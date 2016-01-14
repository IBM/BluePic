//
//  CDTDatastore.m
//  CloudantSync
//
//  Created by Michael Rhodes on 02/07/2013.
//  Copyright (c) 2013 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "CDTDatastore.h"
#import "CDTDocumentRevision.h"
#import "CDTDatastoreManager.h"
#import "CDTAttachment.h"
#import "CDTDatastore+Attachments.h"
#import "CDTEncryptionKeyNilProvider.h"
#import "CDTLogging.h"

#import "TD_Database.h"
#import "TD_View.h"
#import "TD_Body.h"
#import "TD_Database+Insertion.h"
#import "TDInternal.h"
#import "TDMisc.h"

#import <FMDB/FMDatabase.h>
#import <FMDB/FMDatabaseAdditions.h>
#import <FMDB/FMDatabaseQueue.h>

#import "Version.h"

NSString *const CDTDatastoreChangeNotification = @"CDTDatastoreChangeNotification";

@interface CDTDatastore ()

@property (nonatomic, strong, readonly) id<CDTEncryptionKeyProvider> keyProvider;

@property (readonly) CDTDatastoreManager *manager;
- (void)TDdbChanged:(NSNotification *)n;
- (BOOL)validateBodyDictionary:(NSDictionary *)body error:(NSError *__autoreleasing *)error;

@end

@implementation CDTDatastore

@synthesize database = _database;

+ (NSString *)versionString { return @CLOUDANT_SYNC_VERSION; }

- (instancetype)initWithManager:(CDTDatastoreManager *)manager database:(TD_Database *)database
{
    CDTEncryptionKeyNilProvider *provider = [CDTEncryptionKeyNilProvider provider];

    return [self initWithManager:manager database:database encryptionKeyProvider:provider];
}

// Public init method defined in CDTDatastore+EncryptionKey.h
- (instancetype)initWithManager:(CDTDatastoreManager *)manager
					   database:(TD_Database *)database
          encryptionKeyProvider:(id<CDTEncryptionKeyProvider>)provider
{
    NSParameterAssert(manager);
    Assert(provider, @"Key provider is mandatory. Supply a CDTNilEncryptionKeyProvider instead.");

    self = [super init];
    if (self) {
        if (![database openWithEncryptionKeyProvider:provider]) {
            self = nil;
        } else {
            _manager = manager;
            _database = database;
            _keyProvider = provider;

            NSString *dir = [[database path] stringByDeletingLastPathComponent];
            NSString *name = [database name];
            _extensionsDir = [dir
                stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_extensions", name]];

            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(TDdbChanged:)
                                                         name:TD_DatabaseChangeNotification
                                                       object:database];
        }
    }

    return self;
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }

#pragma mark Properties

- (TD_Database *)database
{
    if (![self ensureDatabaseOpen]) {
        return nil;
    }
    return _database;
}

#pragma mark Observer methods

/*
 * Notified that a document has been created/modified/deleted in the
 * database we're wrapping. Wrap it up into a notification containing
 * CDT* classes and re-notify.
 *
 * All this wrapping is to prevent TD* types escaping.
 */
- (void)TDdbChanged:(NSNotification *)n
{
    // Notification structure:

    /** NSNotification posted when a document is updated.
     UserInfo keys:
     - @"rev": the new TD_Revision,
     - @"source": NSURL of remote db pulled from,
     - @"winner": new winning TD_Revision, _if_ it changed (often same as rev).
     */

    //    LogTo(CDTReplicatorLog, @"CDTReplicator: dbChanged");

    NSDictionary *nUserInfo = n.userInfo;
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];

    if (nil != nUserInfo[@"rev"]) {
        TD_Revision *tdRev = nUserInfo[@"rev"];
        userInfo[@"rev"] = [[CDTDocumentRevision alloc] initWithDocId:tdRev.docID
                                                           revisionId:tdRev.revID
                                                                 body:tdRev.body.properties
                                                              deleted:tdRev.deleted
                                                          attachments:@{}
                                                             sequence:tdRev.sequence];
    }

    if (nil != nUserInfo[@"winner"]) {
        TD_Revision *tdRev = nUserInfo[@"rev"];
        userInfo[@"winner"] = [[CDTDocumentRevision alloc] initWithDocId:tdRev.docID
                                                              revisionId:tdRev.revID
                                                                    body:tdRev.body.properties
                                                                 deleted:tdRev.deleted
                                                             attachments:@{}
                                                                sequence:tdRev.sequence];
    }

    if (nil != nUserInfo[@"source"]) {
        userInfo[@"source"] = nUserInfo[@"source"];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:CDTDatastoreChangeNotification
                                                        object:self
                                                      userInfo:userInfo];
}

