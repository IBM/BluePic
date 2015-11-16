//
//  TD_Database+Attachments.m
//  TouchDB
//
//  Created by Jens Alfke on 12/19/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//
//  Modifications for this distribution by Cloudant, Inc., Copyright (c) 2014 Cloudant, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.
//
//  http://wiki.apache.org/couchdb/HTTP_Document_API#Attachments

/*
    Here's what an actual _attachments object from CouchDB 1.2 looks like.
    The "revpos" and "digest" attributes aren't documented in the wiki (yet).

    "_attachments":{
        "index.txt":{"content_type":"text/plain", "revpos":1,
                     "digest":"md5-muNoTiLXyJYP9QkvPukNng==", "length":9, "stub":true}}
*/

#import "TD_Database+Attachments.h"
#import "TD_Database+Insertion.h"
#import "TDBase64.h"
#import "TDBlobStore.h"
#import "TD_Attachment.h"
#import "TD_Body.h"
#import "TDMultipartWriter.h"
#import "TDMisc.h"
#import "TDInternal.h"

#import "CollectionUtils.h"
#import <FMDB/FMDatabase.h>
#import <FMDB/FMDatabaseQueue.h>
#import <FMDB/FMDatabaseAdditions.h>
#import <FMDB/FMResultSet.h>
#import "GTMNSData+zlib.h"

#import "CDTLogging.h"

// Length that constitutes a 'big' attachment
#define kBigAttachmentLength (16 * 1024)

@implementation TD_Database (Attachments)

- (TDBlobStoreWriter*)attachmentWriter
{
    return [[TDBlobStoreWriter alloc] initWithStore:_attachments];
}

- (void)rememberAttachmentWritersForDigests:(NSDictionary*)blobsByDigests
{
    if (!_pendingAttachmentsByDigest)
        _pendingAttachmentsByDigest = [[NSMutableDictionary alloc] init];
    [_pendingAttachmentsByDigest addEntriesFromDictionary:blobsByDigests];
}

- (void)rememberPendingKey:(TDBlobKey)key forDigest:(NSString*)digest
{
    if (!_pendingAttachmentsByDigest)
        _pendingAttachmentsByDigest = [[NSMutableDictionary alloc] init];
    NSData* keyData = [NSData dataWithBytes:&key length:sizeof(TDBlobKey)];
    _pendingAttachmentsByDigest[digest] = keyData;
}

- (void)rememberAttachmentWriter:(TDBlobStoreWriter*)writer forDigest:(NSString*)digest
{
    if (!_pendingAttachmentsByDigest)
        _pendingAttachmentsByDigest = [[NSMutableDictionary alloc] init];
    _pendingAttachmentsByDigest[digest] = writer;
}

// This is ONLY FOR TESTS (see TDMultipartDownloader.m)
#if DEBUG
- (id)attachmentWriterForAttachment:(NSDictionary*)attachment
{
    NSString* digest = $castIf(NSString, attachment[@"digest"]);
    if (!digest) return nil;
    return _pendingAttachmentsByDigest[digest];
}
#endif

/**
 Pulls a "follows" attachment from the writer's pending store
 into the local blob store, or perhaps the attachment is already
 in the store, in which case we just fill in the attachment's
 data.
 */
- (TDStatus)installAttachment:(TD_Attachment*)attachment
                 withDatabase:(FMDatabase *)db
                      forInfo:(NSDictionary*)attachInfo
{
    NSString* digest = $castIf(NSString, attachInfo[@"digest"]);
    if (!digest) return kTDStatusBadAttachment;
    id writer = _pendingAttachmentsByDigest[digest];

    if ([writer isKindOfClass:[TDBlobStoreWriter class]]) {
        // Found a blob writer, so install the blob:
        if (![writer installWithDatabase:db]) return kTDStatusAttachmentError;
        attachment->blobKey = [writer blobKey];
        attachment->length = [writer length];
        // Remove the writer but leave the blob-key behind for future use:
        [self rememberPendingKey:attachment->blobKey forDigest:digest];
        return kTDStatusOK;

    } else if ([writer isKindOfClass:[NSData class]]) {
        // This attachment was already added, but the key was left behind in the dictionary:
        attachment->blobKey = *(TDBlobKey*)[writer bytes];
        NSNumber* lengthObj = $castIf(NSNumber, attachInfo[@"length"]);
        if (!lengthObj) return kTDStatusBadAttachment;
        attachment->length = lengthObj.unsignedLongLongValue;
        return kTDStatusOK;

    } else {
        return kTDStatusBadAttachment;
    }
}

