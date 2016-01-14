//
//  TDMultipartUploader.h
//  TouchDB
//
//  Created by Jens Alfke on 2/5/12.
//  Copyright (c) 2012 Couchbase, Inc. All rights reserved.
//

#import "TDRemoteRequest.h"
#import "TDMultipartWriter.h"

@interface TDMultipartUploader : TDRemoteRequest {
   @private
    TDMultipartWriter *_multipartWriter;
}

- (instancetype)initWithSession:(CDTURLSession*) session URL:(NSURL *)url
                       streamer:(TDMultipartWriter *)writer
                 requestHeaders:(NSDictionary *)requestHeaders
                   onCompletion:(TDRemoteRequestCompletionBlock)onCompletion;

@end