#pragma mark Datastore implementation

- (NSUInteger)documentCount
{
    if (![self ensureDatabaseOpen]) {
        return -1;
    }
    return self.database.documentCount;
}

- (NSString *)name { return self.database.name; }

// Public method defined in CDTDatastore+EncryptionKey.h
- (id<CDTEncryptionKeyProvider>)encryptionKeyProvider { return self.keyProvider; }

- (CDTDocumentRevision *)getDocumentWithId:(NSString *)docId error:(NSError *__autoreleasing *)error
{
    return [self getDocumentWithId:docId rev:nil error:error];
}

- (CDTDocumentRevision *)getDocumentWithId:(NSString *)docId
                                       rev:(NSString *)revId
                                     error:(NSError *__autoreleasing *)error
{
    if (![self ensureDatabaseOpen]) {
        *error = TDStatusToNSError(kTDStatusException, nil);
        return nil;
    }

    TDStatus status;
    TD_Revision *rev =
        [self.database getDocumentWithID:docId revisionID:revId options:0 status:&status];
    if (TDStatusIsError(status)) {
        if (error) {
            *error = TDStatusToNSError(status, nil);
        }
        return nil;
    }

    CDTDocumentRevision *revision = [[CDTDocumentRevision alloc] initWithDocId:rev.docID
                                                                    revisionId:rev.revID
                                                                          body:rev.body.properties
                                                                       deleted:rev.deleted
                                                                   attachments:@{}
                                                                      sequence:rev.sequence];
    NSArray *attachments = [self attachmentsForRev:revision error:error];

    NSMutableDictionary *attachmentsDict = [NSMutableDictionary dictionary];

    for (CDTAttachment *attachment in attachments) {
        [attachmentsDict setObject:attachment forKey:attachment.name];
    }

    revision = [[CDTDocumentRevision alloc] initWithDocId:rev.docID
                                               revisionId:rev.revID
                                                     body:rev.body.properties
                                                  deleted:rev.deleted
                                              attachments:attachmentsDict
                                                 sequence:rev.sequence];

    return revision;
}

- (NSArray *)getAllDocuments
{
    NSError *error;
    if (![self ensureDatabaseOpen]) {
        return nil;
    }

    NSArray *result = [NSArray array];
    TDContentOptions contentOptions = kTDIncludeLocalSeq;
    struct TDQueryOptions query = {.limit = UINT_MAX,
                                   .inclusiveEnd = YES,
                                   .skip = 0,
                                   .descending = NO,
                                   .includeDocs = YES,
                                   .content = contentOptions};

    // This method must loop to get around the fact that conflicted documents
    // contribute more than one row in the query -getDocsWithIDs:options: uses,
    // so in the face of conflicted documents, the initial query above will
    // only return the winning revisions of a subset of the documents.
    BOOL done = NO;
    do {
        NSMutableArray *batch = [NSMutableArray array];

        NSDictionary *dictResults = [self.database getDocsWithIDs:nil options:&query];

        for (NSDictionary *row in dictResults[@"rows"]) {
            NSString *docId = row[@"id"];
            NSString *revId = row[@"value"][@"rev"];

            TD_Revision *revision =
                [[TD_Revision alloc] initWithDocID:docId revID:revId deleted:NO];
            revision.body = [[TD_Body alloc] initWithProperties:row[@"doc"]];
            revision.sequence = [row[@"doc"][@"_local_seq"] longLongValue];

            CDTDocumentRevision *ob =
                [[CDTDocumentRevision alloc] initWithDocId:revision.docID
                                                revisionId:revision.revID
                                                      body:revision.body.properties
                                                   deleted:revision.deleted
                                               attachments:@{}
                                                  sequence:revision.sequence];

            NSArray *attachments = [self attachmentsForRev:ob error:&error];
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            for (CDTAttachment *attachment in attachments) {
                [dict setObject:attachment forKey:attachment.name];
            }
            [batch addObject:[[CDTDocumentRevision alloc] initWithDocId:revision.docID
                                                             revisionId:revision.revID
                                                                   body:revision.body.properties
                                                                deleted:revision.deleted
                                                            attachments:dict
                                                               sequence:revision.sequence]];
        }

        result = [result arrayByAddingObjectsFromArray:batch];

        done = ((NSArray *)dictResults[@"rows"]).count == 0;

        query.skip = query.skip + query.limit;

    } while (!done);

    return result;
}

