//
//  CDTAbstractReplication.h
//
//
//  Created by Adam Cox on 4/8/14.
//  Copyright (c) 2014 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import <Foundation/Foundation.h>
#import "CDTHTTPInterceptor.h"

@class CDTDatastore;

extern NSString* const CDTReplicationErrorDomain;

/**
 * Replication errors.
 */
typedef NS_ENUM(NSInteger, CDTReplicationErrors) {
    /**
     No source is defined.
     */
    CDTReplicationErrorUndefinedSource,
    /**
     No target is defined
     */
    CDTReplicationErrorUndefinedTarget,
    /**
     Unsupported protocol. Only 'http' or 'https'.
     */
    CDTReplicationErrorInvalidScheme,
    /**
     Missing either a username or password.
     */
    CDTReplicationErrorIncompleteCredentials,
    /**
     An optional HTTP Header key or value is not of type NSString.
     */
    CDTReplicationErrorBadOptionalHttpHeaderType,
    /**
     See below for a list of HTTP keys that one may not modify.
     */
    CDTReplicationErrorProhibitedOptionalHttpHeader
};

/**
 This is an abstract base class for the CDTPushReplication and CDTPullReplication subclasses.
 Do not create instances of this class.

 CDTAbstractReplication objects encapsulate the parameters necessary
 for the CDTReplicationFactory to create a CDTReplicator object, which
 is used to start individual replication tasks.

 All replications require a remote datasource URL and a local CDTDatastore.
 These are specified with the -target and -source properties found in the subclasses.

 */
@interface CDTAbstractReplication : NSObject <NSCopying>

/*
 ---------------------------------------------------------------------------------------
 The following methods/properties may be accessed instances of the CDTPushReplication
 and CDTPullReplication classes.

 These methods and properties are common to both push and pull replications and are used
 to set various replication options.

 http://docs.couchdb.org/en/latest/json-structure.html#replication-settings

 ---------------------------------------------------------------------------------------
*/

/**
 Set additional HTTP headers by providing an NSDictionary with the header
 name-value string pairs. The headers will be added to all HTTP requests made on behalf
 of a particular push or pull replication.

 All keys and values are required to be NSString (or subclass) objects. If they are not NSString
 or subclasses, then -dictionaryForReplicatorDocument will return an error and the CDTReplicator
 object will not be instantiated successfully.

 Internally we use NSMutableURLRequest, which automatically sets some headers that should
 not be modified.

 @see NSMutableURLRequest

 NSURL will overwrite the following headers

 * Authorization
 * Connection
 * Host
 * WWW-Authenticate

 CloudantSync will overwrite the following headers

 * Content-Type
 * Accept
 * Content-Length

 As such, these headers are prohibited. If one of these headers are set here, instantiation
 of the CDTReplicator object will fail.

 The header "User-Agent" may be changed or modified by using the optionalHeaders. In order
 to modify the default header, obtain the default value from
 (NSString*) +defaultUserAgentHTTPHeader and then set the header in optionalHeaders with your
 change.

 For example:

    CDTPullReplication* pull = [CDTPullReplication replicationWithSource:remote
                                                                  target:datastore];

    NSString *myUserAgent = [NSString stringWithFormat:@"%@/MyApplication",
                                [CDTAbstractReplication defaultUserAgentHTTPHeader]];

    NSDictionary *extraHeaders = @{@"SpecialHeader":@"foo", @"User-Agent":myUserAgent};




*/
@property (nonatomic, copy) NSDictionary* optionalHeaders;

NS_ASSUME_NONNULL_BEGIN

@property (nonnull, nonatomic, readonly, strong) NSArray* httpInterceptors;

- (void)addInterceptor:(nonnull NSObject<CDTHTTPInterceptor>*)interceptor;
- (void)addInterceptors:(nonnull NSArray*)interceptors;
- (void)clearInterceptors;

NS_ASSUME_NONNULL_END

/**
 Returns the default "User-Agent" header value used in HTTP requests made during replication.
*/
+ (NSString*)defaultUserAgentHTTPHeader;

/*
 ---------------------------------------------------------------------------------------
 The following methods should not be accessed by a user of this class or the subclasses.
 The only exception may be the dictionaryForReplicatorDocument method, in special circumstances.
 */

/** --------------------------------------------------------------------------------------
 @name For internal use only
 ---------------------------------------------------------------------------------------
 */

/** The NSDictionary is used by CDTReplicatorFactory to properly configure CDTReplicator objects.

 @param error reports error information
 @return The NSDictionary that configures a CDTReplicator instance.
 @warning This method is for internal use only. The CDTPushReplication and CDTPullReplication
     classes override this method.

 */
- (NSDictionary*)dictionaryForReplicatorDocument:(NSError* __autoreleasing*)error;

/** Checks the content and format of the remoteDatastore URL to ensure that it uses a proper
 protocol (http or https) and has both a username and password (or neither).

 @warning This method is for internal use only.
 @param url the URL to be validated
 @param error reports error information
 @return YES on valid URL.

 */
- (BOOL)validateRemoteDatastoreURL:(NSURL*)url error:(NSError* __autoreleasing*)error;

@end