- (NSUInteger)blobCount
{
    __block NSUInteger n = 0;
    
    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        n = [_attachments countWithDatabase:db];
    }];
    
    return n;
}

- (id<CDTBlobReader>)blobForKey:(TDBlobKey)key
{
    __block id<CDTBlobReader> reader = nil;
    
    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        reader = [_attachments blobForKey:key withDatabase:db];
    }];
    
    return reader;
}

- (id<CDTBlobReader>)blobForKey:(TDBlobKey)key withDatabase:(FMDatabase *)db
{
    id<CDTBlobReader> reader = [_attachments blobForKey:key withDatabase:db];
    
    return reader;
}

- (BOOL)storeBlob:(NSData*)blob creatingKey:(TDBlobKey*)outKey
{
    NSError* error;
    return [self storeBlob:blob creatingKey:outKey error:&error];
}

- (BOOL)storeBlob:(NSData *)blob creatingKey:(TDBlobKey *)outKey withDatabase:(FMDatabase *)db
{
    NSError* error;
    return [self storeBlob:blob creatingKey:outKey withDatabase:db error:&error];
}

- (BOOL)storeBlob:(NSData *)blob
      creatingKey:(TDBlobKey *)outKey
            error:(NSError *__autoreleasing *)outError
{
    __block BOOL success = YES;

    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
      success = [_attachments storeBlob:blob creatingKey:outKey withDatabase:db error:outError];
    }];

    return success;
}

- (BOOL)storeBlob:(NSData *)blob
      creatingKey:(TDBlobKey *)outKey
     withDatabase:(FMDatabase *)db
            error:(NSError *__autoreleasing *)outError
{
    BOOL success = [_attachments storeBlob:blob creatingKey:outKey withDatabase:db error:outError];

    return success;
}

/**
 All this does is insert the row in the attachments table for the
 attachment. It should be called when the attachment isn't already
 present for a previous revision.
 */
- (TDStatus)insertAttachment:(TD_Attachment*)attachment
                 forSequence:(SequenceNumber)sequence
                  inDatabase:(FMDatabase*)db
{
    Assert(sequence > 0);
    Assert(attachment.isValid);
    NSData* keyData = [NSData dataWithBytes:&attachment->blobKey length:sizeof(TDBlobKey)];
    id encodedLengthObj = attachment->encoding ? @(attachment->encodedLength) : nil;

    bool success;
    success = [db
        executeUpdate:@"INSERT INTO attachments "
                       "(sequence, filename, key, type, encoding, length, encoded_length, revpos) "
                       "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                      @(sequence), attachment.name, keyData, attachment.contentType,
                      @(attachment->encoding), @(attachment->length), encodedLengthObj,
                      @(attachment->revpos)];

    if (!success) {
        return kTDStatusDBError;
    }
    return kTDStatusCreated;
}

/**
 For an attachment that hasn't changed between revisions, we need to
 copy an existing row into one for this sequence to associate the
 attachment with this new revision/seq.

 This method will return kTDStatusNotFound if there isn't an attachment
 with the same name for the previous rev/seq.
 */