- (NSArray *)getAllDocumentIds
{
    if (![self ensureDatabaseOpen]) {
        return nil;
    }

    NSMutableArray *result = [NSMutableArray array];
    struct TDQueryOptions query = {.limit = UINT_MAX,
                                   .inclusiveEnd = YES,
                                   .skip = 0,
                                   .descending = NO,
                                   .includeDocs = NO};

    NSDictionary *dictResults;
    do {
        dictResults = [self.database getDocsWithIDs:nil options:&query];
        for (NSDictionary *row in dictResults[@"rows"]) {
            [result addObject:row[@"id"]];
        }

        query.skip = query.skip + query.limit;
    } while (((NSArray *)dictResults[@"rows"]).count > 0);

    return [NSArray arrayWithArray:result];

}

- (NSArray *)getAllDocumentsOffset:(NSUInteger)offset
                             limit:(NSUInteger)limit
                        descending:(BOOL)descending
{
    struct TDQueryOptions query = {.limit = (unsigned)limit,
                                   .inclusiveEnd = YES,
                                   .skip = (unsigned)offset,
                                   .descending = descending,
                                   .includeDocs = YES};
    return [self allDocsQuery:nil options:&query];
}

- (NSArray *)getDocumentsWithIds:(NSArray *)docIds
{
    TDContentOptions contentOptions = kTDIncludeLocalSeq;
    struct TDQueryOptions query = {
        .limit = UINT_MAX, .inclusiveEnd = YES, .includeDocs = YES, .content = contentOptions};
    return [self allDocsQuery:docIds options:&query];
}

/* docIds can be null for getting all documents */
- (NSArray *)allDocsQuery:(NSArray *)docIds options:(TDQueryOptions *)queryOptions
{
    NSError *error;
    if (![self ensureDatabaseOpen]) {
        return nil;
    }

    NSMutableArray *result = [NSMutableArray array];

    NSDictionary *dictResults = [self.database getDocsWithIDs:docIds options:queryOptions];

    for (NSDictionary *row in dictResults[@"rows"]) {
        NSString *docId = row[@"id"];

        NSString *revId = row[@"value"][@"rev"];
        
        // If a document isn't found, docId and revId will be null, and row will
        // contain an @"error" key.
        if (docId == nil && revId == nil && [row[@"error"] isEqualToString:@"not_found"]) {
            continue;
        }

        // deleted field only present in deleted documents, but to be safe we use
        // the fact that (BOOL)[nil -boolValue] is false
        BOOL deleted = (BOOL)[row[@"value"][@"deleted"] boolValue];

        TD_Revision *revision =
            [[TD_Revision alloc] initWithDocID:docId revID:revId deleted:deleted];
        revision.sequence = [row[@"doc"][@"_local_seq"] longLongValue];

        // Deleted documents won't have a `doc` field
        if (!deleted) {
            revision.body = [[TD_Body alloc] initWithProperties:row[@"doc"]];
        }

        CDTDocumentRevision *ob =
            [[CDTDocumentRevision alloc] initWithDocId:revision.docID
                                            revisionId:revision.revID
                                                  body:revision.body.properties
                                               deleted:revision.deleted
                                           attachments:@{}
                                              sequence:revision.sequence];
        NSArray *attachments = [self attachmentsForRev:ob error:&error];
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for (CDTAttachment *attachment in attachments) {
            [dict setObject:attachment forKey:attachment.name];
        }
        [result addObject:[[CDTDocumentRevision alloc] initWithDocId:revision.docID
                                                          revisionId:revision.revID
                                                                body:revision.body.properties
                                                             deleted:revision.deleted
                                                         attachments:dict
                                                            sequence:revision.sequence]];
    }

    return result;
}

