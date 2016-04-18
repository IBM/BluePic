//
//  CDTBlobHandleFactory.h
//  CloudantSync
//
//  Created by Enrique de la Torre Fernandez on 22/05/2015.
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

#import "CDTBlobReader.h"
#import "CDTBlobWriter.h"

/**
 Given an encryption key provider, this class creates instances that conforms to protocols:
 CDTBlobReader & CDTBlobWriter; and are able to encrypt/decrypt an attachment depending on the key
 returned by the provider.
 
 If the key provider return nil, the instances of CDTBlobReader & CDTBlobWriter will not cipher the
 data. In other case, the information will be ciphered before saving to disk and deciphering
 beforing returning it.
 
 @see CDTEncryptionKeyProvider
 @see CDTBlobReader
 @see CDTBlobWriter
 */
@interface CDTBlobHandleFactory : NSObject

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/**
 Initialise a factory
 
 @param provider An encryption key provider
 
 @warning The key provider is mandatory; if it is not supplied, an exception will be raised.
 */
- (instancetype)initWithEncryptionKeyProvider:(id<CDTEncryptionKeyProvider>)provider
    NS_DESIGNATED_INITIALIZER;

- (id<CDTBlobReader>)readerWithPath:(NSString *)path;

- (id<CDTBlobWriter>)writerWithPath:(NSString *)path;

/**
 Return an instance of this class or a subclass that inherits from this one.
 
 @param provider An encryption key provider
 
 @warning The key provider is mandatory; if it is not supplied, an exception will be raised.
 */
+ (instancetype)factoryWithEncryptionKeyProvider:(id<CDTEncryptionKeyProvider>)provider;

@end
