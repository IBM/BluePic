//
//  CDTQIndexCreator.m
//
//  Created by Michael Rhodes on 29/09/2014.
//  Copyright (c) 2014 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "CDTQIndexCreator.h"

#import "CDTQIndexManager.h"
#import "CDTQIndexUpdater.h"
#import "CDTQLogging.h"

#import "CloudantSync.h"
#import <FMDB/FMDB.h>

@interface CDTQIndexCreator ()

@property (nonatomic, strong) FMDatabaseQueue *database;
@property (nonatomic, strong) CDTDatastore *datastore;

@end

@implementation CDTQIndexCreator

- (instancetype)initWithDatabase:(FMDatabaseQueue *)database datastore:(CDTDatastore *)datastore
{
    self = [super init];
    if (self) {
        _database = database;
        _datastore = datastore;
    }
    return self;
}

#pragma mark Convenience methods

+ (NSString *)ensureIndexed:(CDTQIndex *)index
                 inDatabase:(FMDatabaseQueue *)database
              fromDatastore:(CDTDatastore *)datastore
{
    CDTQIndexCreator *executor =
        [[CDTQIndexCreator alloc] initWithDatabase:database datastore:datastore];
    return [executor ensureIndexed:index];
}

#pragma mark Instance methods

/**
 Add a single, possibly compound index for the given field names and ensure all indexing
 constraints are met.

 @param fieldNames List of fieldnames in the sort format
 @param indexName Name of index to create.
 @returns name of created index
 */
- (NSString *)ensureIndexed:(CDTQIndex *)index
{
    if (!index) {
        return nil;
    }
    
    if ([index.indexType.lowercaseString isEqualToString:@"text"]) {
        if (![CDTQIndexManager ftsAvailableInDatabase:self.database]) {
            LogError(@"Text search not supported.  To add support for text "
                     @"search, enable FTS compile options in SQLite.");
            return nil;
        }
    }

    NSArray *fieldNames = [CDTQIndexCreator removeDirectionsFromFields:index.fieldNames];

    for (NSString *fieldName in fieldNames) {
        if (![CDTQIndexCreator validFieldName:fieldName]) {
            return nil;
        }
    }

    // Check there are no duplicate field names in the array
    NSSet *uniqueNames = [NSSet setWithArray:fieldNames];
    if (uniqueNames.count != fieldNames.count) {
        LogError(@"Cannot create index with duplicated field names %@", fieldNames);
        return nil;
    }

    // Prepend _id and _rev if it's not in the array
    if (![fieldNames containsObject:@"_rev"]) {
        NSMutableArray *tmp = [NSMutableArray arrayWithObject:@"_rev"];
        [tmp addObjectsFromArray:fieldNames];
        fieldNames = [NSArray arrayWithArray:tmp];
    }

    if (![fieldNames containsObject:@"_id"]) {
        NSMutableArray *tmp = [NSMutableArray arrayWithObject:@"_id"];
        [tmp addObjectsFromArray:fieldNames];
        fieldNames = [NSArray arrayWithArray:tmp];
    }

    // Check the index limit.  Limit is 1 for "text" indexes and unlimited for "json" indexes.
    // Then check whether the index already exists; return success if it does and is same,
    // else fail.
    NSDictionary *existingIndexes = [CDTQIndexManager listIndexesInDatabaseQueue:self.database];
    if ([CDTQIndexCreator indexLimitReached:index basedOnIndexes:existingIndexes]) {
        LogError(@"Index limit reached.  Cannot create index %@.", index.indexName);
        return nil;
    }
    if (existingIndexes[index.indexName] != nil) {
        NSDictionary *existingIndex = existingIndexes[index.indexName];
        NSString *existingType = existingIndex[@"type"];
        NSString *existingSettings = existingIndex[@"settings"];
        NSSet *existingFields = [NSSet setWithArray:existingIndex[@"fields"]];
        NSSet *newFields = [NSSet setWithArray:fieldNames];

        if ([existingFields isEqualToSet:newFields] &&
            [index compareIndexTypeTo:existingType withIndexSettings:existingSettings]) {
            BOOL success = [CDTQIndexUpdater updateIndex:index.indexName
                                              withFields:fieldNames
                                              inDatabase:_database
                                           fromDatastore:_datastore
                                                   error:nil];
            return success ? index.indexName : nil;
        } else {
            return nil;
        }
    }

    __block BOOL success = YES;

    [_database inTransaction:^(FMDatabase *db, BOOL *rollback) {

        // Insert metadata table entries
        NSArray *inserts = [CDTQIndexCreator
                            insertMetadataStatementsForIndexName:index.indexName
                                                            type:index.indexType
                                                        settings:index.settingsAsJSON
                                                      fieldNames:fieldNames];
        for (CDTQSqlParts *sql in inserts) {
            success = success && [db executeUpdate:sql.sqlWithPlaceholders
                                     withArgumentsInArray:sql.placeholderValues];
        }

        // Create SQLite data structures to support the index
        // For JSON index type create a SQLite table and a SQLite index
        // For TEXT index type create a SQLite virtual table
        if ([index.indexType.lowercaseString isEqualToString:kCDTQTextType]) {
            // Create the virtual table for the TEXT index
            CDTQSqlParts *createVirtualTable =
            [CDTQIndexCreator createVirtualTableStatementForIndexName:index.indexName
                                                           fieldNames:fieldNames
                                                             settings:index.indexSettings];
            success = success && [db executeUpdate:createVirtualTable.sqlWithPlaceholders
                              withArgumentsInArray:createVirtualTable.placeholderValues];
        } else {
            // Create the table for the index
            CDTQSqlParts *createTable =
            [CDTQIndexCreator createIndexTableStatementForIndexName:index.indexName
                                                         fieldNames:fieldNames];
            success = success && [db executeUpdate:createTable.sqlWithPlaceholders
                              withArgumentsInArray:createTable.placeholderValues];
            
            // Create the SQLite index on the index table
            
            CDTQSqlParts *createIndex =
            [CDTQIndexCreator createIndexIndexStatementForIndexName:index.indexName
                                                         fieldNames:fieldNames];
            success = success && [db executeUpdate:createIndex.sqlWithPlaceholders
                              withArgumentsInArray:createIndex.placeholderValues];
        }
        
        if (!success) {
            *rollback = YES;
        }
    }];

    // Update the new index if it's been created
    if (success) {
        success = success && [CDTQIndexUpdater updateIndex:index.indexName
                                                withFields:fieldNames
                                                inDatabase:_database
                                             fromDatastore:_datastore
                                                     error:nil];
    }

    return success ? index.indexName : nil;
}