- (NSArray *)getRevisionHistory:(CDTDocumentRevision *)revision
{
    if (![self ensureDatabaseOpen]) {
        return nil;
    }

    NSMutableArray *result = [NSMutableArray array];

    // Array of TD_Revision
    TD_Revision *converted = [[TD_Revision alloc] initWithDocID:revision.docId
                                                          revID:revision.revId
                                                        deleted:revision.deleted];

    NSArray *td_revs = [self.database getRevisionHistory:converted];

    for (TD_Revision *td_rev in td_revs) {
        CDTDocumentRevision *ob = [[CDTDocumentRevision alloc] initWithDocId:td_rev.docID
                                                                  revisionId:td_rev.revID
                                                                        body:@{}
                                                                     deleted:td_rev.deleted
                                                                 attachments:@{}
                                                                    sequence:td_rev.sequence];
        [result addObject:ob];
    }

    return result;
}
- (BOOL)validateBodyDictionary:(NSDictionary *)body error:(NSError *__autoreleasing *)error
{


    //Firstly check if the document body is valid json
    if(![NSJSONSerialization isValidJSONObject:body]){
        //body isn't valid json, set error
        if (error){
            *error = TDStatusToNSError(kTDStatusBadJSON, nil);
        }

        return NO;
    }

    // Check user hasn't provided _fields, which should be provided
    // as metadata in the CDTDocumentRevision object rather than
    // via _fields in the body dictionary.
    for (NSString *key in [body keyEnumerator]) {
        if ([key hasPrefix:@"_"]) {
            if (error) {
                NSInteger code = 400;
                NSString *reason = @"Bodies may not contain _ prefixed fields. "
                                    "Use CDTDocumentRevision properties.";
                NSString *description = [NSString stringWithFormat:@"%li %@", (long)code, reason];
                NSDictionary *userInfo = @{
                    NSLocalizedFailureReasonErrorKey : reason,
                    NSLocalizedDescriptionKey : description
                };
                *error = [NSError errorWithDomain:TDHTTPErrorDomain code:code userInfo:userInfo];
            }

            return NO;
        }
    }

    return YES;
}

- (NSString *)extensionDataFolder:(NSString *)extensionName
{
    return [NSString pathWithComponents:@[ _extensionsDir, extensionName ]];
}

#pragma mark Helper methods

- (BOOL)ensureDatabaseOpen
{
    return [_database openWithEncryptionKeyProvider:self.keyProvider];
}

#pragma mark fromRevision API methods

