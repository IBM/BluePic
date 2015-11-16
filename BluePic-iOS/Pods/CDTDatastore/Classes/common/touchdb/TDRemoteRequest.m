//
//  TDRemoteRequest.m
//  TouchDB
//
//  Created by Jens Alfke on 12/15/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//
//  Modified by Michael Rhodes, 2013
//  Copyright (c) 2013 Cloudant, Inc. All rights reserved.
//
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "TDRemoteRequest.h"
#import "TDAuthorizer.h"
#import "TDMisc.h"
#import "TDBlobStore.h"
#import "TD_Database.h"
#import "TDReplicator.h"
#import "CollectionUtils.h"
#import "Logging.h"
#import "Test.h"
#import "MYURLUtils.h"
#import "TDJSON.h"

#import "CDTDatastore.h"
#import "CDTLogging.h"
#import "CDTURLSession.h"

// Max number of retry attempts for a transient failure, and the backoff time formula
#define kMaxRetries 2
#define RetryDelay(COUNT) (4 << (COUNT))  // COUNT starts at 0

@interface TDRemoteRequest()

@property CDTURLSession *session;
@property (nonatomic, strong) CDTURLSessionTask *task;

@end


@implementation TDRemoteRequest

+ (NSString *)userAgentHeader
{
    NSProcessInfo *pInfo = [NSProcessInfo processInfo];
    NSString *version = [pInfo operatingSystemVersionString];
    NSString *platform = @"Unknown";
#if TARGET_OS_IPHONE
    platform = @"iOS";
#elif TARGET_OS_MAC
    platform = @"Mac OS X";
#endif
    return [NSString stringWithFormat:@"CloudantSync/%@ (%@ %@)",
            [CDTDatastore versionString],
            platform,
            version ];
}

- (instancetype)initWithSession:(CDTURLSession*)session
                         method:(NSString*)method
                            URL:(NSURL*)url
                           body:(id)body
                 requestHeaders:(NSDictionary*)requestHeaders
                   onCompletion:(TDRemoteRequestCompletionBlock)onCompletion
{
    self = [super init];
    if (self) {
        _onCompletion = [onCompletion copy];
        _request = [[NSMutableURLRequest alloc] initWithURL:url];
        _request.HTTPMethod = method;
        _request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        
        // Add headers.
        [_request setValue:[[self class] userAgentHeader] forHTTPHeaderField:@"User-Agent"];
        [requestHeaders enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
            [_request setValue:value forHTTPHeaderField:key];
        }];
        _session = session;
    }
    return self;
}

- (id<TDAuthorizer>)authorizer { return _authorizer; }

- (void)setAuthorizer:(id<TDAuthorizer>)authorizer
{
    if (_authorizer != authorizer) {
        _authorizer = authorizer;
        [_request setValue:[authorizer authorizeURLRequest:_request forRealm:nil]
            forHTTPHeaderField:@"Authorization"];
    }
}

- (void)dontLog404 { _dontLog404 = true; }

- (void)start
{
    if (!_request) return;  // -clearConnection already called
    CDTLogVerbose(CDTTD_REMOTE_REQUEST_CONTEXT, @"%@: Starting...", self);

    __weak TDRemoteRequest *weakSelf = self;
    self.task = [self.session dataTaskWithRequest:_request
                                completionHandler:^(NSData *data,
                                                    NSURLResponse *response,
                                                    NSError *error) {
        TDRemoteRequest * strongSelf = weakSelf;
        if(error) {
            [strongSelf requestDidError:error];
        } else if (TDStatusIsError(((NSHTTPURLResponse *)response).statusCode)) {
            [strongSelf receivedResponse:response];
        }  else {
            [strongSelf receivedResponse:response];
            [strongSelf receivedData:data];
        }
    }];
    [self.task resume];

}

- (void)clearSession
{
    _request = nil;
    [self.task cancel];
    self.task = nil;
}

- (void)dealloc { [self clearSession]; }

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@[%@ %@]", [self class], _request.HTTPMethod, TDCleanURLtoString(_request.URL) ];
}

- (NSMutableDictionary *)statusInfo
{
    return [@{ @"URL": _request.URL.absoluteString , @"method": _request.HTTPMethod } mutableCopy];
}

- (void)respondWithResult:(id)result error:(NSError *)error
{
    Assert(result || error);
    if(_onCompletion){
        _onCompletion(result, error);
    }
    _onCompletion = nil;  // break cycles
}

- (void)startAfterDelay:(NSTimeInterval)delay
{
    // assumes task already failed or canceled.
    self.task = nil;
    [self performSelector:@selector(start) withObject:nil afterDelay:delay];
}

