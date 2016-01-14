//
//  TDMultipartUploader.m
//  TouchDB
//
//  Created by Jens Alfke on 2/5/12.
//  Copyright (c) 2012 Couchbase, Inc. All rights reserved.
//
//  Modifications for this distribution by Cloudant, Inc., Copyright (c) 2014 Cloudant, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "TDMultipartUploader.h"
#import "CDTLogging.h"

@implementation TDMultipartUploader

- (instancetype)initWithSession:(CDTURLSession*) session URL:(NSURL *)url
          streamer:(TDMultipartWriter *)writer
    requestHeaders:(NSDictionary *)requestHeaders
      onCompletion:(TDRemoteRequestCompletionBlock)onCompletion
{
    Assert(writer);
    self = [super initWithSession:session method:@"PUT"
                             URL:url
                            body:writer
                  requestHeaders:requestHeaders
                    onCompletion:onCompletion];
    if (self) {
        _multipartWriter = writer;
        // It's important to set a Content-Length header -- without this, CFNetwork won't know the
        // length of the body stream, so it has to send the body chunked. But unfortunately CouchDB
        // doesn't correctly parse chunked multipart bodies:
        // https://issues.apache.org/jira/browse/COUCHDB-1403
        SInt64 length = _multipartWriter.length;
        Assert(length >= 0, @"HTTP multipart upload body has indeterminate length");
        [_request setValue:$sprintf(@"%lld", length) forHTTPHeaderField:@"Content-Length"];
    }
    return self;
}

- (void)start
{
    [_multipartWriter openForURLRequest:_request];
    [super start];
}

- (NSInputStream *)connection:(NSURLConnection *)connection
            needNewBodyStream:(NSURLRequest *)request
{
    CDTLogInfo(CDTTD_REMOTE_REQUEST_CONTEXT, @"%@: Needs new body stream, resetting writer...", self);
    [_multipartWriter close];
    return [_multipartWriter openForInputStream];
}

-(void)requestDidError:(NSError *)error
{
    if ($equal(error.domain, NSURLErrorDomain) &&
        error.code == NSURLErrorRequestBodyStreamExhausted) {
        // The connection is complaining that the body input stream closed prematurely.
        // Check whether this is because the multipart writer got an error on _its_ input stream:
        NSError *writerError = _multipartWriter.error;
        if (writerError) error = writerError;
    }
    [super requestDidError:error];
}

- (void)receivedData:(NSData *)data
{
    [super receivedData:data];
    [self clearSession];
    [self respondWithResult:self error:nil];
}

@end