- (CDTDocumentRevision *)createDocumentFromRevision:(CDTDocumentRevision *)revision
                                              error:(NSError *__autoreleasing *)error
{
    // first lets check to see if we can save the document
    if (!revision.body) {
        TDStatus status = kTDStatusBadRequest;
        *error = TDStatusToNSError(status, nil);
        return nil;
    }

    if (![self validateBodyDictionary:revision.body error:error]) {
        return nil;
    }

    if (![self ensureDatabaseOpen]) {
        *error = TDStatusToNSError(kTDStatusException, nil);
        return nil;
    }

    // convert CDTMutableDocument to TD_Revision

    // we know it shouldn't have a TD_revision behind it, since its a create

    TD_Revision *converted =
        [[TD_Revision alloc] initWithDocID:revision.docId revID:nil deleted:false];
    converted.body = [[TD_Body alloc] initWithProperties:revision.body];

    // dowload attachments to the blob store
    NSMutableArray *downloadedAttachments = [NSMutableArray array];
    NSMutableArray *attachmentsToCopy = [NSMutableArray array];
    if (revision.attachments) {
        for (NSString *key in revision.attachments) {
            CDTAttachment *attachment = [revision.attachments objectForKey:key];
            // check if thae attachment has been saved to blobstore, if not save it
            if (![attachment isKindOfClass:[CDTSavedAttachment class]]) {
                NSDictionary *attachmentData =
                    [self streamAttachmentToBlobStore:attachment error:error];
                if (attachmentData != nil) {
                    [downloadedAttachments addObject:attachmentData];
                } else {  // Error downloading the attachment, bail
                    // error out variable set by -stream...
                    CDTLogWarn(CDTDATASTORE_LOG_CONTEXT,
                            @"Error reading %@ from stream for doc <%@, %@>, rolling back",
                            attachment.name, converted.docID, converted.revID);
                    return nil;
                }
            } else {
                [attachmentsToCopy addObject:attachment];
            }
        }
    }

    // create the document revision with the attachments

    __block CDTDocumentRevision *saved;
    __weak CDTDatastore *datastore = self;

    [self.database.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {

        TDStatus status;
        TD_Revision *new = [datastore.database putRevision : converted prevRevisionID
                            : nil allowConflict : NO status : &status database : db];

        if (TDStatusIsError(status)) {
            *error = TDStatusToNSError(status, nil);
            *rollback = YES;
            saved = nil;
            return;
        } else {
            saved = [[CDTDocumentRevision alloc] initWithDocId:new.docID
                                                    revisionId:new.revID
                                                          body:new.body.properties
                                                       deleted:new.deleted
                                                   attachments:@{}
                                                      sequence:new.sequence];
            for (NSDictionary *attachment in downloadedAttachments) {
                // insert each attchment into the database, if this fails rollback
                if (![datastore addAttachment:attachment toRev:saved inDatabase:db]) {
                    // failed need to rollback
                    saved = nil;
                    *rollback = YES;
                    return;
                }
            }
            // copy saved attachments
            for (CDTSavedAttachment *attachment in attachmentsToCopy) {
                TDStatus status = [self.database copyAttachmentNamed:attachment.name
                                                        fromSequence:attachment.sequence
                                                          toSequence:new.sequence
                                                          inDatabase:db];
                if (TDStatusIsError(status)) {
                    *error = TDStatusToNSError(status, nil);
                    *rollback = YES;
                    saved = nil;
                    return;
                }
            }

            saved = [[CDTDocumentRevision alloc] initWithDocId:new.docID
                                                    revisionId:new.revID
                                                          body:new.body.properties
                                                       deleted:new.deleted
                                                   attachments:@{}
                                                      sequence:new.sequence];
        }
    }];

    if (saved) {
        NSArray *attachmentsFromBlobStore = [self attachmentsForRev:saved error:error];
        NSMutableDictionary *attachmentDict = [NSMutableDictionary dictionary];

        for (CDTAttachment *attachment in attachmentsFromBlobStore) {
            [attachmentDict setObject:attachment forKey:attachment.name];
        }

        saved = [[CDTDocumentRevision alloc] initWithDocId:saved.docId
                                                revisionId:saved.revId
                                                      body:saved.body
                                                   deleted:saved.deleted
                                               attachments:attachmentDict
                                                  sequence:saved.sequence];

        NSDictionary *userInfo = @{ @"rev" : saved, @"winner" : saved };
        [[NSNotificationCenter defaultCenter] postNotificationName:CDTDatastoreChangeNotification
                                                            object:self
                                                          userInfo:userInfo];
    }
    return saved;
}

