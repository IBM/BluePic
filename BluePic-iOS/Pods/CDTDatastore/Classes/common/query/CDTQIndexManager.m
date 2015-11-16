//
//  CDTQIndexManager.m
//
//  Created by Mike Rhodes on 2014-09-27
//  Copyright (c) 2014 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

//
// The metadata for an index is represented in the database table as follows:
//
//   index_name  |  index_type  |  field_name  |  last_sequence
//   -----------------------------------------------------------
//     name      |  json        |   _id        |     0
//     name      |  json        |   _rev       |     0
//     name      |  json        |   firstName  |     0
//     name      |  json        |   lastName   |     0
//     age       |  json        |   age        |     0
//
// The index itself is a single table, with a colum for docId and each of the indexed fields:
//
//      _id      |   _rev      |  firstName   |  lastName
//   --------------------------------------------------------
//     miker     |  1-blah     |  Mike        |  Rhodes
//     johna     |  3-blob     |  John        |  Appleseed
//     joeb      |  2-blip     |  Joe         |  Bloggs
//
// There is a single SQLite index created on all columns of this table.
//
// N.b.: _id and _rev are automatically added to all indexes to allow them to be used to
// project CDTDocumentRevisions without the need to load a document from the datastore.
//

#import "CDTQIndexManager.h"

#import "CDTQIndex.h"
#import "CDTQResultSet.h"
#import "CDTQIndexUpdater.h"
#import "CDTQQueryExecutor.h"
#import "CDTQIndexCreator.h"
#import "CDTQLogging.h"

#import "CDTEncryptionKeyProvider.h"
#import "CDTDatastore+EncryptionKey.h"

#import "TD_Database.h"
#import "TD_Body.h"

#import "FMDatabase+EncryptionKey.h"

#import <CloudantSync.h>
#import <FMDB/FMDB.h>

NSString *const CDTQIndexManagerErrorDomain = @"CDTIndexManagerErrorDomain";

NSString *const kCDTQIndexTablePrefix = @"_t_cloudant_sync_query_index_";
NSString *const kCDTQIndexMetadataTableName = @"_t_cloudant_sync_query_metadata";

static NSString *const kCDTQExtensionName = @"com.cloudant.sync.query";
static NSString *const kCDTQIndexFieldNamePattern = @"^[a-zA-Z][a-zA-Z0-9_]*$";

static const int VERSION = 2;

@interface CDTQIndexManager ()

@property (nonatomic, strong) NSRegularExpression *validFieldName;
@property (readwrite) BOOL textSearchEnabled;

@end

@implementation CDTQSqlParts

+ (CDTQSqlParts *)partsForSql:(NSString *)sql parameters:(NSArray *)parameters
{
    CDTQSqlParts *parts = [[CDTQSqlParts alloc] init];
    parts.sqlWithPlaceholders = sql;
    parts.placeholderValues = parameters;
    return parts;
}

- (NSString *)description
{
    return [NSString
        stringWithFormat:@"sql: %@ vals: %@", self.sqlWithPlaceholders, self.placeholderValues];
}

@end

@implementation CDTQIndexManager

+ (CDTQIndexManager *)managerUsingDatastore:(CDTDatastore *)datastore
                                      error:(NSError *__autoreleasing *)error
{
    return [[CDTQIndexManager alloc] initUsingDatastore:datastore error:error];
}

- (instancetype)initUsingDatastore:(CDTDatastore *)datastore error:(NSError *__autoreleasing *)error
{
    self = [super init];
    if (self) {
        _database = [CDTQIndexManager databaseQueueWithDatastore:datastore error:error];
        if (_database) {
            _datastore = datastore;
            _validFieldName =
                [[NSRegularExpression alloc] initWithPattern:kCDTQIndexFieldNamePattern
                                                     options:0
                                                       error:error];
            _textSearchEnabled = [CDTQIndexManager ftsAvailableInDatabase:_database];
        } else {
            self = nil;
        }
    }

    return self;
}

#pragma mark List indexes

/**
 Returns:

 { indexName: { type: json,
                name: indexName,
                fields: [field1, field2]
 }
 */
- (NSDictionary * /* NSString -> NSArray[NSString]*/)listIndexes
{
    return [CDTQIndexManager listIndexesInDatabaseQueue:_database];
}

