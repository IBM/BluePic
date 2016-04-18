//
//  CDTEncryptionKeychainProvider.m
//  CloudantSync
//
//  Created by Enrique de la Torre Fernandez on 21/04/2015.
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

#import "CDTEncryptionKeychainProvider.h"

#import "CDTEncryptionKeychainManager.h"

#import "CDTLogging.h"

@interface CDTEncryptionKeychainProvider ()

@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) CDTEncryptionKeychainManager *manager;

@end

@implementation CDTEncryptionKeychainProvider

#pragma mark - Init method
- (instancetype)init { return [self initWithPassword:nil forManager:nil]; }

- (instancetype)initWithPassword:(NSString *)password
                      forManager:(CDTEncryptionKeychainManager *)manager
{
    self = [super init];
    if (self) {
        if (password && manager) {
            _password = password;
            _manager = manager;
        } else {
            CDTLogError(CDTDATASTORE_LOG_CONTEXT, @"All parameters are mandatory");

            self = nil;
        }
    }

    return self;
}

#pragma mark - CDTEncryptionKeyProvider methods
- (CDTEncryptionKey *)encryptionKey
{
    CDTEncryptionKey *key = nil;

    @synchronized(self)
    {
        if ([self.manager keyExists]) {
            key = [self.manager loadKeyUsingPassword:self.password];
        } else {
            key = [self.manager generateAndSaveKeyProtectedByPassword:self.password];
        }
    }

    return key;
}

#pragma mark - Public class methods
+ (instancetype)providerWithPassword:(NSString *)password forIdentifier:(NSString *)identifier
{
    CDTEncryptionKeychainStorage *storage =
        [[CDTEncryptionKeychainStorage alloc] initWithIdentifier:identifier];
    CDTEncryptionKeychainManager *manager =
        [[CDTEncryptionKeychainManager alloc] initWithStorage:storage];

    return [[[self class] alloc] initWithPassword:password forManager:manager];
}

@end