- (CDTDocumentRevision *)updateDocumentFromRevision:(CDTDocumentRevision *)revision
                                              error:(NSError *__autoreleasing *)error
{
    if (!revision.isFullRevision) {
        if (error) {
            NSString *reason = @"Trying to save revision where isFullVersion is NO";
            NSString *msg = @"Possibly trying to save projected query result.";
            NSString *recovery = @"Try calling -copy on projected revisions before saving.";
            NSDictionary *info = @{
                NSLocalizedFailureReasonErrorKey : reason,
                NSLocalizedDescriptionKey : msg,
                NSLocalizedRecoverySuggestionErrorKey : recovery
            };
            *error =
                [NSError errorWithDomain:TDHTTPErrorDomain code:kTDStatusBadRequest userInfo:info];
        }
        return nil;
    }

    if (!revision.body) {
        TDStatus status = kTDStatusBadRequest;
        if (error) {
            *error = TDStatusToNSError(status, nil);
        }
        return nil;
    }

    if (![self validateBodyDictionary:revision.body error:error]) {
        return nil;
    }

    if (![self ensureDatabaseOpen]) {
        *error = TDStatusToNSError(kTDStatusException, nil);
        return nil;
    }

    TD_Revision *converted = [[TD_Revision alloc] initWithDocID:revision.docId
                                                          revID:revision.revId
                                                        deleted:revision.deleted];
    converted.body = [[TD_Body alloc] initWithProperties:revision.body];

    NSMutableArray *downloadedAttachments = [[NSMutableArray alloc] init];
    NSMutableArray *attachmentToCopy = [[NSMutableArray alloc] init];
    if (revision.attachments) {
        for (NSString *key in revision.attachments) {
            CDTAttachment *attachment = [revision.attachments objectForKey:key];
            // if the attachment is not saved, save it to the blob store
            // otherwise add it to the array to copy it to the new revision
            if (![attachment isKindOfClass:[CDTSavedAttachment class]]) {
                NSDictionary *attachmentData =
                    [self streamAttachmentToBlobStore:attachment error:error];
                if (attachmentData != nil) {
                    [downloadedAttachments addObject:attachmentData];
                } else {  // Error downloading the attachment, bail
                    // error out variable set by -stream...
                    CDTLogWarn(CDTDATASTORE_LOG_CONTEXT,
                            @"Error reading %@ from stream for doc <%@, %@>, rolling back",
                            attachment.name, converted.docID, converted.revID);
                    return nil;
                }
            } else {
                [attachmentToCopy addObject:attachment];
            }
        }
    }

    __block CDTDocumentRevision *result;
    __weak CDTDatastore *datastore = self;

    [self.database.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        result = [datastore updateDocumentFromTDRevision:converted
                                                   docId:revision.docId
                                                 prevRev:revision.revId
                                           inTransaction:db
                                                rollback:rollback
                                                   error:error];

        if (result) {
            for (NSDictionary *attachment in downloadedAttachments) {
                // insert each attchment into the database, if this fails rollback
                if (![datastore addAttachment:attachment toRev:result inDatabase:db]) {
                    // failed need to rollback
                    result = nil;
                    *rollback = YES;
                }
            }
            for (CDTSavedAttachment *attachment in attachmentToCopy) {
                TDStatus status = [self.database copyAttachmentNamed:attachment.name
                                                        fromSequence:attachment.sequence
                                                          toSequence:result.sequence
                                                          inDatabase:db];
                if (TDStatusIsError(status)) {
                    *error = TDStatusToNSError(status, nil);
                    *rollback = YES;
                    result = nil;
                }
            }
        }
    }];

    if (result) {
        // populate the attachment array with attachments
        NSArray *attachmentsFromBlobStore = [self attachmentsForRev:result error:error];
        NSMutableDictionary *attachmentDict = [NSMutableDictionary dictionary];

        for (CDTAttachment *attachment in attachmentsFromBlobStore) {
            [attachmentDict setObject:attachment forKey:attachment.name];
        }

        result = [[CDTDocumentRevision alloc] initWithDocId:result.docId
                                                 revisionId:result.revId
                                                       body:result.body
                                                    deleted:result.deleted
                                                attachments:attachmentDict
                                                   sequence:result.sequence];

        NSDictionary *userInfo = $dict({ @"rev", result }, { @"winner", result });
        [[NSNotificationCenter defaultCenter] postNotificationName:CDTDatastoreChangeNotification
                                                            object:self
                                                          userInfo:userInfo];
    }

    return result;
}

