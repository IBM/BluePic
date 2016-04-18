//
//  CSDatastoreManager.m
//  CloudantSyncLib
//
//  Created by Michael Rhodes on 04/07/2013.
//  Copyright (c) 2013 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "CDTDatastoreManager.h"
#import "CDTDatastore+EncryptionKey.h"

#import "CDTEncryptionKeyNilProvider.h"

#import "TD_DatabaseManager.h"
#import "TD_Database.h"

NSString *const CDTDatastoreErrorDomain = @"CDTDatastoreErrorDomain";
NSString *const CDTExtensionsDirName = @"_extensions";

@interface CDTDatastoreManager ()

@end

@implementation CDTDatastoreManager

- (id)initWithDirectory:(NSString *)directoryPath error:(NSError **)outError
{
    self = [super init];
    if (self) {
        _manager =
            [[TD_DatabaseManager alloc] initWithDirectory:directoryPath options:nil error:outError];
        if (!_manager) {
            self = nil;
        }
    }

    return self;
}

- (CDTDatastore *)datastoreNamed:(NSString *)name error:(NSError *__autoreleasing *)error
{
    CDTEncryptionKeyNilProvider *provider = [CDTEncryptionKeyNilProvider provider];

    return [self datastoreNamed:name withEncryptionKeyProvider:provider error:error];
}

- (CDTDatastore *)datastoreNamed:(NSString *)name
       withEncryptionKeyProvider:(id<CDTEncryptionKeyProvider>)provider
                           error:(NSError *__autoreleasing *)error
{
    //    if (![TD_Database isValidDatabaseName:name]) {
    //      Not a public method yet
    //    }

    CDTDatastore *datastore = nil;

    NSString *errorReason = nil;
    TD_Database *db = [self.manager databaseNamed:name];
    if (db) {
        datastore = [[CDTDatastore alloc] initWithManager:self database:db encryptionKeyProvider:provider];

        if (!datastore) {
            errorReason = NSLocalizedString(@"Wrong key?", nil);
        }
    } else {
        errorReason = NSLocalizedString(@"Invalid name?", nil);
    }

    if (!datastore && error) {
        NSDictionary *userInfo = @{
            NSLocalizedDescriptionKey : NSLocalizedString(@"Couldn't create database.", nil),
            NSLocalizedFailureReasonErrorKey : errorReason,
            NSLocalizedRecoverySuggestionErrorKey : errorReason
        };
        *error = [NSError errorWithDomain:CDTDatastoreErrorDomain code:400 userInfo:userInfo];
    }

    return datastore;
}

- (BOOL)deleteDatastoreNamed:(NSString *)name error:(NSError *__autoreleasing *)error
{
    // first delete the SQLite database and any attachments
    NSError *localError = nil;
    BOOL success = [self.manager deleteDatabaseNamed:name error:&localError];
    if (!success && error) {
        if ([localError.domain isEqualToString:kTD_DatabaseManagerErrorDomain] &&
            (localError.code == kTD_DatabaseManagerErrorCodeInvalidName)) {
            localError = [NSError errorWithDomain:CDTDatastoreErrorDomain
                                             code:404
                                         userInfo:localError.userInfo];
        }
        
        *error = localError;
    }
    
    if (success) {
        // delete any cloudant extensions
        NSString *dbPath = [self.manager pathForName:name];;
        NSString *extPath = [dbPath stringByDeletingLastPathComponent];
        extPath = [extPath
                   stringByAppendingPathComponent:[name stringByAppendingString:CDTExtensionsDirName]];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        
        BOOL isDirectory;
        BOOL extenstionsExists = [fm fileExistsAtPath:extPath isDirectory:&isDirectory];
        if (extenstionsExists && isDirectory) {
            success = [fm removeItemAtPath:extPath error:&localError];
            if (!success && error) {
                *error = localError;
            }
        }
    }
    
    return success;
}

- (NSArray* /* NSString */) allDatastores
{
    return [self.manager allDatabaseNames];
}

@end
