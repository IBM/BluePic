//
//  CDTDatastore+EncryptionKey.h
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

#import "CDTDatastore.h"

@protocol CDTEncryptionKeyProvider;

@interface CDTDatastore (EncryptionKey)

/**
 * Initialize a CDTDatastore object
 *
 * @param manager this datastore's manager, must not be nil.
 * @param database a database to read/write documents
 * @param provider it will return a key to decipher the database
 *
 * @return an initialized datastore, or nil if an object could not be created
 */
- (instancetype)initWithManager:(CDTDatastoreManager *)manager
                       database:(TD_Database *)database
          encryptionKeyProvider:(id<CDTEncryptionKeyProvider>)provider;

/**
 * Return the key provider used to encrypt the datastore
 */
- (id<CDTEncryptionKeyProvider>)encryptionKeyProvider;

@end
