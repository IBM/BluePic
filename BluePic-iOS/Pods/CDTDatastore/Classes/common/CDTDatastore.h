//
//  CDTDatastore.h
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

#import <Foundation/Foundation.h>
#import "CDTDatastoreManager.h"

@class CDTDocumentRevision;
@class FMDatabase;
@class CDTDocumentRevision;

/** NSNotification posted when a document is updated.
 UserInfo keys:
  - @"rev": the new CDTDocumentRevision,
  - @"source": NSURL of remote db pulled from,
  - @"winner": new winning CDTDocumentRevision, _if_ it changed (often same as rev).
 */
extern NSString *const CDTDatastoreChangeNotification;

@class TD_Database;

/**
 * The CDTDatastore is the core interaction point for create, delete and update
 * operations (CRUD) for within Cloudant Sync.
 *
 * The Datastore can be viewed as a pool of heterogeneous JSON documents. One
 * datastore can hold many different types of document, unlike tables within a
 * relational model. The datastore provides hooks, which allow for various querying models
 * to be built on top of its simpler key-value model.
 *
 * Each document consists of a set of revisions, hence most methods within
 * this class operating on CDTDocumentRevision objects, which carry both a
 * document ID and a revision ID. This forms the basis of the MVCC data model,
 * used to ensure safe peer-to-peer replication is possible.
 *
 * Each document is formed of a tree of revisions. Replication can create
 * branches in this tree when changes have been made in two or more places to
 * the same document in-between replications. MVCC exposes these branches as
 * conflicted documents. These conflicts should be resolved by user-code, by
 * marking all but one of the leaf nodes of the branches as "deleted", using
 * the [CDTDatastore deleteDocumentWithId:rev:error:] method. When the
 * datastore is next replicated with a remote datastore, this fix will be
 * propagated, thereby resolving the conflicted document across the set of
 * peers.
 *
 * **WARNING:** conflict resolution is coming in the next
 * release, where we'll be adding methods to:
 *
 * - Get the IDs of all conflicted documents within the datastore.</li>
 * - Get a list of all current revisions for a given document, so they
 *     can be merged to resolve the conflict.</li>
 *
 * @see CDTDocumentRevision
 *
 */
@interface CDTDatastore : NSObject

@property (nonatomic, strong, readonly) TD_Database *database;

+ (NSString *)versionString;

/**
 *
 * Creates a CDTDatastore instance.
 *
 * @param manager this datastore's maanger, must not be nil.
 * @param database the database where this datastore should save documents
 *
 */
- (instancetype)initWithManager:(CDTDatastoreManager *)manager database:(TD_Database *)database;

/**
 * The number of document in the datastore.
 */
@property (readonly) NSUInteger documentCount;

/**
 * The name of the datastore.
 */
@property (readonly) NSString *name;

/**
 * The name of the datastore.
 */
@property (readonly) NSString *extensionsDir;

/**
 * Returns a document's current winning revision.
 *
 * @param docId id of the specified document
 * @param error will point to an NSError object in case of error.
 *
 * @return current revision as CDTDocumentRevision of given document
 */
- (CDTDocumentRevision *)getDocumentWithId:(NSString *)docId
                                     error:(NSError *__autoreleasing *)error;

/**
 * Return a specific revision of a document.
 *
 * This method gets the revision of a document with a given ID. As the
 * datastore prunes the content of old revisions to conserve space, this
 * revision may contain the metadata but not content of the revision.
 *
 * @param docId id of the specified document
 * @param rev id of the specified revision
 * @param error will point to an NSError object in case of error.
 *
 * @return specified CDTDocumentRevision of the document for given
 *     document id or nil if it doesn't exist
 */
- (CDTDocumentRevision *)getDocumentWithId:(NSString *)docId
                                       rev:(NSString *)rev
                                     error:(NSError *__autoreleasing *)error;

/**
 * Unpaginated read of all documents.
 *
 * All documents are read into memory before being returned.
 *
 * Only the current winning revision of each document is returned.
 *
 * @return NSArray of CDTDocumentRevisions
 */
- (NSArray *)getAllDocuments;

/**
 * Enumerates the current winning revision for all documents in the
 * datastore and return a list of their document identifiers.
 *
 * @return NSArray of NSStrings
 */
- (NSArray *)getAllDocumentIds;

/**
 * Enumerate the current winning revisions for all documents in the
 * datastore.
 *
 * Logically, this method takes all the documents in either ascending
 * or descending order, skips all documents up to `offset` then
 * returns up to `limit` document revisions, stopping either
 * at `limit` or when the list of document is exhausted.
 *
 * Note that if the datastore changes between calls using offset/limit,
 * documents may be missed out.
 *
 * @param offset    start position
 * @param limit maximum number of documents to return
 * @param descending ordered descending if true, otherwise ascendingly
 * @return NSArray containing CDTDocumentRevision objects
 */
- (NSArray *)getAllDocumentsOffset:(NSUInteger)offset
                             limit:(NSUInteger)limit
                        descending:(BOOL)descending;

/**
 * Return the winning revisions for a set of document IDs.
 *
 * @param docIds list of document id
 *
 * @return NSArray containing CDTDocumentRevision objects
 */
- (NSArray *)getDocumentsWithIds:(NSArray *)docIds;

/**
 * Returns the history of revisions for the passed revision.
 *
 * This is each revision on the branch that `revision` is on,
 * from `revision` to the root of the tree.
 *
 * Older revisions will not contain the document data as it will have
 * been compacted away.
 */
- (NSArray *)getRevisionHistory:(CDTDocumentRevision *)revision;

/**
 * Return a directory for an extension to store its data for this CDTDatastore.
 *
 * @param extensionName name of the extension
 *
 * @return the directory for specified extensionName
 */
- (NSString *)extensionDataFolder:(NSString *)extensionName;

#pragma mark API V2
/**
 * Creates a document from a MutableDocumentRevision
 *
 * @param revision document revision to create document from
 * @param error will point to an NSError object in the case of an error
 *
 * @return document revision created
 */
- (CDTDocumentRevision *)createDocumentFromRevision:(CDTDocumentRevision *)revision
                                              error:(NSError *__autoreleasing *)error;

/**
 * Updates a document in the datastore with a new revision
 *
 *  @parm revision updated document revision
 *  @param error will point to an NSError object in the case of an error
 *
 *  @return the updated document
 *
 */
- (CDTDocumentRevision *)updateDocumentFromRevision:(CDTDocumentRevision *)revision
                                              error:(NSError *__autoreleasing *)error;
/**
 * Deletes a document from the datastore.
 *
 * @param revision document to delete from the datastore
 * @param error will point to an NSError object in the case of an error
 *
 * @return the deleted document
 */
- (CDTDocumentRevision *)deleteDocumentFromRevision:(CDTDocumentRevision *)revision
                                              error:(NSError *__autoreleasing *)error;

/**
 *
 * Delete a document and all leaf revisions.
 *
 * @param docId ID of the document
 * @param error will point to an NSError object in the case of an error
 *
 * @return an array of deleted documents
 *
 */
- (NSArray *)deleteDocumentWithId:(NSString *)docId error:(NSError *__autoreleasing *)error;

/**
 *
 * Compact local database, deleting document bodies, keeping only the metadata of
 * previous revisions
 *
 * @param error will point to an NSError object in the case of an error
 */
- (BOOL)compactWithError:(NSError *__autoreleasing *)error;
@end