- (TDStatus)copyAttachmentNamed:(NSString*)name
                   fromSequence:(SequenceNumber)fromSequence
                     toSequence:(SequenceNumber)toSequence
                     inDatabase:(FMDatabase*)db
{
    Assert(name);
    Assert(toSequence > 0);
    Assert(toSequence > fromSequence);
    if (fromSequence <= 0) return kTDStatusNotFound;

    TDStatus result = kTDStatusOK;

    if (![db executeUpdate:
                 @"INSERT INTO attachments "
                  "(sequence, filename, key, type, encoding, encoded_Length, length, revpos) "
                  "SELECT ?, ?, key, type, encoding, encoded_Length, length, revpos "
                  "FROM attachments WHERE sequence=? AND filename=?",
                 @(toSequence), name, @(fromSequence), name]) {
        result = kTDStatusDBError;
    }
    if (db.changes == 0) {
        // Oops. This means a glitch in our attachment-management or pull code,
        // or else a bug in the upstream server.
        CDTLogWarn(CDTDATASTORE_LOG_CONTEXT,
                @"Can't find inherited attachment '%@' from seq#%lld to copy to #%lld", name,
                fromSequence, toSequence);
        result = kTDStatusNotFound;  // Fail if there is no such attachment on fromSequence
    }

    return result;
}

/**
 Copy all attachments from the old sequence to the new sequence.
 */
- (TDStatus)copyAttachmentsFromSequence:(SequenceNumber)fromSequence
                             toSequence:(SequenceNumber)toSequence
                             inDatabase:(FMDatabase*)db
{
    Assert(toSequence > 0);
    Assert(toSequence > fromSequence);
    if (fromSequence <= 0) return kTDStatusNotFound;

    TDStatus result = kTDStatusOK;

    if (![db executeUpdate:
                 @"INSERT INTO attachments "
                  "(sequence, filename, key, type, encoding, encoded_Length, length, revpos) "
                  "SELECT ?, filename, key, type, encoding, encoded_Length, length, revpos "
                  "FROM attachments WHERE sequence=?",
                 @(toSequence), @(fromSequence)]) {
        result = kTDStatusDBError;
    }

    return result;
}

/**
 Unzips an attachment data if required (may extend with different
 encoding possiblities in future.
 */
- (NSData*)decodeAttachment:(NSData*)attachment encoding:(TDAttachmentEncoding)encoding
{
    switch (encoding) {
        case kTDAttachmentEncodingNone:
            break;
        case kTDAttachmentEncodingGZIP:
            attachment = [NSData gtm_dataByInflatingData:attachment];
    }
    if (!attachment) CDTLogWarn(CDTDATASTORE_LOG_CONTEXT, @"Unable to decode attachment!");
    return attachment;
}

/**
 Returns the blob for an attachment in the blob store.

 The encoding type kTDAttachmentEncodingNone, kTDAttachmentEncodingGZIP
 is set as an out parameter
 */
- (id<CDTBlobReader>)getAttachmentBlobForSequence:(SequenceNumber)sequence
                                            named:(NSString *)filename
                                             type:(NSString **)outType
                                         encoding:(TDAttachmentEncoding *)outEncoding
                                           status:(TDStatus *)outStatus
{
    Assert(sequence > 0);
    Assert(filename);
    __block id<CDTBlobReader> blob = nil;

    [_fmdbQueue inDatabase:^(FMDatabase* db) {
        FMResultSet* r =
            [db executeQuery:
                    @"SELECT key, type, encoding FROM attachments WHERE sequence=? AND filename=?",
                    @(sequence), filename];
        if (!r) {
            *outStatus = kTDStatusDBError;
            return;
        }
        @try {
            if (![r next]) {
                *outStatus = kTDStatusNotFound;
                return;
            }
            NSData* keyData = [r dataNoCopyForColumnIndex:0];
            if (keyData.length != sizeof(TDBlobKey)) {
                CDTLogWarn(CDTDATASTORE_LOG_CONTEXT, @"%@: Attachment %lld.'%@' has bogus key size %u",
                        self, sequence, filename, (unsigned)keyData.length);
                *outStatus = kTDStatusCorruptError;
                return;
            }
            blob = [_attachments blobForKey:*(TDBlobKey*)keyData.bytes withDatabase:db];
            *outStatus = kTDStatusOK;
            if (outType) *outType = [r stringForColumnIndex:1];

            *outEncoding = [r intForColumnIndex:2];
        }
        @finally { [r close]; }
    }];

    return blob;
}

