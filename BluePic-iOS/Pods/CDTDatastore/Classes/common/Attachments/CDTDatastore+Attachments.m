//
//  CDTDatastore+Attachments.m
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

#import "CDTDatastore+Attachments.h"

#import <FMDB/FMDatabase.h>
#import <FMDB/FMDatabaseAdditions.h>
#import <FMDB/FMDatabaseQueue.h>

#import "TD_Database.h"
#import "TD_Database+Attachments.h"
#import "TDBlobStore.h"
#import "TDInternal.h"
#import "TDMisc.h"

#import "CDTDocumentRevision.h"
#import "CDTAttachment.h"
#import "CDTLogging.h"

#include <CommonCrypto/CommonDigest.h>

@implementation CDTDatastore (Attachments)

#pragma mark SQL statements

const NSString *SQL_ATTACHMENTS_SELECT =
    @"SELECT sequence, filename, key, type, encoding, length, encoded_length revpos "
    @"FROM attachments WHERE filename = :filename AND sequence = :sequence";

const NSString *SQL_ATTACHMENTS_SELECT_ALL =
    @"SELECT sequence, filename, key, type, encoding, length, encoded_length revpos "
    @"FROM attachments WHERE sequence = :sequence";

const NSString *SQL_DELETE_ATTACHMENT_ROW =
    @"DELETE FROM attachments WHERE filename = :filename AND sequence = :sequence";

const NSString *SQL_INSERT_ATTACHMENT_ROW = @"INSERT INTO attachments "
    @"(sequence, filename, key, type, encoding, length, encoded_length, revpos) "
    @"VALUES (:sequence, :filename, :key, :type, :encoding, :length, :encoded_length, :revpos)";

static NSString *const CDTAttachmentsErrorDomain = @"CDTAttachmentsErrorDomain";

#pragma mark Getting attachments

/**
 Returns the names of attachments for a document revision.

 @return NSArray of CDTAttachment
 */
- (NSArray *)attachmentsForRev:(CDTDocumentRevision *)rev error:(NSError *__autoreleasing *)error;
{
    FMDatabaseQueue *db_queue = self.database.fmdbQueue;

    __block NSArray *attachments;

    __weak CDTDatastore *weakSelf = self;

    [db_queue inDatabase:^(FMDatabase *db) {

        CDTDatastore *strongSelf = weakSelf;
        attachments = [strongSelf attachmentsForRev:rev inTransaction:db error:error];
    }];

    return attachments;
}

- (NSArray *)attachmentsForRev:(CDTDocumentRevision *)rev
                 inTransaction:(FMDatabase *)db
                         error:(NSError *__autoreleasing *)error
{
    NSMutableArray *attachments = [NSMutableArray array];

    // Get all attachments for this revision using the revision's
    // sequence number

    NSDictionary *params = @{ @"sequence" : @(rev.sequence) };
    FMResultSet *r =
        [db executeQuery:[SQL_ATTACHMENTS_SELECT_ALL copy] withParameterDictionary:params];

    @try {
        while ([r next]) {
            CDTSavedAttachment *attachment = [self attachmentFromDbRow:r inDatabase:db];

            if (attachment != nil) {
                [attachments addObject:attachment];
            } else {
                CDTLogInfo(CDTDATASTORE_LOG_CONTEXT,
                        @"Error reading an attachment row for attachments on doc <%@, %@>"
                        @"Closed connection during read?",
                        rev.docId, rev.revId);
            }
        }
    }
    @finally { [r close]; }

    return attachments;
}

- (CDTSavedAttachment *)attachmentFromDbRow:(FMResultSet *)r inDatabase:(FMDatabase *)db
{
    // SELECT sequence, filename, key, type, encoding, length, encoded_length revpos ...
    SequenceNumber sequence = [r longForColumn:@"sequence"];
    NSString *name = [r stringForColumn:@"filename"];

    // Validate key data (required to get to the file) before
    // we construct the attachment instance.
    NSData *keyData = [r dataNoCopyForColumn:@"key"];
    if (keyData.length != sizeof(TDBlobKey)) {
        CDTLogWarn(CDTDATASTORE_LOG_CONTEXT, @"%@: Attachment %lld.'%@' has bogus key size %u", self,
                sequence, name, (unsigned)keyData.length);
        //*outStatus = kTDStatusCorruptError;
        return nil;
    }

    id<CDTBlobReader> blob = [self.database blobForKey:*(TDBlobKey *)keyData.bytes withDatabase:db];

    NSString *type = [r stringForColumn:@"type"];
    NSInteger size = [r longForColumn:@"length"];
    NSInteger revpos = [r longForColumn:@"revpos"];
    TDAttachmentEncoding encoding = [r intForColumn:@"encoding"];
    CDTSavedAttachment *attachment = [[CDTSavedAttachment alloc] initWithBlob:blob
                                                                         name:name
                                                                         type:type
                                                                         size:size
                                                                       revpos:revpos
                                                                     sequence:sequence
                                                                          key:keyData
                                                                     encoding:encoding];

    return attachment;
}

