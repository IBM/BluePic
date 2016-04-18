//
//  CDTURLSessionInterceptor.h
//  
//
//  Created by Rhys Short on 24/08/2015.
//  Copyright (c) 2015 IBM Corp.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "CDTHTTPInterceptorContext.h"

@protocol CDTHTTPInterceptor <NSObject>

@optional
/**
 *  Intercepts a request before it is made
 *
 *  @param context the context for this interception
 *
 *  @return the context for this interception
 **/
- (nonnull CDTHTTPInterceptorContext*)interceptRequestInContext:(nonnull CDTHTTPInterceptorContext*)context;

/**
 *  Intercepts a response before it is returned to the request initiator
 *
 *  @param context the context for this interception
 *
 *  @return the context for this interception
 **/
- (nonnull CDTHTTPInterceptorContext*)interceptResponseInContext:
    (nonnull CDTHTTPInterceptorContext*)context;

@end
