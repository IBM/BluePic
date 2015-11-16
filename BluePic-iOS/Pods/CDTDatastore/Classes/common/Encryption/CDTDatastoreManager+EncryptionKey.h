//
//  CDTDatastoreManager+EncryptionKey.h
//  
//
//  Created by Enrique de la Torre Fernandez on 10/03/2015.
//
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.
//

#import "CDTDatastoreManager.h"

@protocol CDTEncryptionKeyProvider;

@interface CDTDatastoreManager (EncryptionKey)

/**
 Returns a datastore for the given name. It also requires a key provider, the key returned by this
 provider will be used to cipher the datastore (attachments and extensions not included). The
 provider is always mandatory, in case you do not want to encrypt the data, you have to supply a
 CDTEncryptionKeyNilProvider instance or any other object that conforms to protocol
 CDTEncryptionKeyProvider and returns nil when the key is requested.
 
 If a key is provided the first time the datastore is open, only this key will be valid the next
 time. If no key is informed, the datastore will not be cipher and it can not be cipher later on.
 
 @param name datastore name
 @param provider it returns the key to cipher the datastore
 @param error will point to an NSError object in case of error.
 
 @return a datastore for the given name

 @warning *Warning:* It will always return nil unless you use subspec 'CDTDatastore/SQLCipher'
 
 @see CDTDatastore
 @see CDTEncryptionKeyProvider
 @see CDTEncryptionKeyNilProvider
 */
- (CDTDatastore *)datastoreNamed:(NSString *)name
       withEncryptionKeyProvider:(id<CDTEncryptionKeyProvider>)provider
                           error:(NSError *__autoreleasing *)error;

@end
