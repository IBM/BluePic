//
//  CDTEncryptionKeychainStorage.h
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

#import <Foundation/Foundation.h>

#import "CDTEncryptionKeychainData.h"

/**
 Use this class to store a CDTEncryptionKeychainData instance in the keychain associated to an
 identifier. To say in another way, it is possible to store multiple CDTEncryptionKeychainData
 instances as long as you use a CDTEncryptionKeychainStorage with a different identifier for each
 one.

 Each CDTEncryptionKeychainData is bound to a specific identifier and all of them are grouped in
 the keychain by service (service name defined with CDTENCRYPTION_KEYCHAINSTORAGE_SERVICE_VALUE).
 This means that if you use the same identifier to store other data in the keychain it will not
 conflict with these values.
 
 @warning Data is saved in the keychain with kSecAttrAccessible equal to
 kSecAttrAccessibleAfterFirstUnlock, so the data can only be accessed once the device has been
 unlocked after a restart.

 @see CDTEncryptionKeychainData
 */
@interface CDTEncryptionKeychainStorage : NSObject

/**
 Initialise a storage with an identifier. A CDTEncryptionKeychainData saved to the keychain using
 this storage will be bound to the identifier specified here.

 @param identifier A string
 */
- (instancetype)initWithIdentifier:(NSString *)identifier;

/**
 A CDTEncryptionKeychainData previously saved with this storage (or other storage created before
 with the same identifier).

 @return A CDTEncryptionKeychainData saved before or nil
 */
- (CDTEncryptionKeychainData *)encryptionKeyData;

/*
 Save to the keychain a CDTEncryptionKeychainData.

 Notice that if there is already data in the keychain bound to the same identifier used to create
 this storage, the operation will fail.

 @param data Data to save to the keychain

 @return YES (success) or NO (fail)
 */
- (BOOL)saveEncryptionKeyData:(CDTEncryptionKeychainData *)data;

/**
 Remove from the keychain a CDTEncryptionKeychainData associated to the same identifier used to
 create this storage.

 It will succeed if the data is deleted or if there is no data at all.

 @return YES (success) or NO (fail)
 */
- (BOOL)clearEncryptionKeyData;

/**
 Look for data saved in the keychain with the same identifier used to create this storage instance.

 @return YES (data found) or NO (data not found)
 */
- (BOOL)encryptionKeyDataExists;

@end