/**
 Returns the content and MIME type of an attachment
 */
- (NSData *)getAttachmentForSequence:(SequenceNumber)sequence
                               named:(NSString *)filename
                                type:(NSString **)outType
                            encoding:(TDAttachmentEncoding *)outEncoding
                              status:(TDStatus *)outStatus
{
    TDAttachmentEncoding encoding;
    id<CDTBlobReader> blob = [self getAttachmentBlobForSequence:sequence
                                                          named:filename
                                                           type:outType
                                                       encoding:&encoding
                                                         status:outStatus];
    if (!blob) {
        return nil;
    }

    NSError *error = nil;
    NSData *contents = [blob dataWithError:&error];
    if (!contents) {
        CDTLogWarn(CDTDATASTORE_LOG_CONTEXT, @"%@: Failed to load attachment %lld.'%@' -- %@", self,
                   sequence, filename, error);

        *outStatus = kTDStatusCorruptError;

        return nil;
    }

    if (outEncoding) {
        *outEncoding = encoding;
    } else {
        contents = [self decodeAttachment:contents encoding:encoding];
    }

    return contents;
}

/**
 Constructs an "_attachments" dictionary for a revision, to be inserted in its JSON body.

 This generates the dict for a seq because a seq is the autoincrement key
 in the revs table. So it's basically a quick way to get a given rev. It's
 a foreign key in the attachments table.
 */
- (NSDictionary*)getAttachmentDictForSequence:(SequenceNumber)sequence
                                      options:(TDContentOptions)options
                                   inDatabase:(FMDatabase*)db
{
    Assert(sequence > 0);
    __block NSMutableDictionary* attachments;

    FMResultSet* r =
        [db executeQuery:@"SELECT filename, key, type, encoding, length, encoded_length, revpos "
                          "FROM attachments WHERE sequence=?",
                         @(sequence)];
    if (!r) return nil;
    if (![r next]) {
        [r close];
        return nil;
    }
    BOOL decodeAttachments = !(options & kTDLeaveAttachmentsEncoded);
    attachments = $mdict();
    do {
        NSData* keyData = [r dataNoCopyForColumnIndex:1];
        NSString* digestStr = [@"sha1-" stringByAppendingString:[TDBase64 encode:keyData]];
        TDAttachmentEncoding encoding = [r intForColumnIndex:3];
        UInt64 length = [r longLongIntForColumnIndex:4];
        UInt64 encodedLength = [r longLongIntForColumnIndex:5];

        // Get the attachment contents if asked to:
        NSData* data = nil;
        BOOL dataSuppressed = NO;
        if (options & kTDIncludeAttachments) {
            UInt64 effectiveLength = (encoding && !decodeAttachments) ? encodedLength : length;
            if ((options & kTDBigAttachmentsFollow) && effectiveLength >= kBigAttachmentLength) {
                dataSuppressed = YES;
            } else {
                id<CDTBlobReader> blob = [_attachments blobForKey:*(TDBlobKey*)keyData.bytes
                                                     withDatabase:db];
                data = (blob ? [blob dataWithError:nil] : nil);
                if (!data)
                    CDTLogWarn(CDTDATASTORE_LOG_CONTEXT,
                            @"TD_Database: Failed to get attachment for key %@", keyData);
            }
        }

        NSString* encodingStr = nil;
        id encodedLengthObj = nil;
        if (encoding != kTDAttachmentEncodingNone) {
            // Decode the attachment if it's included in the dict:
            if (data && decodeAttachments) {
                data = [self decodeAttachment:data encoding:encoding];
            } else {
                encodingStr = @"gzip";  // the only encoding I know
                encodedLengthObj = @(encodedLength);
            }
        }

        attachments[[r stringForColumnIndex:0]] =
            $dict({ @"stub", ((data || dataSuppressed) ? nil : $true) },
                  { @"data", (data ? [TDBase64 encode:data] : nil) },
                  { @"follows", (dataSuppressed ? $true : nil) }, { @"digest", digestStr },
                  { @"content_type", [r stringForColumnIndex:2] }, { @"encoding", encodingStr },
                  { @"length", @(length) }, { @"encoded_length", encodedLengthObj },
                  { @"revpos", @([r intForColumnIndex:6]) });
    } while ([r next]);
    [r close];

    return attachments;
}