/*
 Streams attachment data into a blob in the blob store.
 Returns nil if there was a problem, otherwise a dictionary
 with the sha and size of the file.
 */
- (NSDictionary *)streamAttachmentToBlobStore:(CDTAttachment *)attachment
                                        error:(NSError *__autoreleasing *)error
{
    NSAssert(attachment != nil, @"Attachment object was nil");

    TDBlobKey outKey;

    NSData *attachmentContent = [attachment dataFromAttachmentContent];

    if (nil == attachmentContent) {
        CDTLogWarn(CDTDATASTORE_LOG_CONTEXT, @"CDTDatastore: attachment %@ had no data; failing.",
                attachment.name);

        if (error) {
            NSString *desc = NSLocalizedString(@"Attachment has no data.", nil);
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : desc};
            *error = [NSError errorWithDomain:TDHTTPErrorDomain
                                         code:kTDStatusAttachmentStreamError
                                     userInfo:userInfo];
        }

        return nil;
    }

    BOOL success = [self.database storeBlob:attachmentContent creatingKey:&outKey error:error];

    if (!success) {
        // -storeBlob:creatingKey:error: will have filled in error

        CDTLogWarn(CDTDATASTORE_LOG_CONTEXT, @"CDTDatastore: Couldn't save attachment %@: %@",
                attachment.name, *error);
        return nil;
    }

    NSData *keyData = [NSData dataWithBytes:&outKey length:sizeof(TDBlobKey)];

    NSDictionary *attachmentData = @{
        @"attachment" : attachment,
        @"keyData" : keyData,
        @"fileLength" : @(attachmentContent.length)
    };
    return attachmentData;
}

/*
 Add the row in the attachments table for a given attachment.
 The attachments dict should store the attachments CDTAttachment
 object, its length and its sha key.
 */
- (BOOL)addAttachment:(NSDictionary *)attachmentData
                toRev:(CDTDocumentRevision *)revision
           inDatabase:(FMDatabase *)db
{
    if (attachmentData == nil) {
        return NO;
    }

    NSData *keyData = attachmentData[@"keyData"];
    NSNumber *fileLength = attachmentData[@"fileLength"];
    CDTAttachment *attachment = attachmentData[@"attachment"];

    __block BOOL success;

    //
    // Create appropriate rows in the attachments table
    //

    // Insert rows for the new attachment into the attachments database
    SequenceNumber sequence = revision.sequence;
    NSString *filename = attachment.name;
    NSString *type = attachment.type;
    TDAttachmentEncoding encoding = kTDAttachmentEncodingNone;  // from a raw input stream
    unsigned generation = [TD_Revision generationFromRevID:revision.revId];

    NSDictionary *params;

    // delete any existing entry for this file and sequence combo
    params = @{ @"filename" : filename, @"sequence" : @(sequence) };
    success = [db executeUpdate:[SQL_DELETE_ATTACHMENT_ROW copy] withParameterDictionary:params];

    if (!success) {
        return NO;
    }

    params = @{
        @"sequence" : @(sequence),
        @"filename" : filename,
        @"key" : keyData,  // how TDDatabase+Attachments does it
        @"type" : type,
        @"encoding" : @(encoding),
        @"length" : fileLength,
        @"encoded_length" : fileLength,  // we don't zip, so same as length, see TDDatabase+Atts
        @"revpos" : @(generation),
    };

    // insert new record
    success = [db executeUpdate:[SQL_INSERT_ATTACHMENT_ROW copy] withParameterDictionary:params];

    // We don't remove the blob from the store on !success because
    // it could be referenced from another attachment (as files are
    // only stored once per sha1 of file data).

    return success;
}

@end
