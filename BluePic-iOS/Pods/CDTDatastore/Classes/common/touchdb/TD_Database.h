/*
 *  TD_Database.h
 *  TouchDB
 *
 *  Created by Jens Alfke on 6/19/10.
 *  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
 *
 *  Modifications for this distribution by Cloudant, Inc., Copyright (c) 2014 Cloudant, Inc.
 *
 */

#import "TD_Revision.h"
#import "TDStatus.h"
#import "TDMisc.h"

@protocol CDTEncryptionKeyProvider;

@class FMDatabase, FMDatabaseQueue, TD_View, TDBlobStore;

struct TDQueryOptions;  // declared in TD_View.h

/** NSNotification posted when a document is updated.
    UserInfo keys: @"rev": the new TD_Revision, @"source": NSURL of remote db pulled from,
    @"winner": new winning TD_Revision, _if_ it changed (often same as rev). */
extern NSString* const TD_DatabaseChangeNotification;

/** NSNotification posted when a database is closing. */
extern NSString* const TD_DatabaseWillCloseNotification;

/** NSNotification posted when a database is about to be deleted (but before it closes). */
extern NSString* const TD_DatabaseWillBeDeletedNotification;

/** Options for what metadata to include in document bodies */
typedef unsigned TDContentOptions;
enum {
    kTDIncludeAttachments = 1,        // adds inline bodies of attachments
    kTDIncludeConflicts = 2,          // adds '_conflicts' property (if relevant)
    kTDIncludeRevs = 4,               // adds '_revisions' property
    kTDIncludeRevsInfo = 8,           // adds '_revs_info' property
    kTDIncludeLocalSeq = 16,          // adds '_local_seq' property
    kTDLeaveAttachmentsEncoded = 32,  // i.e. don't decode
    kTDBigAttachmentsFollow = 64,     // i.e. add 'follows' key instead of data for big ones
    kTDNoBody = 128,                  // omit regular doc body properties
};

/** Options for _changes feed (-changesSinceSequence:). */
typedef struct TDChangesOptions
{
    unsigned limit;
    TDContentOptions contentOptions;
    BOOL includeDocs;
    BOOL includeConflicts;
    BOOL sortBySequence;
} TDChangesOptions;

extern const TDChangesOptions kDefaultTDChangesOptions;

/** A TouchDB database. */
@interface TD_Database : NSObject {
   @private
    NSString* _path;
    NSString* _name;
    FMDatabaseQueue* _fmdbQueue;
    id<CDTEncryptionKeyProvider> _keyProviderToOpenDB;
    BOOL _readOnly;
    BOOL _open;
    int _transactionLevel;
    NSMutableDictionary* _views;
    NSMutableDictionary* _validations;
    TDBlobStore* _attachments;
    NSMutableDictionary* _pendingAttachmentsByDigest;
    NSMutableArray* _activeReplicators;
}

- (id)initWithPath:(NSString*)path;

/**
 * @return YES if the database is open. NO in other case.
 */
- (BOOL)isOpen;

/**
 * This method check if the database is open and it was opened with the same key informed by the
 * provider
 *
 * @param provider it will return the key used to cipher the database
 *
 * @return YES is the database is open and it was opened with the provided key. NO in other case.
 */
- (BOOL)isOpenWithEncryptionKeyProvider:(id<CDTEncryptionKeyProvider>)provider;

/**
 * Open a database using a key to de-cipher its content. If the database does not exit before, it
 * will create it and initialise it. If the database is already open, it will check that the key
 * is valid.
 *
 * @param provider it will return the key used to de-cipher the database
 *
 * @return YES if the database is opened and initialised successfully. NO in other case
 */
- (BOOL)openWithEncryptionKeyProvider:(id<CDTEncryptionKeyProvider>)provider;

- (BOOL)close;
- (BOOL)deleteDatabase:(NSError**)outError;

/**
 * Delete a closed database, i.e. there must not be a database instance bound to the files in this
 * path. This method will remove from disk the database as well as the attachments (if there is any)
 *
 * @param path path to the database
 * @param outError will point to an NSError object in case of error.
 */
+ (BOOL)deleteClosedDatabaseAtPath:(NSString *)path error:(NSError **)outError;

/**
 * Create an empty database, i.e. it deletes all previous content and creates a new database
 *
 * @param path path where the database will be created
 * @param provider will return a key to cipher the content
 *
 * @return The next database or nil if there were an error
 */
+ (instancetype)createEmptyDBAtPath:(NSString*)path
          withEncryptionKeyProvider:(id<CDTEncryptionKeyProvider>)provider;

/** Should the database file be opened in read-only mode? */
@property BOOL readOnly;

@property (nonatomic, readonly) FMDatabaseQueue* fmdbQueue;

/** Replaces the database with a copy of another database.
    This is primarily used to install a canned database on first launch of an app, in which case you
   should first check .exists to avoid replacing the database if it exists already. The canned
   database would have been copied into your app bundle at build time.
    @param databasePath  Path of the database file that should replace this one.
    @param attachmentsPath  Path of the associated attachments directory, or nil if there are no
   attachments.
    @param error  If an error occurs, it will be stored into this parameter on return.
    @return  YES if the database was copied, NO if an error occurred. */
