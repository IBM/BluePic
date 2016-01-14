//
//  CDTEncryptionKeychainUtils.h
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

#import <Foundation/Foundation.h>

// Exception raised if there is a problem while generating a key
extern NSString *const CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_LABEL_KEYGEN;

// Exception raised if there is a problem while encrypting a buffer
extern NSString *const CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_LABEL_ENCRYPT;

// Exception raised if there is a problem while decrypting a buffer
extern NSString *const CDTENCRYPTION_KEYCHAIN_UTILS_ERROR_LABEL_DECRYPT;

@interface CDTEncryptionKeychainUtils : NSObject

/**
 Generates a buffer with random bytes in it.

 @param bytes Number of bytes in the buffer (it can not be bigger than SIZE_T_MAX)

 @return The buffer, nil if the operation fails
 */
+ (NSData *)generateSecureRandomBytesWithLength:(NSUInteger)length;

/**
 Generates a new buffer by applying AES to the buffer passed as a parameter with the key and
 Initialization Vector (IV) also supplied as parameters.

 This method asummes correct inputs:
 - The key length must be kCCKeySizeAES128(16), kCCKeySizeAES192(24) or kCCKeySizeAES256(32)
 - IV length must be kCCBlockSizeAES128(16)
 In other case, an exception will be raised.
 
 @param data The data to encrypt
 @param key The key used for encryption
 @param iv The IV used for encryption

 @return The encrypted data
 */
+ (NSData *)aesEncryptedDataForData:(NSData *)data key:(NSData *)key iv:(NSData *)iv;

/**
 Generates a new buffer using AES to decrypt the buffer passed as a parameter with the key and
 Initialization Vector (IV) also supplied as parameters.

 This method asummes correct inputs:
 - The key length must be kCCKeySizeAES128(16), kCCKeySizeAES192(24) or kCCKeySizeAES256(32)
 - IV length must be kCCBlockSizeAES128(16)
 In other case, an exception will be raised.
 
 @param data The encrypted data to decrypt
 @param key The key used for decryption
 @param iv The IV used for decryption

 @return The decrypted data
 */
+ (NSData *)dataForAESEncryptedData:(NSData *)data key:(NSData *)key iv:(NSData *)iv;

/**
 Generates a key by using the PBKDF2 algorithm.

 @param pass The password that is used to generate the key
 @param salt The salt that is used to generate the key
 @param iterations The number of iterations that is passed to the key generation algorithm
 @param length Size of the key in bytes

 @return The generated key
 */
+ (NSData *)pbkdf2DerivedKeyForPassword:(NSString *)pass
                                   salt:(NSData *)salt
                             iterations:(NSInteger)iterations
                                 length:(NSUInteger)length;

@end