/**
 Return the blob for the file in the blob store pointed out by attachments dict.
 */
- (id<CDTBlobReader>)blobForAttachmentDict:(NSDictionary *)attachmentDict
{
    NSString* digest = attachmentDict[@"digest"];
    if (![digest hasPrefix:@"sha1-"]) {
        return nil;
    }
    
    NSData* keyData = [TDBase64 decode:[digest substringFromIndex:5]];
    if (!keyData) {
        return nil;
    }
    
    return [self blobForKey:*(TDBlobKey*)keyData.bytes];
}

// Calls the block on every attachment dictionary. The block can return a different dictionary,
// which will be replaced in the rev's properties. If it returns nil, the operation aborts.
// Returns YES if any changes were made.
+ (BOOL)mutateAttachmentsIn:(TD_Revision*)rev
                  withBlock:(NSDictionary* (^)(NSString*, NSDictionary*))block
{
    NSDictionary* properties = rev.properties;
    NSMutableDictionary* editedProperties = nil;
    NSDictionary* attachments = (id)properties[@"_attachments"];
    NSMutableDictionary* editedAttachments = nil;
    for (NSString* name in attachments) {
        @autoreleasepool
        {
            NSDictionary* attachment = attachments[name];
            NSDictionary* editedAttachment = block(name, attachment);
            if (!editedAttachment) {
                return NO;  // block canceled
            }
            if (editedAttachment != attachment) {
                if (!editedProperties) {
                    // Make the document properties and _attachments dictionary mutable:
                    editedProperties = [properties mutableCopy];
                    editedAttachments = [attachments mutableCopy];
                    editedProperties[@"_attachments"] = editedAttachments;
                }
                editedAttachments[name] = editedAttachment;
            }
        }
    }
    if (editedProperties) {
        rev.properties = editedProperties;
        return YES;
    }
    return NO;
}

// Replaces attachment data whose revpos is < minRevPos with stubs.
// If attachmentsFollow==YES, replaces data for remaining attachments with "follows" key.
+ (void)stubOutAttachmentsIn:(TD_Revision*)rev
                beforeRevPos:(int)minRevPos
           attachmentsFollow:(BOOL)attachmentsFollow
{
    if (minRevPos <= 1 && !attachmentsFollow) return;
    [self mutateAttachmentsIn:rev
                    withBlock:^NSDictionary * (NSString * name, NSDictionary * attachment) {
                        int revPos = [attachment[@"revpos"] intValue];
                        bool includeAttachment = (revPos == 0 || revPos >= minRevPos);
                        bool stubItOut = !includeAttachment && !attachment[@"stub"];
                        bool addFollows =
                            includeAttachment && attachmentsFollow && !attachment[@"follows"];
                        if (!stubItOut && !addFollows) return attachment;  // no change
                        // Need to modify attachment entry:
                        NSMutableDictionary* editedAttachment = [attachment mutableCopy];
                        [editedAttachment removeObjectForKey:@"data"];
                        if (stubItOut) {
                            // ...then remove the 'data' and 'follows' key:
                            [editedAttachment removeObjectForKey:@"follows"];
                            editedAttachment[@"stub"] = $true;
                            CDTLogVerbose(CDTDATASTORE_LOG_CONTEXT,
                                       @"Stubbed out attachment %@/'%@': revpos %d < %d", rev, name,
                                       revPos, minRevPos);
                        } else if (addFollows) {
                            [editedAttachment removeObjectForKey:@"stub"];
                            editedAttachment[@"follows"] = $true;
                            CDTLogVerbose(CDTDATASTORE_LOG_CONTEXT,
                                       @"Added 'follows' for attachment %@/'%@': revpos %d >= %d",
                                       rev, name, revPos, minRevPos);
                        }
                        return editedAttachment;
                    }];
}

