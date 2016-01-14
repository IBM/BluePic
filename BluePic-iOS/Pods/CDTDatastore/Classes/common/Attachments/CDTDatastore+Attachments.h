//
//  CDTDatastore+Attachments.h
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

#import "CDTDatastore.h"

/**
 * Indexing and query erors.
 */
typedef NS_ENUM(NSInteger, CDTAttachmentError) {
    /**
     * Index name not valid. Names can only contain letters,
     * digits and underscores. They must not start with a digit.
     */
    CDTAttachmentErrorInvalidAttachmentName = 1,
    /**
     * An SQL error occurred.
     */
    CDTAttachmentErrorSqlError = 2,
    /**
     * No index with this name was found.
     */
    CDTAttachmentErrorAttachmentDoesNotExist = 3,
    /**
     * Disk space ran out while writing attachment
     */
    CDTAttachmentErrorInsufficientSpace = 4
};

@class CDTAttachment;

@interface CDTDatastore (Attachments)

/**
 Returns the attachments for a document revision.

 @return NSArray of CDTAttachment
 */
- (NSArray *)attachmentsForRev:(CDTDocumentRevision *)rev error:(NSError *__autoreleasing *)error;

- (NSArray *)attachmentsForRev:(CDTDocumentRevision *)rev
                 inTransaction:(FMDatabase *)db
                         error:(NSError *__autoreleasing *)error;

/*
 Streams attachment data into a blob in the blob store.
 Returns nil if there was a problem, otherwise a dictionary
 with the sha and size of the file.
 */
- (NSDictionary *)streamAttachmentToBlobStore:(CDTAttachment *)attachment
                                        error:(NSError *__autoreleasing *)error;

/*
 Add the row in the attachments table for a given attachment.
 The attachments dict should store the attachments CDTAttachment
 object, its length and its sha key.
 */
- (BOOL)addAttachment:(NSDictionary *)attachmentData
                toRev:(CDTDocumentRevision *)revision
           inDatabase:(FMDatabase *)db;

@end
