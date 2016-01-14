//
//  CDTDatastore+Query.h
//
//  Created by Rhys Short on 19/11/2014.
//
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
#import "CDTDatastore.h"
#import "CDTQIndexManager.h"

/**
 This category adds query capabilities to CDTDatastore.
 
 The query interface is based on Cloudant Query, which has a query
 syntax loosely modelled on MongoDB's query selector.
 */
@interface CDTDatastore (Query)

/**
 Check to see if SQLite is compiled with the necessary compile options
 to support full text search.
 
 @return whether text search is available
 */
@property (nonatomic, readonly, getter = isTextSearchEnabled) BOOL textSearchEnabled;

/**
 Return a list of the indexes defined.
 
 This is returned in a dictionary structure:
 
     { "indexName": { "fields": [ "field1", "field2" ],
                      "type": "json",
                      "name": "indexName" },
       ...
     }
 */
- (NSDictionary * /* NSString -> NSArray[NSString]*/)listIndexes;

/**
 Create a new index over a set of fields.
 
 Fields in sub-documents can be specified using dotted notation.
 
 An example:
 
     { "name": "mike", "address": { "street": "Any Road" } }
 
 The field name "name" would index "mike", while the field name
 "address.street" would index "Any Road".
 
 Indexing an array will add each value in the array to the index.
 There may only be one array field per index.
 
 @return The name of the index if it's created successfully.
 */
- (NSString *)ensureIndexed:(NSArray * /* NSString */)fieldNames
                   withName:(NSString *)indexName;
/**
 Create a new index based on an index type over a set of fields.
 
 Index type can be either "json" or "text".  A TEXT index provides
 the ability to perform text searches.
 */
- (NSString *)ensureIndexed:(NSArray * /* NSString */)fieldNames
                   withName:(NSString *)indexName
                       type:(NSString *)type;

/**
 Create a new index based on an index type with specific index 
 settings over a set of fields.
 
 Index settings currenly only apply to a TEXT index.
 
 An example:
 
 Where ds is your datastore and fields is an array of fieldnames...
 
 [ds ensureIndexed: fields 
          withName: @"text_idx"
              type: @"text" 
          settings: @{ @"tokenize": @"porter" }]
 
 This will create a TEXT index named text_idx and override the
 default tokenizer used to construct the TEXT index with the
 "porter" algorithm tokenizer.
 */
- (NSString *)ensureIndexed:(NSArray * /* NSString */)fieldNames
                   withName:(NSString *)indexName
                       type:(NSString *)type
                   settings:(NSDictionary *)indexSettings;

/**
 Delete an index.
 */
- (BOOL)deleteIndexNamed:(NSString *)indexName;

/**
 Bring indexes up to date with the contents of the datastore.
 
 This happens automatically before queries happen, but if you
 know there are a lot of updates to process, explicitly calling
 -updateAllIndexes will save time during the next query. It's
 useful to call when a replication completes, for example.
 */
- (BOOL)updateAllIndexes;

/**
 Find documents matching a query.
 
 See -find:skip:limit:fields:sort: for more details.
 
 Failures during query (e.g., invalid query) are logged rather than
 error being returned.
 
 @return Set of documents, or `nil` if there was an error.
 */
- (CDTQResultSet *)find:(NSDictionary *)query;

/**
 Find document matching a query.
 
 See https://github.com/cloudant/CDTDatastore/blob/master/doc/query.md 
 for details of the query syntax and option meanings.
 
 Failures during query (e.g., invalid query) are logged rather than
 error being returned.
 
 @return Set of documents, or `nil` if there was an error.
 */
- (CDTQResultSet *)find:(NSDictionary *)query
                   skip:(NSUInteger)skip
                  limit:(NSUInteger)limit
                 fields:(NSArray *)fields
                   sort:(NSArray *)sortDocument;

@end