// Replaces the "follows" key with the real attachment data in all attachments to 'doc'.
- (BOOL)inlineFollowingAttachmentsIn:(TD_Revision *)rev error:(NSError **)outError
{
    __block NSError *error = nil;
    
    [[self class] mutateAttachmentsIn:rev
                            withBlock:^NSDictionary * (NSString * name, NSDictionary * attachment) {
                                if (!attachment[@"follows"]) {
                                    return attachment;
                                }
                                
                                id<CDTBlobReader> blob = [self blobForAttachmentDict:attachment];
                                NSData *fileData = (blob ? [blob dataWithError:&error] : nil);
                                if (!fileData){
                                    return nil;
                                }
                                
                                NSMutableDictionary *editedAttachment = [attachment mutableCopy];
                                [editedAttachment removeObjectForKey:@"follows"];
                                editedAttachment[@"data"] = [TDBase64 encode:fileData];
                                return editedAttachment;
                            }];
    
    if (outError) {
        *outError = error;
    }
    
    return (error == nil);
}

/**
 Takes a TD_Revision and inserts the attachments contained
 in the revision into the attachment blob store and creates
 TD_Attachment objects representing each object.
  - inline attachments are saved to the store
  - follow attachments are given a placeholder TD_Attachment
  - stubs are given a placeholder TD_Attachment

 Returns the list of TD_Attachments derived from the revision.
 */
- (NSDictionary*)attachmentsFromRevision:(TD_Revision*)rev
                              inDatabase:(FMDatabase*)db
                                  status:(TDStatus*)outStatus
{
    // If there are no attachments in the new rev, there's nothing to do:
    NSDictionary* revAttachments = rev[@"_attachments"];
    if (revAttachments.count == 0 || rev.deleted) {
        *outStatus = kTDStatusOK;
        return @{};
    }

    TDStatus status = kTDStatusOK;
    NSMutableDictionary* attachments = $mdict();
    for (NSString* name in revAttachments) {
        // Create a TD_Attachment object:
        NSDictionary* attachInfo = revAttachments[name];
        NSString* contentType = $castIf(NSString, attachInfo[@"content_type"]);
        TD_Attachment* attachment =
            [[TD_Attachment alloc] initWithName:name contentType:contentType];

        NSString* newContentsBase64 = $castIf(NSString, attachInfo[@"data"]);
        if (newContentsBase64) {
            // If there's inline attachment data, decode and store it:
            @autoreleasepool
            {
                NSData* newContents = [TDBase64 decode:newContentsBase64];
                if (!newContents) {
                    status = kTDStatusBadEncoding;
                    break;
                }
                attachment->length = newContents.length;
                if (![self storeBlob:newContents
                         creatingKey:&attachment->blobKey
                        withDatabase:db]) {
                    status = kTDStatusAttachmentError;
                    break;
                }
            }
        } else if ([attachInfo[@"follows"] isEqual:$true]) {
            // "follows" means the uploader provided the attachment in a separate MIME part.
            // This means it's already been registered in _pendingAttachmentsByDigest;
            // I just need to look it up by its "digest" property and install it into the store:
            status = [self installAttachment:attachment withDatabase:db forInfo:attachInfo];
            if (TDStatusIsError(status)) break;
        } else {
            // This item is just a stub; skip it
            continue;
        }

        // Handle encoded attachment:
        NSString* encodingStr = attachInfo[@"encoding"];
        if (encodingStr) {
            if ($equal(encodingStr, @"gzip"))
                attachment->encoding = kTDAttachmentEncodingGZIP;
            else {
                status = kTDStatusBadEncoding;
                break;
            }

            attachment->encodedLength = attachment->length;
            attachment->length = $castIf(NSNumber, attachInfo[@"length"]).unsignedLongLongValue;
        }

        attachment->revpos = $castIf(NSNumber, attachInfo[@"revpos"]).unsignedIntValue;
        attachments[name] = attachment;
    }

    *outStatus = status;
    return status < 300 ? attachments : nil;
}