- (BOOL)replaceWithDatabaseFile:(NSString*)databasePath
                withAttachments:(NSString*)attachmentsPath
                          error:(NSError**)outError;

@property (readonly) NSString* path;
@property (readonly, copy) NSString* name;
@property (readonly) BOOL exists;

@property (readonly) NSUInteger documentCount;
@property (readonly) SequenceNumber lastSequence;
@property (readonly) NSString* privateUUID;
@property (readonly) NSString* publicUUID;

/** Executes the block within a database transaction.
    If the block returns a non-OK status, the transaction is aborted/rolled back.
    Any exception raised by the block will be caught and treated as kTDStatusException. */
- (TDStatus)inTransaction:(TDStatus (^)(FMDatabase*))block;

// DOCUMENTS:

- (TD_Revision*)getDocumentWithID:(NSString*)docID
                       revisionID:(NSString*)revID
                          options:(TDContentOptions)options
                           status:(TDStatus*)outStatus;
- (TD_Revision*)getDocumentWithID:(NSString*)docID revisionID:(NSString*)revID;

/** Only call from within a queued transaction **/
- (TD_Revision*)getDocumentWithID:(NSString*)docID
                       revisionID:(NSString*)revID
                          options:(TDContentOptions)options
                           status:(TDStatus*)outStatus
                         database:(FMDatabase*)db;

- (BOOL)existsDocumentWithID:(NSString*)docID revisionID:(NSString*)revID database:(FMDatabase*)db;

- (TDStatus)loadRevisionBody:(TD_Revision*)rev options:(TDContentOptions)options;

- (TDStatus)loadRevisionBody:(TD_Revision*)rev
                     options:(TDContentOptions)options
                    database:(FMDatabase*)db;

/** Returns an array of TDRevs in reverse chronological order,
 starting with the given revision. */
- (NSArray*)getRevisionHistory:(TD_Revision*)rev;
- (NSArray*)getRevisionHistory:(TD_Revision*)rev database:(FMDatabase*)db;

/** Returns the revision history as a _revisions dictionary, as returned by the REST API's
 * ?revs=true option. */
- (NSDictionary*)getRevisionHistoryDict:(TD_Revision*)rev inDatabase:(FMDatabase*)db;

/**
 Returns all the known revisions (or all current/conflicting revisions) of a document.
 Each database document (i.e. each row in the revs table) contains a 'current' and 'deleted'
 element.
 A row/documuent that has current = 1 is a leaf node in the revision tree for that document.
 And 'deleted', of course, indicates a deleted revision.

 For example, this method may be used to get all active conflicting revisions for a document by
 calling this method with onlyCurrent=YES and excludeDeleted=YES.

 Calling this method with onlyCurrent=NO and excludeDelete=NO will return the entire
 set of revisions.
 */
- (TD_RevisionList*)getAllRevisionsOfDocumentID:(NSString*)docID
                                    onlyCurrent:(BOOL)onlyCurrent
                                 excludeDeleted:(BOOL)excludeDeleted;
/**
 Sams as the method above, but is to be used within an ongoing database transaction.
 */
- (TD_RevisionList*)getAllRevisionsOfDocumentID:(NSString*)docID
                                    onlyCurrent:(BOOL)onlyCurrent
                                 excludeDeleted:(BOOL)excludeDeleted
                                       database:(FMDatabase*)db;

/** Returns IDs of local revisions of the same document, that have a lower generation number.
    Does not return revisions whose bodies have been compacted away, or deletion markers. */
- (NSArray*)getPossibleAncestorRevisionIDs:(TD_Revision*)rev limit:(unsigned)limit;

/** Returns the most recent member of revIDs that appears in rev's ancestry. */
- (NSString*)findCommonAncestorOf:(TD_Revision*)rev
                       withRevIDs:(NSArray*)revIDs
                         database:(FMDatabase*)db;

// VIEWS & QUERIES:

- (NSDictionary*)getAllDocs:(const struct TDQueryOptions*)options;

- (NSDictionary*)getDocsWithIDs:(NSArray*)docIDs options:(const struct TDQueryOptions*)options;

- (TD_View*)viewNamed:(NSString*)name;

- (TD_View*)existingViewNamed:(NSString*)name;

/** Returns the view with the given name. If there is none, and the name is in CouchDB
    format ("designdocname/viewname"), it attempts to load the view properties from the
    design document and compile them with the TDViewCompiler. */
- (TD_View*)compileViewNamed:(NSString*)name status:(TDStatus*)outStatus;

@property (readonly) NSArray* allViews;

- (TD_RevisionList*)changesSinceSequence:(SequenceNumber)lastSequence
                                 options:(const TDChangesOptions*)options
                                  filter:(TD_FilterBlock)filter
                                  params:(NSDictionary*)filterParams;

@end
