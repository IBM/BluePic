//
//  FMDatabase+EncryptionKey.h
//  CloudantSync
//
//  Created by Enrique de la Torre Fernandez on 27/04/2015.
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

#import "FMDatabase.h"

#import "CDTEncryptionKeyProvider.h"

extern NSString *const FMDatabaseEncryptionKeyErrorDomain;

/**
 Errors for 'setKeyWithProvider:error:'
 */
typedef NS_ENUM(NSInteger, FMDatabaseEncryptionKeyError) {
    FMDatabaseEncryptionKeyErrorKeyNotSet,
    FMDatabaseEncryptionKeyErrorDBCorruptedOrNoKeyProvided,
    FMDatabaseEncryptionKeyErrorWrongKeyOrDBNotEncrypted
};

@interface FMDatabase (EncryptionKey)

/**
 This method performs 3 steps:
 - Get an encryption key from the provider
 - Set the key (if there is any, a provider can return nil)
 - Check that the db can be read

 @param provider Returns the key to decipher the db (or nil)
 @param error Output param, it will contain an error if the method does not succeed

 @return `YES` if success, `NO` on error.
 */
- (BOOL)setKeyWithProvider:(id<CDTEncryptionKeyProvider>)provider error:(NSError **)error;

@end