/**
 Validate the field name string is usable.

 The only restriction so far is that the parts don't start with
 a $ sign, as this makes the query language ambiguous.
 */
+ (BOOL)validFieldName:(NSString *)fieldName
{
    NSArray *parts = [fieldName componentsSeparatedByString:@"."];
    for (NSString *part in parts) {
        if ([part hasPrefix:@"$"]) {
            LogError(@"Field names cannot start with a $ in field %@", fieldName);
            return NO;
        }
    }
    return YES;
}

/**
 We don't support directions on field names, but they are an optimisation so
 we can discard them safely.
 */
+ (NSArray /*NSDictionary or NSString*/ *)removeDirectionsFromFields:(NSArray *)fieldNames
{
    NSMutableArray *result = [NSMutableArray array];

    for (NSObject *field in fieldNames) {
        if ([field isKindOfClass:[NSDictionary class]]) {
            NSDictionary *specifier = (NSDictionary *)field;
            if (specifier.count == 1) {
                NSString *fieldName = [specifier allKeys][0];
                [result addObject:fieldName];
            }
        } else if ([field isKindOfClass:[NSString class]]) {
            [result addObject:field];
        }
    }

    return result;
}

/**
 * Based on the proposed index and the list of existing indexes, this function checks
 * whether another index can be created.  Currently the limit for TEXT indexes is 1.
 * JSON indexes are unlimited.
 *
 * @param existingIndexes the list of already existing indexes
 * @param index the proposed index
 * @return whether the index limit has been reached
 */
+ (BOOL) indexLimitReached:(CDTQIndex *)index basedOnIndexes:(NSDictionary *)existingIndexes
{
    if ([index.indexType.lowercaseString isEqualToString:kCDTQTextType]) {
        for (NSString *name in existingIndexes.allKeys) {
            NSDictionary *existingIndex = existingIndexes[name];
            NSString *type = existingIndex[@"type"];
            if ([type.lowercaseString isEqualToString:kCDTQTextType] &&
                ![name.lowercaseString isEqualToString:index.indexName.lowercaseString]) {
                LogError(@"The text index %@ already exists.  "
                          "One text index per datastore permitted.  "
                          "Delete %@ and recreate %@", name, name, index.indexName);
                return YES;
            }
        }
    }
    
    return NO;
}

