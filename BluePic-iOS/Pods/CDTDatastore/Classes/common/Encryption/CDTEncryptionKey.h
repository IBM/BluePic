//
//  CDTEncryptionKey.h
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

#import <Foundation/Foundation.h>

/**
 Use this class to pass around a DPK (Data Protection Key).

 This class is essentially a wrapper for a NSData instance. However this instance has to have a
 specific size: CDTENCRYPTIONKEY_KEYSIZE bytes. The reason for this is that we rely on SQLCipher to
 encrypt databases and it requires a key of CDTENCRYPTIONKEY_KEYSIZE bytes.
 */

// Size (bytes) of the DPK (Data Protection Key)
#define CDTENCRYPTIONKEY_KEYSIZE 32

@interface CDTEncryptionKey : NSObject

/**
 CDTENCRYPTIONKEY_KEYSIZE bytes buffer with the DPK
 */
@property (strong, nonatomic, readonly) NSData *data;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/**
 Initialise an encryption key with a buffer.

 @param data Buffer of size CDTENCRYPTIONKEY_KEYSIZE bytes with the DPK
 
 @warning If data.length is not CDTENCRYPTIONKEY_KEYSIZE, init will return nil
 */
- (instancetype)initWithData:(NSData *)data NS_DESIGNATED_INITIALIZER;

- (BOOL)isEqualToEncryptionKey:(CDTEncryptionKey *)encryptionKey;

+ (instancetype)encryptionKeyWithData:(NSData *)data;

@end