+ (NSDictionary /* NSString -> NSArray[NSString]*/ *)listIndexesInDatabaseQueue:
                                                         (FMDatabaseQueue *)db
{
    // Accumulate indexes and definitions into a dictionary

    __block NSDictionary *indexes;

    [db inDatabase:^(FMDatabase *db) { indexes = [self listIndexesInDatabase:db]; }];

    return indexes;
}

+ (NSDictionary /* NSString -> NSArray[NSString]*/ *)listIndexesInDatabase:(FMDatabase *)db
{
    // Accumulate indexes and definitions into a dictionary

    NSMutableDictionary *indexes = [NSMutableDictionary dictionary];

    NSString *sql = @"SELECT index_name, index_type, field_name, index_settings FROM %@;";
    sql = [NSString stringWithFormat:sql, kCDTQIndexMetadataTableName];
    FMResultSet *rs = [db executeQuery:sql];
    while ([rs next]) {
        NSString *rowIndex = [rs stringForColumn:@"index_name"];
        NSString *rowType = [rs stringForColumn:@"index_type"];
        NSString *rowField = [rs stringForColumn:@"field_name"];
        NSString *rowSettings = [rs stringForColumn:@"index_settings"];

        if (indexes[rowIndex] == nil) {
            if (rowSettings) {
                indexes[rowIndex] = @{@"type" : rowType,
                                      @"name" : rowIndex,
                                      @"fields" : [NSMutableArray array],
                                      @"settings" : rowSettings};
            } else {
                indexes[rowIndex] = @{@"type" : rowType,
                                      @"name" : rowIndex,
                                      @"fields" : [NSMutableArray array]};
            }
        }

        [indexes[rowIndex][@"fields"] addObject:rowField];
    }
    [rs close];

    // Now we need to make the return value immutable

    for (NSString *indexName in [indexes allKeys]) {
        NSMutableDictionary *details = indexes[indexName];
        if (details[@"settings"]) {
            indexes[indexName] = @{
                @"type" : details[@"type"],
                @"name" : details[@"name"],
                @"fields" : [details[@"fields"] copy],  // -copy makes arrays immutable
                @"settings" : details[@"settings"]
            };
        } else {
            indexes[indexName] = @{
                @"type" : details[@"type"],
                @"name" : details[@"name"],
                @"fields" : [details[@"fields"] copy]  // -copy makes arrays immutable
            };
        }
    }

    return [NSDictionary dictionaryWithDictionary:indexes];  // make dictionary immutable
}

#pragma mark Create Indexes

/**
 Add a single, possibly compound, index for the given field names.

 This function generates a name for the new index.

 @param fieldNames List of fieldnames in the sort format
 @returns name of created index
 */
- (NSString *)ensureIndexed:(NSArray * /* NSString */)fieldNames
{
    LogError(@"-ensureIndexed: not implemented");
    return nil;
}

/**
 Add a single, possibly compound, index for the given field names.

 @param fieldNames List of fieldnames in the sort format
 @param indexName Name of index to create.
 @returns name of created index
 */
- (NSString *)ensureIndexed:(NSArray * /* NSString */)fieldNames withName:(NSString *)indexName
{
    return [CDTQIndexCreator ensureIndexed:[CDTQIndex index:indexName withFields:fieldNames]
                                inDatabase:_database
                             fromDatastore:_datastore];
}

/**
 Add a single, possibly compound, index for the given field names.

 @param fieldNames List of fieldnames in the sort format
 @param indexName Name of index to create.
 @param type The type of index (json or text currently supported)
 @returns name of created index
 */
- (NSString *)ensureIndexed:(NSArray * /* NSString */)fieldNames
                   withName:(NSString *)indexName
                       type:(NSString *)type
{
    return [self ensureIndexed:fieldNames withName:indexName type:type settings:nil];
}

/**
 Add a single, possibly compound, index for the given field names.
 
 @param fieldNames List of fieldnames in the sort format
 @param indexName Name of index to create.
 @param type The type of index (json or text currently supported)
 @param indexSettings The optional settings to be applied to an index
 *                    Only text indexes support settings - Ex. { "tokenize" : "simple" }
 @returns name of created index
 */
