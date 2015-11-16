//
//  CDTEncryptionKeySimpleProvider.m
//  CloudantSync
//
//  Created by Enrique de la Torre Fernandez on 26/05/2015.
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

#import "CDTEncryptionKeySimpleProvider.h"

#import "CDTLogging.h"

@interface CDTEncryptionKeySimpleProvider ()

@property (strong, nonatomic, readonly) CDTEncryptionKey *thisKey;

@end

@implementation CDTEncryptionKeySimpleProvider

- (instancetype)init { return [self initWithKey:nil]; }

- (instancetype)initWithKey:(NSData *)key
{
    self = [super init];
    if (self) {
        _thisKey = [CDTEncryptionKey encryptionKeyWithData:key];
        if (!_thisKey) {
            CDTLogError(CDTDATASTORE_LOG_CONTEXT,
                        @"Key could not be created with provided data. Abort initialisation");

            self = nil;
        }
    }

    return self;
}

#pragma mark - CDTEncryptionKeyProvider methods
- (CDTEncryptionKey *)encryptionKey { return self.thisKey; }

#pragma mark - Public class methods
+ (instancetype)providerWithKey:(NSData *)key { return [[[self class] alloc] initWithKey:key]; }

@end
