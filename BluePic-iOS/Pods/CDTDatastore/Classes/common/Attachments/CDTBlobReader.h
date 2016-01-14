//
//  CDTBlobReader.h
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

/**
 Define methods to access the content of an attachment without exposing its path.
 */
@protocol CDTBlobReader <NSObject>

/**
 Load the content of an attachment in a NSData instance.
 
 @param error Output param that will point to an error (in case there is any)
 
 @return Content of the attachment as a NSData instance or nil if there is an error
 
 @warning This operation is synchronous and reads the file content into memory before returning;
 this may cause issues with larger files..
 */
- (NSData *)dataWithError:(NSError **)error;

/**
 Create an input stream to read from an attachment.
 
 @param outputLength Output param with the size of the data in the attachment
 
 @return Input stream to the attachment or nil if there is an error
 */
- (NSInputStream *)inputStreamWithOutputLength:(UInt64 *)outputLength;

@end
