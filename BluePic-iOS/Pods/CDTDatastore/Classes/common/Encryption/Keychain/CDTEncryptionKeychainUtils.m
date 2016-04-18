//
//  CDTEncryptionKeychainUtils.m
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

#import "CDTEncryptionKeychainUtils.h"
#import "CDTEncryptionKeychainUtils+AES.h"
#import "CDTEncryptionKeychainUtils+PBKDF2.h"

NSString *const CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_KEYGEN_LABEL = @"KEYGEN_ERROR";
NSString *const CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_KEYGEN_MSG_INVALID_ITERATIONS =
    @"Number of iterations must greater than 0";
NSString *const CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_KEYGEN_MSG_INVALID_LENGTH =
    @"Length must greater than 0";
NSString *const CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_KEYGEN_MSG_EMPTY_PASSWORD =
    @"Password cannot be nil/empty";
NSString *const CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_KEYGEN_MSG_EMPTY_SALT =
    @"Salt cannot be nil/empty";
NSString *const CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_KEYGEN_MSG_PASS_NOT_DERIVED =
    @"Password not derived";

NSString *const CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_ENCRYPT_LABEL = @"ENCRYPT_ERROR";
NSString *const CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_ENCRYPT_MSG_EMPTY_DATA =
    @"Cannot encrypt empty/nil data";
NSString *const CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_ENCRYPT_MSG_EMPTY_KEY =
    @"Cannot work with an empty/nil key";
NSString *const CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_ENCRYPT_MSG_EMPTY_IV =
    @"Cannot encrypt with empty/nil iv";

NSString *const CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_DECRYPT_LABEL = @"DECRYPT_ERROR";
NSString *const CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_DECRYPT_MSG_EMPTY_CIPHER =
    @"Cannot decrypt empty/nil cipher";
NSString *const CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_DECRYPT_MSG_EMPTY_KEY =
    @"Cannot work with an empty/nil key";
NSString *const CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_DECRYPT_MSG_EMPTY_IV =
    @"Cannot decrypt with empty/nil iv";

@interface CDTEncryptionKeychainUtils ()

@end

@implementation CDTEncryptionKeychainUtils

#pragma mark - Public class methods
+ (NSData *)generateSecureRandomBytesWithLength:(NSUInteger)length
{
    NSAssert((size_t)length <= SIZE_T_MAX, @"length %lu out of bound", (unsigned long)length);
    
    uint8_t randBytes[length];
    
    int rc = SecRandomCopyBytes(kSecRandomDefault, (size_t)length, randBytes);
    if (rc != 0) {
        return nil;
    }
    
    NSData *data = [NSData dataWithBytes:randBytes length:length];
    
    return data;
}

+ (NSData *)aesEncryptedDataForData:(NSData *)data key:(NSData *)key iv:(NSData *)iv
{
    if (![data isKindOfClass:[NSData class]] || (data.length < 1)) {
        [NSException raise:CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_ENCRYPT_LABEL
                    format:CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_ENCRYPT_MSG_EMPTY_DATA];
    }

    if (![key isKindOfClass:[NSData class]] || (key.length < 1)) {
        [NSException raise:CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_ENCRYPT_LABEL
                    format:CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_ENCRYPT_MSG_EMPTY_KEY];
    }

    if (![iv isKindOfClass:[NSData class]] || (iv.length < 1)) {
        [NSException raise:CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_ENCRYPT_LABEL
                    format:CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_ENCRYPT_MSG_EMPTY_IV];
    }

    NSData *cipherDat = [CDTEncryptionKeychainUtils doEncrypt:data withKey:key iv:iv];

    return cipherDat;
}

+ (NSData *)dataForAESEncryptedData:(NSData *)data key:(NSData *)key iv:(NSData *)iv
{
    if (![data isKindOfClass:[NSData class]] || (data.length < 1)) {
        [NSException raise:CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_DECRYPT_LABEL
                    format:CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_DECRYPT_MSG_EMPTY_CIPHER];
    }

    if (![key isKindOfClass:[NSData class]] || (key.length < 1)) {
        [NSException raise:CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_DECRYPT_LABEL
                    format:CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_DECRYPT_MSG_EMPTY_KEY];
    }

    if (![iv isKindOfClass:[NSData class]] || (iv.length < 1)) {
        [NSException raise:CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_DECRYPT_LABEL
                    format:CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_DECRYPT_MSG_EMPTY_IV];
    }

    NSData *decodedCipher = [CDTEncryptionKeychainUtils doDecrypt:data withKey:key iv:iv];
    
    return decodedCipher;
}

+ (NSData *)pbkdf2DerivedKeyForPassword:(NSString *)pass
                                   salt:(NSData *)salt
                             iterations:(NSInteger)iterations
                                 length:(NSUInteger)length
{
    if (length < 1) {
        [NSException raise:CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_KEYGEN_LABEL
                    format:CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_KEYGEN_MSG_INVALID_LENGTH];
    }

    if (![pass isKindOfClass:[NSString class]] || (pass.length < 1)) {
        [NSException raise:CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_KEYGEN_LABEL
                    format:CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_KEYGEN_MSG_EMPTY_PASSWORD];
    }

    if (![salt isKindOfClass:[NSData class]] || (salt.length < 1)) {
        [NSException raise:CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_KEYGEN_LABEL
                    format:CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_KEYGEN_MSG_EMPTY_SALT];
    }

    if (iterations < 1) {
        [NSException raise:CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_KEYGEN_LABEL
                    format:CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_KEYGEN_MSG_INVALID_ITERATIONS];
    }

    NSData *derivedKey = [CDTEncryptionKeychainUtils deriveKeyOfLength:length
                                                          fromPassword:pass
                                                             usingSalt:salt
                                                            iterations:iterations];
    if (!derivedKey) {
        [NSException raise:CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_KEYGEN_LABEL
                    format:CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_KEYGEN_MSG_PASS_NOT_DERIVED];
    }

    return derivedKey;
}

@end