+ (NSArray /*CDTQSqlParts*/ *)insertMetadataStatementsForIndexName:(NSString *)indexName
                                                              type:(NSString *)indexType
                                                          settings:(NSString *)indexSettings
                                                        fieldNames:
                                                            (NSArray /*NSString*/ *)fieldNames
{
    if (!indexName) {
        return nil;
    }

    if (!fieldNames || fieldNames.count == 0) {
        return nil;
    }

    NSMutableArray *result = [NSMutableArray array];
    for (NSString *fieldName in fieldNames) {
        NSString *sql;
        NSArray *metaParameters;
        if (indexSettings) {
            sql = @"INSERT INTO %@"
                   " (index_name, index_type, index_settings, field_name, last_sequence) "
                   "VALUES (?, ?, ?, ?, 0);";
            metaParameters = @[ indexName, indexType, indexSettings, fieldName ];
        } else {
            sql = @"INSERT INTO %@"
                   " (index_name, index_type, field_name, last_sequence) "
                   "VALUES (?, ?, ?, 0);";
            metaParameters = @[ indexName, indexType, fieldName ];
        }
        sql = [NSString stringWithFormat:sql, kCDTQIndexMetadataTableName];
        
        CDTQSqlParts *parts = [CDTQSqlParts partsForSql:sql parameters:metaParameters];
        [result addObject:parts];
    }
    return result;
}

+ (CDTQSqlParts *)createIndexTableStatementForIndexName:(NSString *)indexName
                                             fieldNames:(NSArray /*NSString*/ *)fieldNames
{
    if (!indexName) {
        return nil;
    }

    if (!fieldNames || fieldNames.count == 0) {
        return nil;
    }

    NSString *tableName = [CDTQIndexManager tableNameForIndex:indexName];
    NSMutableArray *clauses = [NSMutableArray array];
    for (NSString *fieldName in fieldNames) {
        NSString *clause = [NSString stringWithFormat:@"\"%@\" NONE", fieldName];
        [clauses addObject:clause];
    }

    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE %@ ( %@ );", tableName,
                                               [clauses componentsJoinedByString:@", "]];
    return [CDTQSqlParts partsForSql:sql parameters:@[]];
}

+ (CDTQSqlParts *)createIndexIndexStatementForIndexName:(NSString *)indexName
                                             fieldNames:(NSArray /*NSString*/ *)fieldNames
{
    if (!indexName) {
        return nil;
    }

    if (!fieldNames || fieldNames.count == 0) {
        return nil;
    }

    NSString *tableName = [CDTQIndexManager tableNameForIndex:indexName];
    NSString *sqlIndexName = [tableName stringByAppendingString:@"_index"];

    NSMutableArray *clauses = [NSMutableArray array];
    for (NSString *fieldName in fieldNames) {
        [clauses addObject:[NSString stringWithFormat:@"\"%@\"", fieldName]];
    }

    NSString *sql = [NSString stringWithFormat:@"CREATE INDEX %@ ON %@ ( %@ );", sqlIndexName,
                                               tableName, [clauses componentsJoinedByString:@", "]];
    return [CDTQSqlParts partsForSql:sql parameters:@[]];
}

/**
 * This function generates the virtual table create SQL for the specified index.
 * Note:  Any column that contains an '=' will cause the statement to fail
 *        because it triggers SQLite to expect that a parameter/value is being passed in.
 *
 * @param indexName the index name to be used when creating the SQLite virtual table
 * @param fieldNames the columns in the table
 * @param indexSettings the special settings to apply to the virtual table -
 *                      (only 'tokenize' is current supported)
 * @return the SQL to create the SQLite virtual table
 */
+ (CDTQSqlParts *)createVirtualTableStatementForIndexName:(NSString *)indexName
                                               fieldNames:(NSArray /*NSString*/ *)fieldNames
                                                 settings:(NSDictionary *)indexSettings;
{
    if (!indexName) {
        return nil;
    }
    
    if (!fieldNames || fieldNames.count == 0) {
        return nil;
    }
    
    NSString *tableName = [CDTQIndexManager tableNameForIndex:indexName];
    NSMutableArray *clauses = [NSMutableArray array];
    for (NSString *fieldName in fieldNames) {
        [clauses addObject:[NSString stringWithFormat:@"\"%@\"", fieldName]];
    }
    
    NSMutableArray *settingsClauses = [NSMutableArray array];
    for (NSString *parameter in indexSettings.allKeys) {
        [settingsClauses addObject:[NSString stringWithFormat:@"%@=%@",
                                    parameter,
                                    indexSettings[parameter]]];
    }
    
    NSString *sql = [NSString stringWithFormat:@"CREATE VIRTUAL TABLE %@ USING FTS4 ( %@, %@ );",
                     tableName,
                     [clauses componentsJoinedByString:@", "],
                     [settingsClauses componentsJoinedByString:@", "]];
    return [CDTQSqlParts partsForSql:sql parameters:@[]];
}

@end
