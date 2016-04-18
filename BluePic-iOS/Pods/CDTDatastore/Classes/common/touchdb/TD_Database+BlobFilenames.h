//
//  TD_Database+BlobFilenames.h
//  CloudantSync
//
//  Created by Enrique de la Torre Fernandez on 29/05/2015.
//  Copyright (c) 2015 IBM Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.
//

#import "TD_Database.h"

#import "TDBlobStore.h"

/** Name of the table that relates keys and filenames */
extern NSString *const TDDatabaseBlobFilenamesTableName;

/** First column / Primary key: key */
extern NSString *const TDDatabaseBlobFilenamesColumnKey;

/** Second column: filename */
extern NSString *const TDDatabaseBlobFilenamesColumnFilename;

/** File extension for attachments saved to disk */
extern NSString *const TDDatabaseBlobFilenamesFileExtension;

/**
 This is an utility class that defines all the required methods to create and interact with a table
 for relating keys and filenames.
 */
@interface TD_Database (BlobFilenames)

/**
 Execute the SQL command returned by this method to:
 - Create table TDDatabaseBlobFilenamesTableName
 - Generate an index for this table
 
 @return A SQL command
 */
+ (NSString *)sqlCommandToCreateBlobFilenamesTable;

/**
 This method:
 - Generate a filename as the hexadecimal representation of the provided key plus extension
 TDDatabaseBlobFilenamesFileExtension
 - Insert the filename with the key passed a parameter into TDDatabaseBlobFilenamesTableName
 
 @param key Key for the filename
 @param db Database with table TDDatabaseBlobFilenamesTableName
 
 @return A new filename or nil if there is an error
 */
+ (NSString *)generateAndInsertFilenameBasedOnKey:(TDBlobKey)key
                 intoBlobFilenamesTableInDatabase:(FMDatabase *)db;

/**
 This method:
 - Generate a filename as a random string and check that is not in use yet. The filename includes
 extension TDDatabaseBlobFilenamesFileExtension
 - Insert the filename with the key passed a parameter into TDDatabaseBlobFilenamesTableName
 
 @param key Key for the filename
 @param db Database with table TDDatabaseBlobFilenamesTableName
 
 @return A new filename or nil if there is an error
 */
+ (NSString *)generateAndInsertRandomFilenameBasedOnKey:(TDBlobKey)key
                       intoBlobFilenamesTableInDatabase:(FMDatabase *)db;

/**
 Count the number of rows/entries in the table TDDatabaseBlobFilenamesTableName
 
 @param db Database with table TDDatabaseBlobFilenamesTableName
 
 @return Number of rows in TDDatabaseBlobFilenamesTableName
 */
+ (NSUInteger)countRowsInBlobFilenamesTableInDatabase:(FMDatabase *)db;

/**
 Return an array with all the rows in table TDDatabaseBlobFilenamesTableName. Each row is
 represented with an instance of TD_DatabaseBlobFilenameRow.
 
 @param db Database with table TDDatabaseBlobFilenamesTableName
 
 @return Array with rows in TDDatabaseBlobFilenamesTableName
 
 @see TD_DatabaseBlobFilenameRow
 */
+ (NSArray *)rowsInBlobFilenamesTableInDatabase:(FMDatabase *)db;

/**
 Look for the filename related to the key passed as a parameter
 
 @param key Key for the filename we are lookin for
 @param db Database with table TDDatabaseBlobFilenamesTableName
 
 @return A filename or nil if the key is not found
 */
+ (NSString *)filenameForKey:(TDBlobKey)key inBlobFilenamesTableInDatabase:(FMDatabase *)db;

/**
 Insert a row in TDDatabaseBlobFilenamesTableName with the filename and key provided
 
 @param filename Filename to insert in database
 @param key Key to insert in database
 @param db Database with table TDDatabaseBlobFilenamesTableName
 
 @return YES if the a new row in inserted or NO if there is an error
 */
+ (BOOL)insertFilename:(NSString *)filename
                             withKey:(TDBlobKey)key
    intoBlobFilenamesTableInDatabase:(FMDatabase *)db;

/**
 Look for a row with a key equal to the key passed as a parameter and delete it.
 
 @param key Key for the row to delete
 @param db Database with table TDDatabaseBlobFilenamesTableName
 
 @return YES if a row is deleted or NO in other case
 */
+ (BOOL)deleteRowForKey:(TDBlobKey)key inBlobFilenamesTableInDatabase:(FMDatabase *)db;

@end

/**
 This is an auxiliary class only used by: 'TD_Database:rowsInBlobFilenamesTableInDatabase:'
 */
@interface TD_DatabaseBlobFilenameRow : NSObject

@property (assign, nonatomic, readonly) TDBlobKey key;
@property (strong, nonatomic, readonly) NSString *blobFilename;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithKey:(TDBlobKey)key
               blobFilename:(NSString *)blobFilename NS_DESIGNATED_INITIALIZER;

+ (instancetype)rowWithKey:(TDBlobKey)key blobFilename:(NSString *)blobFilename;

@end
