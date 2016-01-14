//
//  CDTEncryptionKeychainConstants.h
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

#ifndef _CDTEncryptionKeychainConstants_h
#define _CDTEncryptionKeychainConstants_h

#import <CommonCrypto/CommonCryptor.h>

// Define the version of the implementation used to cipher/decipher DPKs
#define CDTENCRYPTION_KEYCHAIN_VERSION @"1.0"

// PBKDF2: Size (bytes) of the salt value used to derive a user-provided password
#define CDTENCRYPTION_KEYCHAIN_PBKDF2_SALT_SIZE 32

// PBKDF2: Number of times the derivation process is applied to a user-provided password
#define CDTENCRYPTION_KEYCHAIN_PBKDF2_ITERATIONS (NSInteger)10000

// AES: Size (bytes) of the key used to encrypt/decrypt a DPK
#define CDTENCRYPTION_KEYCHAIN_AES_KEY_SIZE kCCKeySizeAES256

#endif
