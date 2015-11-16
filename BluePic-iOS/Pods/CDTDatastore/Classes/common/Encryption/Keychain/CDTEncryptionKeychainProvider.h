//
//  CDTEncryptionKeychainProvider.h
//  CloudantSync
//
//  Created by Enrique de la Torre Fernandez on 21/04/2015.
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

#import "CDTEncryptionKeyProvider.h"

/**
 This class conforms to protocol CDTEncryptionKeyProvider and it can be used to create an
 encrypted datastore.
 
 Given an user-provided password and an identifier, it generates a strong key and store it safely
 in the keychain, so the same key can be retrieved later provided that the user supplies the same
 password and id.
 
 The password is used to protect the key before saving it to the keychain. The identifier is an
 easy way to have more than one encryption key in the same app, the only condition is to provide
 different ids for each of them.
 
 @see CDTEncryptionKeyProvider
 @see CDTEncryptionKeychainManager
 @see CDTEncryptionKeychainStorage
 */
@interface CDTEncryptionKeychainProvider : NSObject <CDTEncryptionKeyProvider>

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/**
 This is a convenience method that creates a CDTEncryptionKeychainManager with the provided
 identifier before calling the init method to create a provider.
 
 @param password An user-provided password
 @param identifier The data saved in the keychain will be accessed with this identifier
 
 @return A key provider
 
 @see CDTEncryptionKeychainManager
 */
+ (instancetype)providerWithPassword:(NSString *)password forIdentifier:(NSString *)identifier;

@end
