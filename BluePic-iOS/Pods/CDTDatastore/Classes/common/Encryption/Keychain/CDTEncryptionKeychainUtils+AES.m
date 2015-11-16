//
//  CDTEncryptionKeychainUtils+AES.m
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

#import "CDTEncryptionKeychainUtils+AES.h"

@implementation CDTEncryptionKeychainUtils (AES)

#pragma mark - Public class methods
+ (NSData *)doDecrypt:(NSData *)data withKey:(NSData *)key iv:(NSData *)iv
{
    return [CDTEncryptionKeychainUtils applyOperation:kCCDecrypt toData:data withKey:key iv:iv];
}

+ (NSData *)doEncrypt:(NSData *)data withKey:(NSData *)key iv:(NSData *)iv
{
    return [CDTEncryptionKeychainUtils applyOperation:kCCEncrypt toData:data withKey:key iv:iv];
}

#pragma mark - Private class method
+ (NSData *)applyOperation:(CCOperation)operation
                    toData:(NSData *)data
                   withKey:(NSData *)key
                        iv:(NSData *)iv
{
    // Validations
    NSAssert((key.length == kCCKeySizeAES128) || (key.length == kCCKeySizeAES192) ||
                 (key.length == kCCKeySizeAES256),
             @"Key length must be appropriate for the selected operation and algorithm.");
    NSAssert(iv.length == kCCBlockSizeAES128,
             @"IV length must be the same length as the selected algorithm's block size");

    // Generate context
    CCCryptorRef cryptor = NULL;
    CCCryptorStatus cryptorStatus =
        CCCryptorCreate(operation, kCCAlgorithmAES, kCCOptionPKCS7Padding, key.bytes, key.length,
                        iv.bytes, &cryptor);
    NSAssert((cryptorStatus == kCCSuccess) && cryptor, @"Cryptographic context not created");

    // Encrypt
    size_t dataOutSize = CCCryptorGetOutputLength(cryptor, (size_t)[data length], true);
    void *dataOut = malloc(dataOutSize);
    memset(dataOut, '\0', dataOutSize);

    size_t dataOutPartialSize = 0;
    cryptorStatus = CCCryptorUpdate(cryptor, [data bytes], (size_t)[data length], dataOut,
                                    dataOutSize, &dataOutPartialSize);
    NSAssert(cryptorStatus == kCCSuccess, @"Data not encrypted (update)");

    size_t dataOutTotalSize = dataOutPartialSize;

    cryptorStatus = CCCryptorFinal(cryptor, dataOut + dataOutPartialSize,
                                   dataOutSize - dataOutPartialSize, &dataOutPartialSize);
    NSAssert(cryptorStatus == kCCSuccess, @"Data not encrypted (final)");

    dataOutTotalSize += dataOutPartialSize;

    // Free context
    CCCryptorRelease(cryptor);

    // Return
    NSData *processedData = [NSData dataWithBytesNoCopy:dataOut length:dataOutTotalSize];

    return processedData;
}

@end