- (NSString *)ensureIndexed:(NSArray * /* NSString */)fieldNames
                   withName:(NSString *)indexName
                       type:(NSString *)type
                   settings:(NSDictionary *)indexSettings
{
    return [CDTQIndexCreator ensureIndexed:[CDTQIndex index:indexName
                                                 withFields:fieldNames
                                                     ofType:type
                                               withSettings:indexSettings]
                                inDatabase:_database
                             fromDatastore:_datastore];
}

#pragma mark Delete Indexes

- (BOOL)deleteIndexNamed:(NSString *)indexName
{
    __block BOOL success = YES;

    [_database inTransaction:^(FMDatabase *db, BOOL *rollback) {

        NSString *tableName = [CDTQIndexManager tableNameForIndex:indexName];
        NSString *sql;

        // Drop the index table
        sql = [NSString stringWithFormat:@"DROP TABLE \"%@\";", tableName];
        success = success && [db executeUpdate:sql withArgumentsInArray:@[]];

        // Delete the metadata entries
        sql = [NSString
            stringWithFormat:@"DELETE FROM %@ WHERE index_name = ?", kCDTQIndexMetadataTableName];
        success = success && [db executeUpdate:sql withArgumentsInArray:@[ indexName ]];

        if (!success) {
            LogError(@"Failed to delete index: %@", indexName);
            *rollback = YES;
        }
    }];

    return success;
}

#pragma mark Update indexes

- (BOOL)updateAllIndexes
{
    // TODO

    // To start with, assume top-level fields only

    NSDictionary *indexes = [self listIndexes];
    return
        [CDTQIndexUpdater updateAllIndexes:indexes inDatabase:_database fromDatastore:_datastore];
}

#pragma mark Query indexes

- (CDTQResultSet *)find:(NSDictionary *)query
{
    return [self find:query skip:0 limit:0 fields:nil sort:nil];
}

- (CDTQResultSet *)find:(NSDictionary *)query
                   skip:(NSUInteger)skip
                  limit:(NSUInteger)limit
                 fields:(NSArray *)fields
                   sort:(NSArray *)sortDocument
{
    if (!query) {
        LogError(@"-find called with nil selector; bailing.");
        return nil;
    }

    if (![self updateAllIndexes]) {
        return nil;
    }

    CDTQQueryExecutor *queryExecutor =
        [[CDTQQueryExecutor alloc] initWithDatabase:_database datastore:_datastore];
    return [queryExecutor find:query
                  usingIndexes:[self listIndexes]
                          skip:skip
                         limit:limit
                        fields:fields
                          sort:sortDocument];
}

#pragma mark Utilities

+ (NSString *)tableNameForIndex:(NSString *)indexName
{
    return [kCDTQIndexTablePrefix stringByAppendingString:indexName];
}

+ (BOOL)ftsAvailableInDatabase:(FMDatabaseQueue *)db
{
    __block BOOL ftsOptionsExist = NO;
    
    [db inDatabase:^(FMDatabase *db) {
        NSMutableArray *ftsCompileOptions = [NSMutableArray arrayWithArray:@[ @"ENABLE_FTS3" ] ];
        FMResultSet *rs = [db executeQuery:@"PRAGMA compile_options;"];
        while ([rs next]) {
            NSString *compileOption = [rs stringForColumnIndex:0];
            [ftsCompileOptions removeObject:compileOption];
            if (ftsCompileOptions.count == 0) {
                ftsOptionsExist = YES;
                break;
            }
        }
        [rs close];
    }];
    
    return ftsOptionsExist;
}

- (BOOL)isTextSearchEnabled
{
    if (!_textSearchEnabled) {
        LogInfo(@"Based on SQLite compile options, "
                @"text search is currently not supported.  "
                @"To enable text search recompile SQLite with "
                @"the full text saerch compile options turned on.");
    }
    return _textSearchEnabled;
}

#pragma mark Setup methods

