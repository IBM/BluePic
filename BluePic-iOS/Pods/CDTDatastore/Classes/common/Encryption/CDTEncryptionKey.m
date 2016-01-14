//
//  CDTEncryptionKey.m
//  CloudantSync
//
//  Created by Enrique de la Torre Fernandez on 12/05/2015.
//  Copyright (c) 2015 IBM Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.
//

#import "CDTEncryptionKey.h"

#import "CDTLogging.h"

@interface CDTEncryptionKey ()

@property (strong, nonatomic, readonly) NSData *privateData;

@end

@implementation CDTEncryptionKey

#pragma mark - Synthesize properties
- (NSData *)data {
    return [self.privateData copy];
}

#pragma mark - Init object
- (instancetype)init { return [self initWithData:nil]; }

- (instancetype)initWithData:(NSData *)data
{
    self = [super init];
    if (self) {
        if (data && (data.length == CDTENCRYPTIONKEY_KEYSIZE)) {
            _privateData = [data copy];
        } else {
            NSNumber *length = (data ? @(data.length) : nil);
            CDTLogError(CDTDATASTORE_LOG_CONTEXT,
                        @"No data provided or it does no have the right size: %@ (instead of %i)",
                        length, CDTENCRYPTIONKEY_KEYSIZE);

            self = nil;
        }
    }

    return self;
}

#pragma mark - NSObject methods
- (BOOL)isEqual:(id)object
{
    if (!object) {
        return NO;
    }

    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[CDTEncryptionKey class]]) {
        return NO;
    }

    return [self isEqualToEncryptionKey:(CDTEncryptionKey *)object];
}

- (NSUInteger)hash {
    return [self.privateData hash];
}

#pragma mark - Public methods
- (BOOL)isEqualToEncryptionKey:(CDTEncryptionKey *)encryptionKey
{
    if (!encryptionKey) {
        return NO;
    }

    return [self.privateData isEqualToData:encryptionKey.privateData];
}

#pragma mark - Public class methods
+ (instancetype)encryptionKeyWithData:(NSData *)data
{
    return [[[self class] alloc] initWithData:data];
}

@end