/**
 Creates and updates rows in the attachments table for the
 given list of attachments, generated for the revision using
 the -attachmentsFromRevision:status: method in this file.

 This is called when the rev has been saved to the revs table,
 as, of course, the seq number must be from the new rev.
 */
- (TDStatus)processAttachments:(NSDictionary*)attachments
                   forRevision:(TD_Revision*)rev
            withParentSequence:(SequenceNumber)parentSequence
                    inDatabase:(FMDatabase*)db
{
    Assert(rev);

    // If there are no attachments in the new rev, there's nothing to do:
    NSDictionary* revAttachments = rev[@"_attachments"];
    if (revAttachments.count == 0 || rev.deleted) return kTDStatusOK;

    SequenceNumber newSequence = rev.sequence;
    Assert(newSequence > 0);
    Assert(newSequence > parentSequence);
    unsigned generation = rev.generation;
    Assert(generation > 0, @"Missing generation in rev %@", rev);

    for (NSString* name in revAttachments) {
        TDStatus status;
        TD_Attachment* attachment = attachments[name];
        if (attachment) {
            // Determine the revpos, i.e. generation # this was added in. Usually this is
            // implicit, but a rev being pulled in replication will have it set already.
            if (attachment->revpos == 0)
                attachment->revpos = generation;
            else if (attachment->revpos > generation) {
                CDTLogWarn(CDTDATASTORE_LOG_CONTEXT,
                        @"Attachment %@ . '%@' has weird revpos %u; setting to %u", rev, name,
                        attachment->revpos, generation);
                attachment->revpos = generation;
            }

            // Finally insert the attachment:
            status = [self insertAttachment:attachment forSequence:newSequence inDatabase:db];
        } else {
            // It's just a stub, so copy the previous revision's attachment entry:
            //? Should I enforce that the type and digest (if any) match?
            status = [self copyAttachmentNamed:name
                                  fromSequence:parentSequence
                                    toSequence:newSequence
                                    inDatabase:db];
        }
        if (TDStatusIsError(status)) return status;
    }
    return kTDStatusOK;
}

- (TDMultipartWriter*)multipartWriterForRevision:(TD_Revision*)rev
                                     contentType:(NSString*)contentType
{
    TDMultipartWriter* writer =
        [[TDMultipartWriter alloc] initWithContentType:contentType boundary:nil];
    [writer setNextPartsHeaders:@{ @"Content-Type" : @"application/json" }];
    [writer addData:rev.asJSON];
    NSDictionary* attachments = rev[@"_attachments"];
    for (NSString* attachmentName in attachments) {
        NSDictionary* attachment = attachments[attachmentName];
        if (attachment[@"follows"]) {
            NSString* disposition =
                $sprintf(@"attachment; filename=%@", TDQuoteString(attachmentName));
            [writer setNextPartsHeaders:$dict({ @"Content-Disposition", disposition })];

            id<CDTBlobReader> blob = [self blobForAttachmentDict:attachment];
            UInt64 length = 0;
            NSInputStream* inputStream = [blob inputStreamWithOutputLength:&length];
            [writer addStream:inputStream length:length];
        }
    }
    return writer;
}

