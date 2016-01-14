//
//  CDTBlobData.h
//  CloudantSync
//
//  Created by Enrique de la Torre Fernandez on 05/05/2015.
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

extern NSString *const CDTBlobDataErrorDomain;

typedef NS_ENUM(NSInteger, CDTBlobDataError) {
    CDTBlobDataErrorNoDataProvided,
    CDTBlobDataErrorOperationNotPossibleIfBlobIsOpen
};

/**
 Use this class to read/write an attachment. The data read from an attachment is returned as it is,
 so make sure that the attachment is not encrypted. In the same way, the data provided is written to
 disk without further processing.
 
 To accomplish this purpose, this class conforms to 2 related protocols: 'CDTBlobReader' &
 'CDTBlobWriter'. Notice the beaviour of the methods defined in 'CDTBlobReader' in relation to
 'CDTBlobWriter':
 
 - 'dataWithError:'.- It will fail if the blob is open.
 - 'inputStreamWithOutputLength:'.- As the previous method, it will fail if the blob is open.
 
 @see CDTBlobReader
 @see CDTBlobWriter
 */
@interface CDTBlobData : NSObject <CDTBlobReader, CDTBlobWriter>

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithPath:(NSString *)path NS_DESIGNATED_INITIALIZER;

+ (instancetype)blobWithPath:(NSString *)path;

@end
