//
//  CDTURLSessionTask.h
//
//
//  Created by Rhys Short on 20/08/2015.
//  Copyright (c) 2015 IBM Corp.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.
//

#import "CDTURLSessionTask.h"
#import "CDTHTTPInterceptorContext.h"
#import "CDTHTTPInterceptor.h"
#import "CDTLogging.h"

@interface CDTURLSessionTask ()

/**
 Request we're carrying out.
 */
@property (nonnull, nonatomic, strong) NSURLRequest *request;

/*
 * The NSURLSessionTask backing this one
 */
@property (nonnull, nonatomic, strong) NSURLSessionDataTask *inProgressTask;

@property NSURLSession *session;

/**
 Request interceptors. -init... filters to only valid request interceptors
 */
@property (nonnull, nonatomic, strong) NSArray *requestInterceptors;

@property (nonnull, nonatomic, strong) NSArray *responseInterceptors;

@property (nonatomic) int remainingRetries;

@end

@implementation CDTURLSessionTask

- (nullable instancetype)init
{
    NSAssert(NO, @"Use designated initializer");
    return nil;
}

- (nullable instancetype)initWithSession:(NSURLSession *)session
                                 request:(NSURLRequest *)request
                            interceptors:(NSArray *)interceptors
{
    NSParameterAssert(session);
    NSParameterAssert(request);

    self = [super init];
    if (self) {
        _session = session;
        _request = [request mutableCopy];
        _requestInterceptors = [self filterRequestInterceptors:interceptors];
        _responseInterceptors = [self filterResponseInterceptors:interceptors];
        _remainingRetries = 10;
    }
    return self;
}

- (void)resume
{
    NSURLSessionTask *t = self.inProgressTask;
    if (!t) {
        self.inProgressTask = [self makeRequest];
    }
    [self.inProgressTask resume];
}
- (void)cancel
{
    NSURLSessionTask *t = self.inProgressTask;
    if (t) {
        [t cancel];
    }
}

- (NSURLSessionTaskState)state
{
    NSURLSessionTask *t = self.inProgressTask;
    if (t) {
        return t.state;
    } else {
        return NSURLSessionTaskStateSuspended;  // essentially we're in this state until resumed.
    }
}

#pragma mark Helpers

- (nonnull NSURLSessionDataTask *)makeRequest
{
    __block CDTHTTPInterceptorContext *ctx =
        [[CDTHTTPInterceptorContext alloc] initWithRequest:[self.request mutableCopy]];

    // We make sure all objects support `interceptRequestInContext:` during init.
    for (NSObject<CDTHTTPInterceptor> *obj in self.requestInterceptors) {
        ctx = [obj interceptRequestInContext:ctx];
    }

    __weak CDTURLSessionTask *weakSelf = self;
    return [self.session
        dataTaskWithRequest:ctx.request
          completionHandler:^void(NSData *data, NSURLResponse *response, NSError *error) {
            __strong CDTURLSessionTask *strongSelf = weakSelf;
            if (strongSelf) {
                ctx.response = (NSHTTPURLResponse*)response;
                for (NSObject<CDTHTTPInterceptor> *obj in strongSelf.responseInterceptors) {
                    ctx = [obj interceptResponseInContext:ctx];
                }

                if (ctx.shouldRetry && strongSelf.remainingRetries > 0) {
                    // retry
                    strongSelf.remainingRetries--;
                    strongSelf.inProgressTask = [strongSelf makeRequest];
                    [strongSelf.inProgressTask resume];
                } else if (strongSelf.completionHandler) {
                    strongSelf.completionHandler(data, response, error);
                }
            }
          }];
}

/**
 Copy the interceptor array, filtering out non-compliant classes.

 We do this once during `-init...`. This checks for responding to `interceptRequestInContext:`
 as we're creating a request interceptor array, not a response one.
 */
- (nonnull NSArray *)filterRequestInterceptors:(nonnull NSArray *)proposedRequestInterceptors
{
    NSMutableArray *requestInterceptors = [NSMutableArray array];

    for (NSObject *obj in proposedRequestInterceptors) {
        if ([obj respondsToSelector:@selector(interceptRequestInContext:)]) {
            [requestInterceptors addObject:obj];
        }
    }

    return [NSArray arrayWithArray:requestInterceptors];
}

/**
 Copy the interceptor array, filtering out non-compliant classes.

 We do this once during `-init...`. This checks for responding to `interceptResponseInContext:`
 as we're creating a response interceptor array, not a request one.
 */
- (nonnull NSArray *)filterResponseInterceptors:(nonnull NSArray *)proposedResponseInterceptors
{
    NSMutableArray *responseInterceptors = [NSMutableArray array];

    for (NSObject *obj in proposedResponseInterceptors) {
        if ([obj respondsToSelector:@selector(interceptResponseInContext:)]) {
            [responseInterceptors addObject:obj];
        }
    }

    return [NSArray arrayWithArray:responseInterceptors];
}

@end