- (TD_Revision*)updateAttachment:(NSString*)filename
                            body:(TDBlobStoreWriter*)body
                            type:(NSString*)contentType
                        encoding:(TDAttachmentEncoding)encoding
                         ofDocID:(NSString*)docID
                           revID:(NSString*)oldRevID
                          status:(TDStatus*)outStatus
                      inDatabase:(FMDatabase*)db
{
    *outStatus = kTDStatusBadAttachment;
    if (filename.length == 0 || (body && !contentType) || (oldRevID && !docID) || (body && !docID))
        return nil;

    TD_Revision* oldRev = [[TD_Revision alloc] initWithDocID:docID revID:oldRevID deleted:NO];
    if (oldRevID) {
        // Load existing revision if this is a replacement:
        *outStatus = [self loadRevisionBody:oldRev options:0 database:db];
        if (TDStatusIsError(*outStatus)) {
            if (*outStatus == kTDStatusNotFound &&
                [self existsDocumentWithID:docID revisionID:nil database:db])
                *outStatus = kTDStatusConflict;  // if some other revision exists, it's a conflict
            return nil;
        }
    } else {
        // If this creates a new doc, it needs a body:
        oldRev.body = [TD_Body bodyWithProperties:@{}];
    }

    // Update the _attachments dictionary:
    NSMutableDictionary* attachments = [oldRev[@"_attachments"] mutableCopy];
    if (!attachments) attachments = $mdict();
    if (body) {
        TDBlobKey key = body.blobKey;
        NSString* digest =
            [@"sha1-" stringByAppendingString:[TDBase64 encode:&key length:sizeof(key)]];
        [self rememberAttachmentWriter:body forDigest:digest];
        NSString* encodingName = (encoding == kTDAttachmentEncodingGZIP) ? @"gzip" : nil;
        attachments[filename] =
            $dict({ @"digest", digest }, { @"length", @(body.length) }, { @"follows", $true },
                  { @"content_type", contentType }, { @"encoding", encodingName });
    } else {
        if (!attachments[filename]) {
            *outStatus = kTDStatusAttachmentNotFound;
            return nil;
        }
        [attachments removeObjectForKey:filename];
    }
    NSMutableDictionary* properties = [oldRev.properties mutableCopy];
    properties[@"_attachments"] = attachments;
    oldRev.properties = properties;

    // Store a new revision with the updated _attachments:
    TD_Revision* newRev =
        [self putRevision:oldRev prevRevisionID:oldRevID allowConflict:NO status:outStatus];
    if (!body && *outStatus == kTDStatusCreated) *outStatus = kTDStatusOK;
    return newRev;
}

/**
 * db argument must be from inside _fmdbQueue inDatabase
 */
- (TDStatus)garbageCollectAttachments:(FMDatabase*)db
{
    // First delete attachment rows for already-cleared revisions:
    // OPT: Could start after last sequence# we GC'd up to

    [db executeUpdate:@"DELETE FROM attachments WHERE sequence IN "
                       "(SELECT sequence from revs WHERE json IS null)"];

    // Now collect all remaining attachment IDs and tell the store to delete all but these:
    FMResultSet* r = [db executeQuery:@"SELECT DISTINCT key FROM attachments"];
    if (!r) {
        return kTDStatusDBError;
    }
    NSMutableSet* allKeys = [NSMutableSet set];
    while ([r next]) {
        [allKeys addObject:[r dataForColumnIndex:0]];
    }
    [r close];
    BOOL blobDeleted = [_attachments deleteBlobsExceptWithKeys:allKeys withDatabase:db];
    if (!blobDeleted) {
        return kTDStatusAttachmentError;
    }
    CDTLogInfo(CDTDATASTORE_LOG_CONTEXT, @"Unneeded attachment blobs deleted");
    return kTDStatusOK;
}

@end
