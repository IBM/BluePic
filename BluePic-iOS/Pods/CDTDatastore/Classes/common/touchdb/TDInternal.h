//
//  TDInternal.h
//  TouchDB
//
//  Created by Jens Alfke on 12/8/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//
//  Modifications for this distribution by Cloudant, Inc., Copyright (c) 2014 Cloudant, Inc.
//

#import "TD_Database.h"
#import "TD_Database+Attachments.h"
#import "TD_DatabaseManager.h"
#import "TD_View.h"
#import "TDReplicator.h"
#import "TDRemoteRequest.h"
#import "TDBlobStore.h"

@class TD_Attachment;

@interface TD_Database ()

@property (readwrite, copy) NSString* name;  // make it settable

- (BOOL)openFMDBWithEncryptionKeyProvider:(id<CDTEncryptionKeyProvider>)provider;

/** Must be called from within a queue -inDatabase: or -inTransaction: **/
- (SInt64)getDocNumericID:(NSString*)docID database:(FMDatabase*)db;

/** Must be called from within a queue -inDatabase: or -inTransaction: **/
- (SequenceNumber)getSequenceOfDocument:(SInt64)docNumericID
                               revision:(NSString*)revID
                            onlyCurrent:(BOOL)onlyCurrent
                               database:(FMDatabase*)database;

/** Must be called from within a queue -inDatabase: or -inTransaction: **/
- (TD_RevisionList*)getAllRevisionsOfDocumentID:(NSString*)docID
                                      numericID:(SInt64)docNumericID
                                    onlyCurrent:(BOOL)onlyCurrent
                                 excludeDeleted:(BOOL)excludeDeleted
                                       database:(FMDatabase*)database;

/** Must be called from within a queue -inDatabase: or -inTransaction: **/
- (TD_Revision*)getDocumentWithID:(NSString*)docID
                       revisionID:(NSString*)revID
                          options:(TDContentOptions)options
                           status:(TDStatus*)outStatus
                         database:(FMDatabase*)database;

/** Must be called from within a queue -inDatabase: or -inTransaction: **/
- (TDStatus)deleteViewNamed:(NSString*)name;

- (NSMutableDictionary*)documentPropertiesFromJSON:(NSData*)json
                                             docID:(NSString*)docID
                                             revID:(NSString*)revID
                                           deleted:(BOOL)deleted
                                          sequence:(SequenceNumber)sequence
                                           options:(TDContentOptions)options
                                        inDatabase:(FMDatabase*)db;

/** Must be called from within a queue -inDatabase: or -inTransaction: **/
- (NSString*)winningRevIDOfDocNumericID:(SInt64)docNumericID
                              isDeleted:(BOOL*)outIsDeleted
                               database:(FMDatabase*)database;
@end

@interface TD_Database (Insertion_Internal)
- (NSData*)encodeDocumentJSON:(TD_Revision*)rev;
- (TDStatus)validateRevision:(TD_Revision*)newRev previousRevision:(TD_Revision*)oldRev;
@end

@interface TD_Database (Attachments_Internal)
- (void)rememberAttachmentWritersForDigests:(NSDictionary*)writersByDigests;
#if DEBUG
- (id)attachmentWriterForAttachment:(NSDictionary*)attachment;
#endif

- (NSUInteger)blobCount;
- (id<CDTBlobReader>)blobForKey:(TDBlobKey)key;
- (id<CDTBlobReader>)blobForKey:(TDBlobKey)key withDatabase:(FMDatabase *)db;
- (BOOL)storeBlob:(NSData *)blob creatingKey:(TDBlobKey *)outKey;
- (BOOL)storeBlob:(NSData *)blob creatingKey:(TDBlobKey *)outKey withDatabase:(FMDatabase *)db;
- (BOOL)storeBlob:(NSData *)blob
      creatingKey:(TDBlobKey *)outKey
            error:(NSError *__autoreleasing *)outError;
- (BOOL)storeBlob:(NSData *)blob
      creatingKey:(TDBlobKey *)outKey
     withDatabase:(FMDatabase *)db
            error:(NSError *__autoreleasing *)outError;

- (TDStatus)insertAttachment:(TD_Attachment*)attachment
                 forSequence:(SequenceNumber)sequence
                  inDatabase:(FMDatabase*)db;
- (TDStatus)copyAttachmentNamed:(NSString*)name
                   fromSequence:(SequenceNumber)fromSequence
                     toSequence:(SequenceNumber)toSequence
                     inDatabase:(FMDatabase*)db;
- (TDStatus)copyAttachmentsFromSequence:(SequenceNumber)fromSequence
                             toSequence:(SequenceNumber)toSequence
                             inDatabase:(FMDatabase*)db;
- (BOOL)inlineFollowingAttachmentsIn:(TD_Revision*)rev error:(NSError**)outError;
@end

@interface TD_Database (Replication_Internal)
- (void)stopAndForgetReplicator:(TDReplicator*)repl;
- (NSObject*)lastSequenceWithCheckpointID:(NSString*)checkpointID;
- (void)setLastSequence:(NSObject*)lastSequence withCheckpointID:(NSString*)checkpointID;
+ (NSString*)joinQuotedStrings:(NSArray*)strings;
@end

@interface TD_View ()
- (id)initWithDatabase:(TD_Database*)db name:(NSString*)name;
@property (readonly) int viewID;
- (NSArray*)dump;
- (void)databaseClosing;
@end

@interface TD_DatabaseManager ()
#if DEBUG
+ (TD_DatabaseManager*)createEmptyAtPath:(NSString*)path;           // for testing
+ (TD_DatabaseManager*)createEmptyAtTemporaryPath:(NSString*)name;  // for testing
#endif
@end

@interface TDReplicator ()
// protected:
@property (copy) NSObject* lastSequence;
@property (readwrite, nonatomic) NSUInteger changesProcessed, changesTotal;
- (void)maybeCreateRemoteDB;
- (void)beginReplicating;
- (void)addToInbox:(TD_Revision*)rev;
- (void)addRevsToInbox:(TD_RevisionList*)revs;
- (void)processInbox:(TD_RevisionList*)inbox;  // override this
- (TDRemoteJSONRequest*)sendAsyncRequest:(NSString*)method
                                    path:(NSString*)relativePath
                                    body:(id)body
                            onCompletion:(TDRemoteRequestCompletionBlock)onCompletion;
- (void)addRemoteRequest:(TDRemoteRequest*)request;
- (void)removeRemoteRequest:(TDRemoteRequest*)request;
- (void)asyncTaskStarted;
- (void)asyncTasksFinished:(NSUInteger)numTasks;
- (void)stopped;
- (void)databaseClosing;
- (void)revisionFailed;  // subclasses call this if a transfer fails
- (void)retry;

- (void)reachabilityChanged:(TDReachability*)reachability;
- (BOOL)goOffline;
- (BOOL)goOnline;
#if DEBUG
@property (readonly) BOOL savingCheckpoint;
#endif
@end