+ (FMDatabaseQueue *)databaseQueueWithDatastore:(CDTDatastore *)datastore
                                          error:(NSError *__autoreleasing *)error
{
    NSString *dir = [datastore extensionDataFolder:kCDTQExtensionName];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir
                              withIntermediateDirectories:TRUE
                                               attributes:nil
                                                    error:nil];
    NSString *filename = [NSString pathWithComponents:@[ dir, @"indexes.sqlite" ]];

    id<CDTEncryptionKeyProvider> provider = [datastore encryptionKeyProvider];
    FMDatabaseQueue *database = nil;
    NSError *thisError = nil;
    BOOL success = YES;

    if (success) {
        database = [[FMDatabaseQueue alloc] initWithPath:filename];

        success = (database != nil);
        if (!success) {
            NSDictionary *userInfo = @{
                NSLocalizedDescriptionKey :
                    NSLocalizedString(@"Problem opening or creating database.", nil)
            };
            thisError = [NSError errorWithDomain:CDTQIndexManagerErrorDomain
                                            code:CDTQIndexErrorSqlError
                                        userInfo:userInfo];
        }
    }

    if (success) {
        success = [CDTQIndexManager configureDatabase:database
                            withEncryptionKeyProvider:provider
                                                error:&thisError];
    }

    if (success) {
        success = [CDTQIndexManager updateSchema:VERSION inDatabase:database];

        if (!success) {
            NSDictionary *userInfo = @{
                NSLocalizedDescriptionKey :
                    NSLocalizedString(@"Problem updating database schema.", nil)
            };
            thisError = [NSError errorWithDomain:CDTQIndexManagerErrorDomain
                                            code:CDTQIndexErrorSqlError
                                        userInfo:userInfo];
        }
    }
    
    if (!success) {
        database = nil;
        
        if (error) {
            *error = thisError;
        }
    }
    
    return database;
}

+ (BOOL)configureDatabase:(FMDatabaseQueue *)database
    withEncryptionKeyProvider:(id<CDTEncryptionKeyProvider>)provider
                        error:(NSError **)error
{
    __block BOOL success = YES;

    [database inDatabase:^(FMDatabase *db) {
      NSError *thisError = nil;
      success = [db setKeyWithProvider:provider error:&thisError];
      if (!success) {
          LogError(@"Problem configuring database with encryption key: %@", thisError);
      }
    }];

    if (!success && error) {
        NSDictionary *userInfo = @{
            NSLocalizedDescriptionKey :
                NSLocalizedString(@"Problem configuring database with encryption key", nil)
        };

        *error = [NSError errorWithDomain:CDTQIndexManagerErrorDomain
                                     code:CDTQIndexErrorEncryptionKeyError
                                 userInfo:userInfo];
    }

    return success;
}

+ (BOOL)updateSchema:(int)currentVersion inDatabase:(FMDatabaseQueue *)database
{
    __block BOOL success = YES;

    // get current version
    [database inTransaction:^(FMDatabase *db, BOOL *rollback) {
        int version = 0;

        FMResultSet *rs = [db executeQuery:@"pragma user_version;"];
        while ([rs next]) {
            version = [rs intForColumnIndex:0];
            break;  // should only be a single result, so may as well break
        }
        [rs close];

        if (version < 1) {
            success = [CDTQIndexManager migrate_0_1:db];
        }
        
        if (version < 2) {
            success = success && [CDTQIndexManager migrate_1_2:db];
        }

        // Set user_version unconditionally
        NSString *sql = [NSString stringWithFormat:@"pragma user_version = %d", currentVersion];
        success = success && [db executeUpdate:sql];

        if (!success) {
            LogError(@"Failed to update schema");
            *rollback = YES;
        }
    }];

    return success;
}

+ (BOOL)migrate_0_1:(FMDatabase *)db
{
    NSString *SCHEMA_INDEX = @"CREATE TABLE _t_cloudant_sync_query_metadata ( "
        @"        index_name TEXT NOT NULL, " @"        index_type TEXT NOT NULL, "
        @"        field_name TEXT NOT NULL, " @"        last_sequence INTEGER NOT NULL);";
    return [db executeUpdate:SCHEMA_INDEX];
}

+ (BOOL)migrate_1_2:(FMDatabase *)db
{
    NSString *SCHEMA_INDEX = @"ALTER TABLE _t_cloudant_sync_query_metadata "
                             @"        ADD COLUMN index_settings TEXT NULL;";
    return [db executeUpdate:SCHEMA_INDEX];
}

@end
