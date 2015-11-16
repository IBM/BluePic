//
//  CDTEncryptionKeychainManager.m
//  CloudantSync
//
//  Created by Enrique de la Torre Fernandez on 09/04/2015.
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

#import <CommonCrypto/CommonCryptor.h>

#import "CDTEncryptionKeychainManager.h"

#import "CDTEncryptionKeychainUtils.h"
#import "CDTEncryptionKeychainConstants.h"

#import "CDTLogging.h"

#define CDTENCRYPTIONKEYCHAINMANAGER_AES_IV_SIZE kCCBlockSizeAES128

@interface CDTEncryptionKeychainManager ()

@property (strong, nonatomic, readonly) CDTEncryptionKeychainStorage *storage;

@end

@implementation CDTEncryptionKeychainManager

#pragma mark - Init object
- (instancetype)init { return [self initWithStorage:nil]; }

- (instancetype)initWithStorage:(CDTEncryptionKeychainStorage *)storage
{
    self = [super init];
    if (self) {
        if (storage) {
            _storage = storage;
        } else {
            CDTLogError(CDTDATASTORE_LOG_CONTEXT, @"Storage is mandatory");

            self = nil;
        }
    }

    return self;
}

#pragma mark - Public methods
- (CDTEncryptionKey *)loadKeyUsingPassword:(NSString *)password
{
    CDTEncryptionKeychainData *data = [self.storage encryptionKeyData];
    if (!data || ![self validateEncryptionKeyData:data]) {
        return nil;
    }

    NSData *aesKey = [self pbkdf2DerivedKeyForPassword:password
                                                  salt:data.salt
                                            iterations:data.iterations
                                                length:CDTENCRYPTION_KEYCHAIN_AES_KEY_SIZE];

    NSData *dpk = [self decryptDpk:data.encryptedDPK usingAESWithKey:aesKey iv:data.iv];

    return [CDTEncryptionKey encryptionKeyWithData:dpk];
}

- (CDTEncryptionKey *)generateAndSaveKeyProtectedByPassword:(NSString *)password
{
    NSData *dpk = nil;

    if (![self keyExists]) {
        dpk = [self generateDpk];

        CDTEncryptionKeychainData *keychainData =
            [self keychainDataToStoreDpk:dpk encryptedWithPassword:password];

        if (![self.storage saveEncryptionKeyData:keychainData]) {
            dpk = nil;
        }
    }

    return [CDTEncryptionKey encryptionKeyWithData:dpk];
}

- (BOOL)keyExists { return [self.storage encryptionKeyDataExists]; }

- (BOOL)clearKey { return [self.storage clearEncryptionKeyData]; }

#pragma mark - CDTEncryptionKeychainManager+Internal methods
- (BOOL)validateEncryptionKeyData:(CDTEncryptionKeychainData *)data
{
    // Ensure IV has the correct length
    if (data.iv.length != CDTENCRYPTIONKEYCHAINMANAGER_AES_IV_SIZE) {
        CDTLogWarn(CDTDATASTORE_LOG_CONTEXT, @"IV does not have the expected size: %i bytes",
                   CDTENCRYPTIONKEYCHAINMANAGER_AES_IV_SIZE);

        return NO;
    }

    return YES;
}

- (NSData *)generateDpk
{
    NSData *dpk =
        [CDTEncryptionKeychainUtils generateSecureRandomBytesWithLength:CDTENCRYPTIONKEY_KEYSIZE];

    return dpk;
}

- (CDTEncryptionKeychainData *)keychainDataToStoreDpk:(NSData *)dpk
                                encryptedWithPassword:(NSString *)password
{
    NSData *salt = [self generatePBKDF2Salt];

    NSData *key = [self pbkdf2DerivedKeyForPassword:password
                                               salt:salt
                                         iterations:CDTENCRYPTION_KEYCHAIN_PBKDF2_ITERATIONS
                                             length:CDTENCRYPTION_KEYCHAIN_AES_KEY_SIZE];

    NSData *iv = [self generateAESIv];

    NSData *encryptedDpk = [self encryptDpk:dpk usingAESWithKey:key iv:iv];

    CDTEncryptionKeychainData *keychainData =
        [CDTEncryptionKeychainData dataWithEncryptedDPK:encryptedDpk
                                                   salt:salt
                                                     iv:iv
                                             iterations:CDTENCRYPTION_KEYCHAIN_PBKDF2_ITERATIONS
                                                version:CDTENCRYPTION_KEYCHAIN_VERSION];

    return keychainData;
}

- (NSData *)generatePBKDF2Salt
{
    NSData *salt = [CDTEncryptionKeychainUtils
        generateSecureRandomBytesWithLength:CDTENCRYPTION_KEYCHAIN_PBKDF2_SALT_SIZE];

    return salt;
}

- (NSData *)pbkdf2DerivedKeyForPassword:(NSString *)pass
                                   salt:(NSData *)salt
                             iterations:(NSInteger)iterations
                                 length:(NSUInteger)length
{
    NSData *key = [CDTEncryptionKeychainUtils pbkdf2DerivedKeyForPassword:pass
                                                                     salt:salt
                                                               iterations:iterations
                                                                   length:length];

    return key;
}

- (NSData *)generateAESIv
{
    NSData *iv = [CDTEncryptionKeychainUtils
        generateSecureRandomBytesWithLength:CDTENCRYPTIONKEYCHAINMANAGER_AES_IV_SIZE];

    return iv;
}

- (NSData *)encryptDpk:(NSData *)dpk usingAESWithKey:(NSData *)key iv:(NSData *)iv
{
    NSData *encyptedDpk = [CDTEncryptionKeychainUtils aesEncryptedDataForData:dpk key:key iv:iv];

    return encyptedDpk;
}

- (NSData *)decryptDpk:(NSData *)cipheredDpk usingAESWithKey:(NSData *)key iv:(NSData *)iv
{
    NSData *dpk = [CDTEncryptionKeychainUtils dataForAESEncryptedData:cipheredDpk key:key iv:iv];

    return dpk;
}

@end
