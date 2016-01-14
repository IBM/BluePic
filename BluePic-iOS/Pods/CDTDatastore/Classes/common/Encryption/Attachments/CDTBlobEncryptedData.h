//
//  CDTBlobEncryptedData.h
//  CloudantSync
//
//  Created by Enrique de la Torre Fernandez on 21/05/2015.
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

#import "CDTBlobReader.h"
#import "CDTBlobWriter.h"

#import "CDTEncryptionKey.h"

extern NSString *const CDTBlobEncryptedDataErrorDomain;

typedef NS_ENUM(NSInteger, CDTBlobEncryptedDataError) {
    CDTBlobEncryptedDataErrorFileTooSmall,
    CDTBlobEncryptedDataErrorWrongVersion,
    CDTBlobEncryptedDataErrorNoDataProvided
};

/**
 Use this class to read/write an encrypted attachment.
 
 An attachment has the following structure:
 
 --------------------------------------------------------------------------
 |  Version - 1-byte  |  IV - 16-bytes |          Encrypted blob          |
 --------------------------------------------------------------------------
 |                  header             |              body                |
 --------------------------------------------------------------------------
 
 As its counterpart 'CDTBlobData', this class conforms to protocols 'CDTBlobReader' &
 'CDTBlobWriter'. Notice the beaviour of the methods defined in 'CDTBlobReader' in relation to
 'CDTBlobWriter':
 
 - 'dataWithError:'.- It will fail if the blob is open.
 - 'inputStreamWithOutputLength:'.- As the previous method, it will fail if the blob is open.
 
 Also, notice some details about the methods defined in 'CDTBlobWriter':
 
 - 'dataWithError:'.- An encrypted attachment will always have a header but it might not have a
 body. In that case, this method will return an empty 'NSData' instance and no error will be
 returned.
 - 'createBlobWithData:error:'.- If the data passed to this method is an empty 'NSData' instance,
 it will create an attachment with a header but not a body.
 - 'openBlobToAddData'.- As decribed in the documentation for this protocol, this method will create
 a file or it will delete the existing content. This implementation will also add a header to the
 file.
 
 @see CDTBlobData
 @see CDTBlobReader
 @see CDTBlobWriter
 */
@interface CDTBlobEncryptedData : NSObject <CDTBlobReader, CDTBlobWriter>

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithPath:(NSString *)path
               encryptionKey:(CDTEncryptionKey *)encryptionKey NS_DESIGNATED_INITIALIZER;

+ (instancetype)blobWithPath:(NSString *)path encryptionKey:(CDTEncryptionKey *)encryptionKey;

@end
