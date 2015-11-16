//
//  TD_DatabaseManager.h
//  TouchDB
//
//  Created by Jens Alfke on 3/22/12.
//  Copyright (c) 2012 Couchbase, Inc. All rights reserved.
//
//  Modifications for this distribution by Cloudant, Inc., Copyright(c) 2014 Cloudant, Inc.

#import <Foundation/Foundation.h>
#import "TDStatus.h"

@class TD_Database, TDReplicator;
//@class TDReplicatorManager;

typedef struct TD_DatabaseManagerOptions
{
    bool readOnly;
    bool noReplicator;
} TD_DatabaseManagerOptions;

extern const TD_DatabaseManagerOptions kTD_DatabaseManagerDefaultOptions;

extern NSString *const kTD_DatabaseManagerErrorDomain;
extern NSUInteger const kTD_DatabaseManagerErrorCodeInvalidName;

/** Manages a directory containing TD_Databases. */
@interface TD_DatabaseManager : NSObject {
   @private
    NSString* _dir;
    TD_DatabaseManagerOptions _options;
    NSMutableDictionary* _databases;
}

+ (BOOL)isValidDatabaseName:(NSString*)name;
- (NSString*)pathForName:(NSString*)name;

- (id)initWithDirectory:(NSString*)dirPath
                options:(const TD_DatabaseManagerOptions*)options
                  error:(NSError**)outError;

@property (readonly) NSString* directory;

/**
 * Returns a database:
 * - If the database is cached, it will return this database. The database may or may not be open.
 * - If it is not cached, it will create a new instance. The database is closed and it is based on
 * the content saved to disk (if there is any)
 * - It will no create an instance if the database is for read-only and there is not previous data
 * on disk
 *
 * param name name of the database. This name is used to compose the filename of the database
 *
 * return a database or nil if it is not possible to create a new instance
 */
- (TD_Database*)databaseNamed:(NSString*)name;

/**
 * Returns a database that was previously allocated with 'databaseNamed:'.
 * Be aware that the database may or may not be open.
 */
- (TD_Database*)cachedDatabaseNamed:(NSString*)name;

- (BOOL)deleteDatabaseNamed:(NSString*)name error:(NSError *__autoreleasing *)error;

@property (readonly) NSArray* allDatabaseNames;
@property (readonly) NSArray* allOpenDatabases;

- (void)close;

- (TDStatus)validateReplicatorProperties:(NSDictionary*)properties;
- (TDReplicator*)replicatorWithProperties:(NSDictionary*)body status:(TDStatus*)outStatus;

#if DEBUG  // made public for testing (Adam Cox, Cloudant. 2014-1-20)
+ (TD_DatabaseManager*)createEmptyAtPath:(NSString*)path;
+ (TD_DatabaseManager*)createEmptyAtTemporaryPath:(NSString*)name;
#endif

@end
