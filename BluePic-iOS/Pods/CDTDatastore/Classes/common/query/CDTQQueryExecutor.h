//
//  CDTQQueryExecutor.h
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

@class CDTDatastore;
@class CDTQResultSet;
@class CDTQSqlParts;
@class FMDatabaseQueue;

/**
 Handles querying indexes for a given datastore.
 */
@interface CDTQQueryExecutor : NSObject

/**
 Constructs a new CDTQQueryExecutor using the indexes in `database` to find documents from
 `datastore`.
 */
- (instancetype)initWithDatabase:(FMDatabaseQueue *)database datastore:(CDTDatastore *)datastore;

/**
 Execute the query passed using the selection of index definition provided.

 The index definitions are presumed to already exist and be up to date for the
 datastore and database passed to the constructor.

 @param query query to execute.
 @param indexes indexes to use (this method will select the most appropriate).
 @param skip how many results to skip before returning results to caller
 @param limit number of documents the result should be limited to
 @param fields fields to project from the result documents
 @param sortDocument document specifying the order to return results, nil to have no sorting
 */
- (CDTQResultSet *)find:(NSDictionary *)query
           usingIndexes:(NSDictionary *)indexes
                   skip:(NSUInteger)skip
                  limit:(NSUInteger)limit
                 fields:(NSArray *)fields
                   sort:(NSArray *)sortDocument;

/**
 Return SQL to get ordered list of docIds.

 @param sortDocument Array of ordering definitions `@[ @{"fieldName": "asc"}, @{@"fieldName2",
 @"asc"} ]`
 @param indexes dictionary of indexes
 */
+ (CDTQSqlParts *)sqlToSortIds:(NSSet /*NSString*/ *)docIdSet
                    usingOrder:(NSArray /*NSDictionary*/ *)sortDocument
                       indexes:(NSDictionary *)indexes;

@end
