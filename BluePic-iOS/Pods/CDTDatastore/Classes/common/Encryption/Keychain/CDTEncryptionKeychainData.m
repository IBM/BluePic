//
//  CDTEncryptionKeychainData.m
//  CloudantSync
//
//  Created by Enrique de la Torre Fernandez on 12/04/2015.
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

#import "CDTEncryptionKeychainData.h"

#import "CDTLogging.h"

#define CDTENCRYPTION_KEYCHAINDATA_KEY_DPK @"dpk"
#define CDTENCRYPTION_KEYCHAINDATA_KEY_SALT @"salt"
#define CDTENCRYPTION_KEYCHAINDATA_KEY_IV @"iv"
#define CDTENCRYPTION_KEYCHAINDATA_KEY_ITERATIONS @"iterations"
#define CDTENCRYPTION_KEYCHAINDATA_KEY_VERSION @"version"

@interface CDTEncryptionKeychainData ()

@end

@implementation CDTEncryptionKeychainData

#pragma mark - Init object
- (instancetype)init
{
    return [self initWithEncryptedDPK:nil salt:nil iv:nil iterations:NSIntegerMin version:nil];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSData *encryptedDPK =
        [aDecoder decodeObjectOfClass:[NSData class] forKey:CDTENCRYPTION_KEYCHAINDATA_KEY_DPK];
    NSData *salt =
        [aDecoder decodeObjectOfClass:[NSData class] forKey:CDTENCRYPTION_KEYCHAINDATA_KEY_SALT];
    NSData *iv =
        [aDecoder decodeObjectOfClass:[NSData class] forKey:CDTENCRYPTION_KEYCHAINDATA_KEY_IV];
    NSNumber *iterations = [aDecoder decodeObjectOfClass:[NSNumber class]
                                                  forKey:CDTENCRYPTION_KEYCHAINDATA_KEY_ITERATIONS];
    NSString *version = [aDecoder decodeObjectOfClass:[NSString class]
                                               forKey:CDTENCRYPTION_KEYCHAINDATA_KEY_VERSION];

    return [self initWithEncryptedDPK:encryptedDPK
                                 salt:salt
                                   iv:iv
                           iterations:(iterations ? [iterations integerValue] : -1)
                              version:version];
}

- (instancetype)initWithEncryptedDPK:(NSData *)encryptedDPK
                                salt:(NSData *)salt
                                  iv:(NSData *)iv
                          iterations:(NSInteger)iterations
                             version:(NSString *)version
{
    self = [super init];
    if (self) {
        if (encryptedDPK && salt && iv && (iterations >= 0) && version) {
            _encryptedDPK = encryptedDPK;
            _salt = salt;
            _iv = iv;
            _iterations = iterations;
            _version = version;
        } else {
            CDTLogError(
                CDTDATASTORE_LOG_CONTEXT,
                @"All params are mandatory (and iterations value has to be positive or zero)");

            self = nil;
        }
    }

    return self;
}

#pragma mark - NSCoding methods
+ (BOOL)supportsSecureCoding { return YES; }

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.encryptedDPK forKey:CDTENCRYPTION_KEYCHAINDATA_KEY_DPK];
    [aCoder encodeObject:self.salt forKey:CDTENCRYPTION_KEYCHAINDATA_KEY_SALT];
    [aCoder encodeObject:self.iv forKey:CDTENCRYPTION_KEYCHAINDATA_KEY_IV];
    [aCoder encodeObject:[NSNumber numberWithInteger:self.iterations]
                  forKey:CDTENCRYPTION_KEYCHAINDATA_KEY_ITERATIONS];
    [aCoder encodeObject:self.version forKey:CDTENCRYPTION_KEYCHAINDATA_KEY_VERSION];
}

#pragma mark - Public class methods
+ (instancetype)dataWithEncryptedDPK:(NSData *)encryptedDPK
                                salt:(NSData *)salt
                                  iv:(NSData *)iv
                          iterations:(NSInteger)iterations
                             version:(NSString *)version
{
    return [[[self class] alloc] initWithEncryptedDPK:encryptedDPK
                                                 salt:salt
                                                   iv:iv
                                           iterations:iterations
                                              version:version];
}

@end
