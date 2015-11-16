//
//  CDTQQuerySqlTranslator.h
//
//  Created by Michael Rhodes on 03/10/2014.
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

@class CDTQSqlParts;

@interface CDTQQueryNode : NSObject

@end

@interface CDTQChildrenQueryNode : CDTQQueryNode

@property (nonatomic, strong) NSMutableArray *children;

@end

@interface CDTQAndQueryNode : CDTQChildrenQueryNode

@end

@interface CDTQOrQueryNode : CDTQChildrenQueryNode

@end

@interface CDTQSqlQueryNode : CDTQQueryNode

@property (nonatomic, strong) CDTQSqlParts *sql;

@end

/**
 This class translates Cloudant Query selectors into the SQL we need to use
 to query our indexes.

 It creates a tree structure which contains AND/OR nodes, along with the SQL which
 needs to be used to get a list of document IDs for each level. This tree structure
 is passed back out of the translation process for execution by an interpreter which
 can perform the needed AND and OR operations between the document ID sets returned
 by the SQL queries.

 This merging of results in code allows use to make more intelligent use of indexes
 within the SQLite database. As SQLite allows us to use just a single index per query,
 performing several queries over indexes and then using set operations works out
 more flexible and likely more efficient.

 The SQL must be executed separately so we can do it in a transaction so we're doing
 it over a consistent view of the index.

 The translator is a simple depth-first, recursive decent parser over the selector
 dictionary.

 Some examples:

 AND : [ { x: X }, { y: Y } ]

 This can be represented by a single SQL query and AND tree node:

    AND
     |
    sql


 OR : [ { x: X }, { y: Y } ]

 This is a single OR node and two SQL queries:

       OR
       / \
     sql  sql

 The interpreter then unions the results.


 OR : [ { AND : [ { x: X }, { y: Y } ] }, { y: Y } ]

 This requires a more complex tree:

          OR
         /   \
       AND    sql
        |
       sql

 We could collapse out the extra AND node.


 AND : [ { OR : [ { x: X }, { y: Y } ] }, { y: Y } ]

 This is really the most complex situation:

         AND
         /  \
       OR   sql
      / |
    sql sql

 These basic patterns can be composed into more complicate structures.
 */
@interface CDTQQuerySqlTranslator : NSObject

+ (CDTQQueryNode *)translateQuery:(NSDictionary *)query
                     toUseIndexes:(NSDictionary *)indexes
                indexesCoverQuery:(BOOL *)indexesCoverQuery;

/**
 Expand implicit operators in a query.
 */
//+ (NSDictionary *)normaliseQuery:(NSDictionary *)query;

/**
 Extract fields from an AND clause

 `fieldName` and so on from:

 ```
 @[@{@"fieldName": @"mike"}, ...]
 ```
 */
+ (NSArray *)fieldsForAndClause:(NSArray *)clause;

/**
 Checks for the existence of an operator in a query clause array
*/
+ (BOOL)isOperator:(NSString *)operator inClause:(NSArray *)clause;

/**
 Selects an index to use for a given query from the set provided.

 Here we're looking for the index which supports all the fields used in the query.

 @param query full query provided by user.
 @param indexes index list of the form @{indexName: @[fieldName1, fieldName2]}
 @return name of index from `indexes` to ues for `query`, or `nil` if none found.
 */
+ (NSString *)chooseIndexForAndClause:(NSArray *)clause fromIndexes:(NSDictionary *)indexes;

/**
 Selects an index to use for a set of fields.
 */
+ (NSString *)chooseIndexForFields:(NSSet *)neededFields fromIndexes:(NSDictionary *)indexes;

/**
 Returns the SQL WHERE clause for a query.
 */
+ (CDTQSqlParts *)wherePartsForAndClause:(NSArray *)clause usingIndex:(NSString *)indexName;

/**
 Returns the SQL statement to find document IDs matching query.

 @param query the query being executed.
 @param indexName the index selected for use in this query
 */
+ (CDTQSqlParts *)selectStatementForAndClause:(NSArray *)clause usingIndex:(NSString *)indexName;

@end