- (void)stop
{
    if (self.task) {
        CDTLogVerbose(CDTTD_REMOTE_REQUEST_CONTEXT, @"%@: Stopped", self);
        [self.task cancel];
    }
    [self clearSession];
    if (_onCompletion) {
        NSError *error =
            [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
        [self respondWithResult:nil error:error];
        _onCompletion = nil;  // break cycles
    }
}
	
- (void)cancelWithStatus:(int)status
{
    [self.task cancel];
    [self requestDidError:TDStatusToNSError(status, _request.URL)];
}

- (BOOL)retry
{
    // Note: This assumes all requests are idempotent, since even though we got an error back, the
    // request might have succeeded on the remote server, and by retrying we'd be issuing it again.
    // PUT and POST requests aren't generally idempotent, but the ones sent by the replicator are.

    if (_retryCount >= kMaxRetries) return NO;
    NSTimeInterval delay = RetryDelay(_retryCount);
    ++_retryCount;
    CDTLogVerbose(CDTTD_REMOTE_REQUEST_CONTEXT, @"%@: Will retry in %g sec", self, delay);
    [self startAfterDelay:delay];
    return YES;
}

- (bool)retryWithCredential
{
    return false;
}

+ (BOOL)checkTrust:(SecTrustRef)trust forHost:(NSString *)host
{
    SecTrustResultType trustResult;
    OSStatus err = SecTrustEvaluate(trust, &trustResult);
    if (err == noErr &&
        (trustResult == kSecTrustResultProceed || trustResult == kSecTrustResultUnspecified)) {
        return YES;
    } else {
        CDTLogWarn(
            CDTTD_REMOTE_REQUEST_CONTEXT,
            @"TouchDB: SSL server <%@> not trusted (err=%d, trustResult=%u); cert chain follows:",
            host, (int)err, (unsigned)trustResult);
#if TARGET_OS_IPHONE
        for (CFIndex i = 0; i < SecTrustGetCertificateCount(trust); ++i) {
            SecCertificateRef cert = SecTrustGetCertificateAtIndex(trust, i);
            CFStringRef subject = SecCertificateCopySubjectSummary(cert);
            CDTLogWarn(CDTTD_REMOTE_REQUEST_CONTEXT, @"    %@", subject);
            CFRelease(subject);
        }
#else
#ifdef __OBJC_GC__
        NSArray *trustProperties = NSMakeCollectable(SecTrustCopyProperties(trust));
#else
        NSArray *trustProperties = (__bridge_transfer NSArray *)SecTrustCopyProperties(trust);
#endif
        for (NSDictionary *property in trustProperties) {
            CDTLogWarn(CDTTD_REMOTE_REQUEST_CONTEXT, @"    %@: error = %@",
                    property[(__bridge id)kSecPropertyTypeTitle],
                    property[(__bridge id)kSecPropertyTypeError]);
        }
#endif
        return NO;
    }
}
- (void) receivedResponse:(NSURLResponse *)response
{
    //if we hit an error we shouldn't retry, the Http interceptors should deal with retires.
    _status = (int)((NSHTTPURLResponse *)response).statusCode;
    CDTLogVerbose(CDTTD_REMOTE_REQUEST_CONTEXT, @"%@: Got response, status %d", self, _status);

    if (TDStatusIsError(_status)) [self cancelWithStatus:_status];
}

-(void) receivedData:(NSData *)data
{
    CDTLogVerbose(CDTTD_REMOTE_REQUEST_CONTEXT, @"%@: Got %lu bytes", self, (unsigned long)data.length);
}

- (void)requestDidError:(NSError *)error
{
    if (!(_dontLog404 && error.code == kTDStatusNotFound &&
          $equal(error.domain, TDHTTPErrorDomain)))
        CDTLogVerbose(CDTTD_REMOTE_REQUEST_CONTEXT, @"%@: Got error. domain %@, code %@", self, error.domain, @(error.code));

    // If the error is likely transient, retry:
    if (TDMayBeTransientError(error) && [self retry]) return;

    [self clearSession];
    [self respondWithResult:nil error:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    CDTLogVerbose(CDTTD_REMOTE_REQUEST_CONTEXT, @"%@: Finished loading", self);
    [self clearSession];
    [self respondWithResult:self error:nil];
}

@end

@implementation TDRemoteJSONRequest

-(instancetype) initWithSession:(CDTURLSession*)session method:(NSString *)method URL:(NSURL *)url body:(id)body requestHeaders:(NSDictionary *)requestHeaders onCompletion:(TDRemoteRequestCompletionBlock)onCompletion
{
    self = [super initWithSession:session method:method URL:url body:body requestHeaders:requestHeaders onCompletion:onCompletion];
    if(self){
        
        [_request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        if (body) {
            _request.HTTPBody = [TDJSON dataWithJSONObject:body options:0 error:NULL];
            [_request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        }
        
    }
    
    return self;
}


- (void)clearSession
{
    _jsonBuffer = nil;
    [super clearSession];
}

- (void)receivedData:(NSData *)data
{
    [super receivedData:data];
    if (!_jsonBuffer)
        _jsonBuffer = [[NSMutableData alloc] initWithCapacity:MAX(data.length, 8192u)];
    [_jsonBuffer appendData:data];

    id result = nil;
    NSError *error = nil;
    if (_jsonBuffer.length > 0) {
        result = [TDJSON JSONObjectWithData:_jsonBuffer options:0 error:NULL];
        if (!result) {
            CDTLogWarn(CDTTD_REMOTE_REQUEST_CONTEXT, @"%@: %@ %@ returned unparseable data '%@'", self,
                    _request.HTTPMethod, TDCleanURLtoString(_request.URL), [_jsonBuffer my_UTF8ToString]);
            error = TDStatusToNSError(kTDStatusUpstreamError, _request.URL);
        }
    } else {
        result = @{};
    }
    [self clearSession];
    [self respondWithResult:result error:error];
}

@end
