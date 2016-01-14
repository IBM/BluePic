//
//  CDTEncryptionKeychainUtils+PBKDF2.h
//  CloudantSync
//
//  Created by Enrique de la Torre Fernandez on 13/04/2015.
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

#import "CDTEncryptionKeychainUtils.h"

/**
 Utility class to derive a key from a user-provided password using PBKDF2:
 http://en.wikipedia.org/wiki/PBKDF2

 The resulting key is a stronger password that can be used as a cryptographic key in subsequent
 operations.
 */
@interface CDTEncryptionKeychainUtils (PBKDF2)

/**
 Generates a key by using the PBKDF2 algorithm.

 @param length Size of the key in bytes
 @param password The password that is used to generate the key
 @param salt The salt that is used to generate the key
 @param iterations The number of iterations that is passed to the key generation algorithm

 @return The generated key
 */
+ (NSData *)deriveKeyOfLength:(NSUInteger)length
                 fromPassword:(NSString *)password
                    usingSalt:(NSData *)salt
                   iterations:(NSUInteger)iterations;

@end
