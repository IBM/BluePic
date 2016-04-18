//
//  CDTAttachment.h
//
//
//  Created by Michael Rhodes on 24/03/2014.
//  Copyright (c) 2014 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.
//

#import <Foundation/Foundation.h>

#import "TD_Database.h"
#import "TD_Database+Attachments.h"

#import "CDTBlobReader.h"

/**
 Base class for attachments in the datastore.

 This object is an abstract class, in use at least. Attachments
 that are read from the database will always be CDTSavedAttachment
 objects, indicating that they've come from the database.
 Attachments to be added to the database will be objects of type,
 by naming convention alone, CDTUnsaved<something>Attachment.

 The idea is that unsaved attachments can come from various places,
 and developers using this library can subclass CDTAttachment,
 implementing the -getInputStream method as needed for their
 needs. The library provides some unsaved attachment classes
 for convenience and as examples:

   - CDTUnsavedDataAttachment: provides a wrapped around an
       NSData instance to be added as an attachment.


 */
@interface CDTAttachment : NSObject

// common
@property (nonatomic, strong, readonly) NSString *name;

/** Mimetype string */
@property (nonatomic, strong, readonly) NSString *type;

/* Size in bytes, may be -1 if not known (e.g., HTTP URL for new attachment) */
@property (nonatomic, readonly) NSInteger size;

/** Subclasses should call this to initialise instance vars */
- (instancetype)initWithName:(NSString *)name type:(NSString *)type size:(NSInteger)size;

/** Get unopened input stream for this attachment */
- (NSData *)dataFromAttachmentContent;

@end

/**
 An attachment retrieved from the datastore.

 These attachment objects are immutable as they represent
 revisions already in the database.
 */
@interface CDTSavedAttachment : CDTAttachment

@property (nonatomic, readonly) NSInteger revpos;
@property (nonatomic, readonly) SequenceNumber sequence;
@property (nonatomic, readonly) TDAttachmentEncoding encoding;

/** sha of file, used for file path on disk. */
@property (nonatomic, readonly) NSData *key;

- (instancetype)initWithBlob:(id<CDTBlobReader>)blob
                        name:(NSString *)name
                        type:(NSString *)type
                        size:(NSInteger)size
                      revpos:(NSInteger)revpos
                    sequence:(SequenceNumber)sequence
                         key:(NSData *)keyData
                    encoding:(TDAttachmentEncoding)encoding;

@end

/**
 An attachment to be inserted into the database, using
 data from an NSData instance as input data for the attachment.
 */
@interface CDTUnsavedDataAttachment : CDTAttachment

/**
 Create a new unsaved attachment using an NSData instance
 as the source of attachment data.
 */
- (instancetype)initWithData:(NSData *)data name:(NSString *)name type:(NSString *)type;

@end

/**
 An attachment to be inserted into the database, using
 data from a file as input data for the attachment.
 */
@interface CDTUnsavedFileAttachment : CDTAttachment

- (instancetype)initWithPath:(NSString *)filePath name:(NSString *)name type:(NSString *)type;

@end

@interface CDTSavedHTTPAttachment : CDTAttachment

/**

 Creates a CDTRemoteAttachment object from information obtained from
 the _attachments object in a couch get request

 @param name The name of the attachment eg example.txt
 @param jsonData The decoded jsonData reccived from couchdb / cloudant
 @param document the URL of the document this attachment is attached to
 @param error will point to an NSError object in case of error

 */
+ (CDTSavedHTTPAttachment *)createAttachmentWithName:(NSString *)name
                                            JSONData:(NSDictionary *)jsonData
                                       attachmentURL:(NSURL *)attachmentURL
                                               error:(NSError *__autoreleasing *)error;
/**

 Creates an attachment that represents a remote HTTP accessed attachment

 @param attachmentURL the URL to the attachment file
 @param name the name of the attachment
 @param type the mime type of the attachment eg image/jpeg
 @param size the size of the file in bytes (-1 if unkown)
 @param data attschment data if it has already been downloaded

 */
- (id)initWithDocumentURL:(NSURL *)attachmentURL
                     name:(NSString *)name
                     type:(NSString *)type
                     size:(NSInteger)size
                     data:(NSData *)data;

/**

 Returns the data for an attachment. If attachment data requries downloading, (ie it was not
 provided
 in the JSON with the document download) it will block while downloading the data from the remote
 server

 @return the attachments data

 */
- (NSData *)dataFromAttachmentContent;
@end
