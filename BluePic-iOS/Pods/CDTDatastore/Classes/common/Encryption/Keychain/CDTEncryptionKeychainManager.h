//
//  CDTEncryptionKeychainManager.h
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

#import "CDTEncryptionKey.h"
#import "CDTEncryptionKeychainStorage.h"

/**
 Use this class to generate a Data Protection Key (DPK), i.e. a strong password that can be used
 later on for other purposes like encrypting a database.
 
 The generated DPK is automatically encrypted and saved to the keychain, for this reason, it is
 neccesary to provide a password to generate and retrieve the DPK. On a high level, this is done as
 follow:
 - Generate a DPK as a 32 bytes buffer with secure random values.
 - Generate a salt as a 32 bytes buffer with secure random values.
 - Use PBKDF2 to derive a key based on the user-provided password and the salt.
 - Generate an initialization vector (IV) as a 16 bytes buffer with secure random values.
 - Use AES to cipher the DPK with the key and the IV.
 - Return the DPK and save the encrypted version to the keychain.
 */
@interface CDTEncryptionKeychainManager : NSObject

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/**
 Initialise a manager with a CDTEncryptionKeychainStorage instance.
 
 A CDTEncryptionKeychainStorage binds an entry in the keychain to an identifier. The data
 protection key (DPK) saved to the keychain by this class will therefore be bound to the storage's
 identifier. To save different DPKs (say for different users of your application), create multiple
 managers using storages initialised with different identifiers.
 
 @param storage Storage instance to save DPKs to the keychain
 
 @see CDTEncryptionKeychainStorage
 */
- (instancetype)initWithStorage:(CDTEncryptionKeychainStorage *)storage;

/**
 Returns the decrypted Data Protection Key (DPK) from the keychain.
 
 @param password Password used to decrypt the DPK
 
 @return The DPK
 */
- (CDTEncryptionKey *)loadKeyUsingPassword:(NSString *)password;

/**
 Generates a Data Protection Key (DPK), encrypts it, and stores it inside the keychain.
 
 @param password Password used to encrypt the DPK
 
 @return The DPK
 */
- (CDTEncryptionKey *)generateAndSaveKeyProtectedByPassword:(NSString *)password;

/**
 Checks if the encrypted Data Protection Key (DPK) is inside the keychain.
 
 @return YES if the encrypted DPK is inside the keychain, NO otherwise
 */
- (BOOL)keyExists;

/**
 Clears security metadata from the keychain.
 
 @return Success (true) or failure (false)
 */
- (BOOL)clearKey;

@end
