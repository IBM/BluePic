//
//  CDTAbstractReplication.m
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

#import "CDTAbstractReplication.h"
#import "TD_DatabaseManager.h"
#import "CDTLogging.h"
#import "TDRemoteRequest.h"

NSString *const CDTReplicationErrorDomain = @"CDTReplicationErrorDomain";

@interface CDTAbstractReplication ()

NS_ASSUME_NONNULL_BEGIN
@property (nonnull, nonatomic, readwrite, strong) NSArray *httpInterceptors;
NS_ASSUME_NONNULL_END

@end

@implementation CDTAbstractReplication

+ (NSString *)defaultUserAgentHTTPHeader { return [TDRemoteRequest userAgentHeader]; }

- (instancetype)copyWithZone:(NSZone *)zone
{
    CDTAbstractReplication *copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        copy.optionalHeaders = self.optionalHeaders;
        copy.httpInterceptors = [self.httpInterceptors copyWithZone:zone];
    }

    return copy;
}

NS_ASSUME_NONNULL_BEGIN

- (instancetype)init
{
    self = [super init];
    if (self) {
        _httpInterceptors = @[];
    }
    return self;
}

/**
 * This method is a convience method and is the same as calling
 * -addinterceptors: with a single element array.
 */
- (void)addInterceptor:(NSObject<CDTHTTPInterceptor> *)interceptor
{
    [self addInterceptors:@[ interceptor ]];
}

/**
 * Appends the interceptors in the array to the list of
 * interceptors to run for each request made to the
 * server.
 *
 * @param interceptors the interceptors to append to the list
 **/
- (void)addInterceptors:(NSArray *)interceptors
{
    self.httpInterceptors = [self.httpInterceptors arrayByAddingObjectsFromArray:interceptors];
}

- (void)clearInterceptors { self.httpInterceptors = @[]; }
NS_ASSUME_NONNULL_END

/**
 This method sets all of the common replication parameters. The subclasses,
 CDTPushReplication and CDTPullReplication add source, target and filter.

 */
- (NSDictionary *)dictionaryForReplicatorDocument:(NSError *__autoreleasing *)error
{
    NSMutableDictionary *doc = [[NSMutableDictionary alloc] init];

    if (self.optionalHeaders) {
        NSMutableArray *lowercaseOptionalHeaders = [[NSMutableArray alloc] init];

        // check for strings
        for (id key in self.optionalHeaders) {
            if (![key isKindOfClass:[NSString class]]) {
                CDTLogWarn(CDTREPLICATION_LOG_CONTEXT,
                        @"CDTAbstractReplication " @"-dictionaryForReplicatorDocument Error: "
                        @"Replication HTTP header key is invalid (%@).\n It must be NSString. "
                        @"Found type %@",
                        key, [key class]);

                if (error) {
                    NSString *msg = @"Cannot sync data. Bad optional HTTP header.";
                    NSDictionary *userInfo =
                        @{NSLocalizedDescriptionKey : NSLocalizedString(msg, nil)};
                    *error = [NSError errorWithDomain:CDTReplicationErrorDomain
                                                 code:CDTReplicationErrorBadOptionalHttpHeaderType
                                             userInfo:userInfo];
                }
                return nil;
            }

            if (![self.optionalHeaders[key] isKindOfClass:[NSString class]]) {
                CDTLogWarn(CDTREPLICATION_LOG_CONTEXT,
                        @"CDTAbstractReplication " @"-dictionaryForReplicatorDocument Error: "
                        @"Value for replication HTTP header %@ is invalid (%@).\n"
                        @"It must be NSString. Found type %@.",
                        key, self.optionalHeaders[key], [self.optionalHeaders[key] class]);

                if (error) {
                    NSString *msg = @"Cannot sync data. Bad optional HTTP header.";
                    NSDictionary *userInfo =
                        @{NSLocalizedDescriptionKey : NSLocalizedString(msg, nil)};
                    *error = [NSError errorWithDomain:CDTReplicationErrorDomain
                                                 code:CDTReplicationErrorBadOptionalHttpHeaderType
                                             userInfo:userInfo];
                }
                return nil;
            }

            [lowercaseOptionalHeaders addObject:[(NSString *)key lowercaseString]];
        }

        NSArray *prohibitedHeaders = @[
            @"authorization",
            @"www-authenticate",
            @"host",
            @"connection",
            @"content-type",
            @"accept",
            @"content-length"
        ];

        NSMutableArray *badHeaders = [[NSMutableArray alloc] init];

        for (NSString *header in prohibitedHeaders) {
            if ([lowercaseOptionalHeaders indexOfObject:header] != NSNotFound) {
                [badHeaders addObject:header];
            }
        }

        if ([badHeaders count] > 0) {
            CDTLogWarn(CDTREPLICATION_LOG_CONTEXT,
                    @"CDTAbstractionReplication " @"-dictionaryForReplicatorDocument Error: "
                    @"You may not use these prohibited headers: %@",
                    badHeaders);

            if (error) {
                NSString *msg = @"Cannot sync data. Bad optional HTTP header.";
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : NSLocalizedString(msg, nil)};
                *error = [NSError errorWithDomain:CDTReplicationErrorDomain
                                             code:CDTReplicationErrorProhibitedOptionalHttpHeader
                                         userInfo:userInfo];
            }

            return nil;
        }

        doc[@"headers"] = self.optionalHeaders;
    }
    doc[@"interceptors"] = self.httpInterceptors;

    return [NSDictionary dictionaryWithDictionary:doc];
}

- (BOOL)validateRemoteDatastoreURL:(NSURL *)url error:(NSError *__autoreleasing *)error
{
    NSString *scheme = [url.scheme lowercaseString];
    NSArray *validSchemes = @[ @"http", @"https" ];
    if (![validSchemes containsObject:scheme]) {
        CDTLogWarn(CDTREPLICATION_LOG_CONTEXT,
                @"%@ -validateRemoteDatastoreURL Error. " @"Invalid scheme: %@", [self class],
                url.scheme);

        if (error) {
            NSString *msg = @"Cannot sync data. Invalid Remote Database URL";

            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : NSLocalizedString(msg, nil)};
            *error = [NSError errorWithDomain:CDTReplicationErrorDomain
                                         code:CDTReplicationErrorInvalidScheme
                                     userInfo:userInfo];
        }
        return NO;
    }

    // username and password must be supplied together
    BOOL usernameSupplied = url.user != nil && ![url.user isEqualToString:@""];
    BOOL passwordSupplied = url.password != nil && ![url.password isEqualToString:@""];

    if ((!usernameSupplied && passwordSupplied) || (usernameSupplied && !passwordSupplied)) {
        CDTLogWarn(CDTREPLICATION_LOG_CONTEXT, @"%@ -validateRemoteDatastoreURL Error. "
                @"Must have both username and password, or neither. ",
                [self class]);

        if (error) {
            NSString *msg =
                [NSString stringWithFormat:@"Cannot sync data. Missing %@",
                                           usernameSupplied ? @"password" : @"username"];

            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : NSLocalizedString(msg, nil)};
            *error = [NSError errorWithDomain:CDTReplicationErrorDomain
                                         code:CDTReplicationErrorIncompleteCredentials
                                     userInfo:userInfo];
        }
        return NO;
    }

    return YES;
}

@end