//
//  CDTQIndexUpdater.h
//
//  Created by Mike Rhodes on 2014-09-29
//  Copyright (c) 2014 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import <Foundation/Foundation.h>

#import "TD_Database.h"

@class CDTDocumentRevision;
@class CDTDatastore;

@class CDTQSqlParts;
@class FMDatabaseQueue;

/**
 Handles updating indexes for a given datastore.
 */
@interface CDTQIndexUpdater : NSObject

/**
 Update all the indexes in a set.

 The indexes are assumed to already exist.
 */
+ (BOOL)updateAllIndexes:(NSDictionary /*NSString -> NSArray[NSString]*/ *)indexes
              inDatabase:(FMDatabaseQueue *)database
           fromDatastore:(CDTDatastore *)datastore;

/**
 Update a single index.

 The index is assumed to already exist.
 */
+ (BOOL)updateIndex:(NSString *)indexName
         withFields:(NSArray /* NSString */ *)fieldNames
         inDatabase:(FMDatabaseQueue *)database
      fromDatastore:(CDTDatastore *)datastore
              error:(NSError *__autoreleasing *)error;

/**
 Constructs a new CDTQQueryExecutor using the indexes in `database` to index documents from
 `datastore`.
 */
- (instancetype)initWithDatabase:(FMDatabaseQueue *)database datastore:(CDTDatastore *)datastore;

/**
 Update all the indexes in a set.

 The indexes are assumed to already exist.
 */
- (BOOL)updateAllIndexes:(NSDictionary /*NSString -> NSArray[NSString]*/ *)indexes;

/**
 Update a single index.

 The index is assumed to already exist.
 */
- (BOOL)updateIndex:(NSString *)indexName
         withFields:(NSArray /* NSString */ *)fieldNames
              error:(NSError *__autoreleasing *)error;

/**
 Generate the DELETE statement to remove a documents entries from an index.
 */
+ (CDTQSqlParts *)partsToDeleteIndexEntriesForDocId:(NSString *)docId
                                          fromIndex:(NSString *)indexName;

/**
 Generate the INSERT statement to add a document to an index.
 */
+ (NSArray /*CDTQSqlParts*/ *)partsToIndexRevision:(CDTDocumentRevision *)rev
                                           inIndex:(NSString *)indexName
                                    withFieldNames:(NSArray *)fieldNames;

/**
 Return the sequence number for the given index

 This is the sequence number from this index's datastore that the
 index is up to date with.
 */
- (SequenceNumber)sequenceNumberForIndex:(NSString *)indexName;

@end