- (CDTDocumentRevision *)updateDocumentFromTDRevision:(TD_Revision *)td_rev
                                                docId:(NSString *)docId
                                              prevRev:(NSString *)prevRev
                                        inTransaction:(FMDatabase *)db
                                             rollback:(BOOL *)rollback
                                                error:(NSError *__autoreleasing *)error
{
    if (![self ensureDatabaseOpen]) {
        *error = TDStatusToNSError(kTDStatusException, nil);
        return nil;
    }

    TD_Revision *revision = [[TD_Revision alloc] initWithDocID:docId revID:nil deleted:NO];
    revision.body = td_rev.body;

    TDStatus status;
    TD_Revision *new = [self.database putRevision : revision prevRevisionID : prevRev allowConflict
                        : NO status : &status database : db];
    if (TDStatusIsError(status)) {
        *error = TDStatusToNSError(status, nil);
        *rollback = YES;
        return nil;
    }

    return [[CDTDocumentRevision alloc] initWithDocId:new.docID
                                           revisionId:new.revID
                                                 body:new.body.properties
                                              deleted:new.deleted
                                          attachments:@{}
                                             sequence:new.sequence];
}

- (CDTDocumentRevision *)deleteDocumentFromRevision:(CDTDocumentRevision *)revision
                                              error:(NSError *__autoreleasing *)error
{
    if (![self ensureDatabaseOpen]) {
        *error = TDStatusToNSError(kTDStatusException, nil);
        return nil;
    }

    // A mutable document revision stores the revId in other property
    NSString *prevRevisionID = revision.revId;

    TD_Revision *td_revision =
        [[TD_Revision alloc] initWithDocID:revision.docId revID:nil deleted:YES];
    TDStatus status;
    TD_Revision *new = [self.database putRevision:td_revision
                                   prevRevisionID:prevRevisionID
                                    allowConflict:NO
                                           status:&status];
    if (TDStatusIsError(status)) {
        if (error) {
            *error = TDStatusToNSError(status, nil);
        }
        return nil;
    }

    return [[CDTDocumentRevision alloc] initWithDocId:new.docID
                                           revisionId:new.revID
                                                 body:new.body.properties
                                              deleted:new.deleted
                                          attachments:@{}
                                             sequence:new.sequence];
}

- (NSArray *)deleteDocumentWithId:(NSString *)docId error:(NSError *__autoreleasing *)error
{
    __weak CDTDatastore *weakself = self;
    __block NSMutableArray *deletedDocs = [NSMutableArray array];

    [self.database.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {

        FMResultSet *result = [db executeQueryWithFormat:@"SELECT revs.revid FROM docs,revs WHERE \
        revs.doc_id = docs.doc_id AND docs.docid = %@ AND deleted = 0 AND revs.sequence \
        NOT IN (SELECT DISTINCT parent FROM revs WHERE parent NOT NULL)",
                                                         docId];

        while ([result next]) {
            NSString *revId = [result stringForColumn:@"revid"];
            CDTDocumentRevision *deleted;

            TD_Revision *td_revision =
                [[TD_Revision alloc] initWithDocID:docId revID:nil deleted:YES];
            TDStatus status;
            TD_Revision *new = [weakself.database putRevision : td_revision prevRevisionID
                                : revId allowConflict : NO status : &status database : db];

            if (TDStatusIsError(status)) {
                *error = TDStatusToNSError(status, nil);
                *rollback = YES;
                deletedDocs = nil;
                return;
            }
            deleted = [[CDTDocumentRevision alloc] initWithDocId:new.docID
                                                      revisionId:new.revID
                                                            body:new.body.properties
                                                         deleted:new.deleted
                                                     attachments:@{}
                                                        sequence:new.sequence];
            [deletedDocs addObject:deleted];
        }
    }];

    if (deletedDocs) {
        NSDictionary *userInfo = $dict({ @"deletedRevs", deletedDocs });
        [[NSNotificationCenter defaultCenter] postNotificationName:CDTDatastoreChangeNotification
                                                            object:self
                                                          userInfo:userInfo];
    }

    return [deletedDocs copy];
}

- (BOOL)compactWithError:(NSError *__autoreleasing *)error
{
    TDStatus status = [self.database compact];

    if (TDStatusIsError(status)) {
        if(error){
            *error = TDStatusToNSError(status, nil);
        }
        return NO;
    }

    return YES;
}

@end
