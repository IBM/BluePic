//
//  CDTEncryptionKeychainProvider+Internal.h
//  CloudantSync
//
//  Created by Enrique de la Torre Fernandez on 15/05/2015.
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

/**
 This category is only for testing purposes.
 */
@interface CDTEncryptionKeychainProvider (Internal)

/**
 Initialise a provider with a password and a CDTEncryptionKeychainManager instance.
 
 The returned provider will pass the password to the manager to generate the key or get it from the
 keychain if it already exists.
 
 @param password An user-provided password
 @param manager A manager to generate and store the resulting key
 
 @see CDTEncryptionKeychainManager
 */
- (instancetype)initWithPassword:(NSString *)password
                      forManager:(CDTEncryptionKeychainManager *)manager;

@end
