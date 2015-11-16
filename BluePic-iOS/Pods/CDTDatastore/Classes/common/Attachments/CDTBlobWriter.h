//
//  CDTBlobWriter.h
//  CloudantSync
//
//  Created by Enrique de la Torre Fernandez on 06/05/2015.
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

/**
 Define methods to store data in an attachment without exposing its path.
 */
@protocol CDTBlobWriter <NSObject>

/**
 Overwrite the content of an attachment with the data provided as a parameter. If the file does
 not exist, it will create it.
 
 If the blob is open, this method will fail.
 
 @param data Data to store in the attachment
 @param error Output param that will point to an error (if there is any)
 
 @return YES (if the operation succeed) or NO (if there is an error)
 */
- (BOOL)writeEntireBlobWithData:(NSData *)data error:(NSError **)error;

/**
 By default, a blob is closed until it is open.
 
 @return YES if the attachment was open before or NO in other case
 */
- (BOOL)isBlobOpenForWriting;

/**
 Prepare an attachment to write data in it.
 
 If the file does not exist, it will create it now. If the file exists, it will delete the existing
 content and move the pointer to the begining of the file.
 
 @return YES if the attachment was open (or it was already open) or NO in other case
 */
- (BOOL)openForWriting;

/**
 Add data to the end of the attachment.
 
 The blob has to be open before calling this method, otherwise it will fail.
 
 @param data Data to append to the attachment
 
 @return YES if the data was added or NO in other case.
 */
- (BOOL)appendData:(NSData *)data;

/**
 Use this method to signal that there are no more data to add.
 
 @warning Notice that, even if no data is added to the blob, the file created with
 'openBlobToAddData' will not be removed.
 */
- (void)close;

@end
