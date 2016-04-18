//
//  CDTBlobHandleFactory.m
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

#import "CDTBlobHandleFactory.h"

#import "CDTBlobData.h"
#import "CDTBlobEncryptedData.h"

@interface CDTBlobHandleFactory ()

@property (strong, nonatomic, readonly) CDTEncryptionKey *encryptionKeyOrNil;

@end

@implementation CDTBlobHandleFactory

#pragma mark - Init object
- (instancetype)init { return [self initWithEncryptionKeyProvider:nil]; }

- (instancetype)initWithEncryptionKeyProvider:(id<CDTEncryptionKeyProvider>)provider
{
    Assert(provider, @"Key provider is mandatory. Supply a CDTNilEncryptionKeyProvider instead.");

    self = [super init];
    if (self) {
        _encryptionKeyOrNil = [provider encryptionKey];
    }

    return self;
}

#pragma mark - Public methods
- (id<CDTBlobReader>)readerWithPath:(NSString *)path { return [self blobWithPath:path]; }

- (id<CDTBlobWriter>)writerWithPath:(NSString *)path { return [self blobWithPath:path]; }

#pragma mark - Private methods
- (id<CDTBlobReader, CDTBlobWriter>)blobWithPath:(NSString *)path
{
    return (self.encryptionKeyOrNil
                ? [CDTBlobEncryptedData blobWithPath:path encryptionKey:self.encryptionKeyOrNil]
                : [CDTBlobData blobWithPath:path]);
}

#pragma mark - Public class methods
+ (instancetype)factoryWithEncryptionKeyProvider:(id<CDTEncryptionKeyProvider>)provider
{
    return [[[self class] alloc] initWithEncryptionKeyProvider:provider];
}

@end
