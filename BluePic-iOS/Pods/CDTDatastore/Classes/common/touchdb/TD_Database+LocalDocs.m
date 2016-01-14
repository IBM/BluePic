//
//  TD_Database+LocalDocs.m
//  TouchDB
//
//  Created by Jens Alfke on 1/10/12.
//  Copyright (c) 2012 Couchbase, Inc. All rights reserved.
//
//  Modifications for this distribution by Cloudant, Inc., Copyright (c) 2014 Cloudant, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "TD_Database+LocalDocs.h"
#import "TD_Revision.h"
#import "TD_Body.h"
#import "TDInternal.h"
#import "TDJSON.h"

#import <FMDB/FMDatabase.h>
#import <FMDB/FMDatabaseQueue.h>

@implementation TD_Database (LocalDocs)

- (TD_Revision *)getLocalDocumentWithID:(NSString *)docID revisionID:(NSString *)revID
{
    __block TD_Revision *result;
    [_fmdbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *r =
            [db executeQuery:@"SELECT revid, json FROM localdocs WHERE docid=?", docID];
        if ([r next]) {
            NSString *gotRevID = [r stringForColumnIndex:0];
            if (revID && !$equal(revID, gotRevID)) {
                return;
            }
            NSData *json = [r dataNoCopyForColumnIndex:1];
            NSMutableDictionary *properties;
            if (json.length == 0 || (json.length == 2 && memcmp(json.bytes, "{}", 2) == 0)) {
                properties = $mdict();  // workaround for issue #44
            } else {
                properties = [TDJSON JSONObjectWithData:json
                                                options:TDJSONReadingMutableContainers
                                                  error:NULL];
                if (!properties) {
                    return;
                }
            }
            properties[@"_id"] = docID;
            properties[@"_rev"] = gotRevID;
            result = [[TD_Revision alloc] initWithDocID:docID revID:gotRevID deleted:NO];
            result.properties = properties;
        }
        [r close];
    }];
    return result;
}

- (TD_Revision *)putLocalRevision:(TD_Revision *)revision
                   prevRevisionID:(NSString *)prevRevID
                           status:(TDStatus *)outStatus
{
    NSString *docID = revision.docID;
    if (![docID hasPrefix:@"_local/"]) {
        *outStatus = kTDStatusBadID;
        return nil;
    }
    if (!revision.deleted) {
        // PUT:
        NSData *json = [self encodeDocumentJSON:revision];
        __block TD_Revision *result;
        [_fmdbQueue inDatabase:^(FMDatabase *db) {
            NSString *newRevID;
            if (prevRevID) {
                unsigned generation = [TD_Revision generationFromRevID:prevRevID];
                if (generation == 0) {
                    *outStatus = kTDStatusBadID;
                    return;
                }
                newRevID = $sprintf(@"%d-local", ++generation);
                if (![db executeUpdate:@"UPDATE localdocs SET revid=?, json=? "
                                        "WHERE docid=? AND revid=?",
                                       newRevID, json, docID, prevRevID]) {
                    *outStatus = kTDStatusDBError;
                    return;
                }
            } else {
                newRevID = @"1-local";
                // The docid column is unique so the insert will be a no-op if there is already
                // a doc with this ID.
                if (![db executeUpdate:@"INSERT OR IGNORE INTO localdocs (docid, revid, json) "
                                        "VALUES (?, ?, ?)",
                                       docID, newRevID, json]) {
                    *outStatus = kTDStatusDBError;
                    return;
                }
            }
            if (db.changes == 0) {
                *outStatus = kTDStatusConflict;
                return;
            }
            *outStatus = kTDStatusCreated;
            result = [revision copyWithDocID:docID revID:newRevID];
        }];

        return result;
    } else {
        // DELETE:
        *outStatus = [self deleteLocalDocumentWithID:docID revisionID:prevRevID];
        return *outStatus < 300 ? revision : nil;
    }
}

- (TDStatus)deleteLocalDocumentWithID:(NSString *)docID revisionID:(NSString *)revID
{
    if (!docID) return kTDStatusBadID;
    if (!revID) {
        // Didn't specify a revision to delete: kTDStatusNotFound or a kTDStatusConflict, depending
        return [self getLocalDocumentWithID:docID revisionID:nil] ? kTDStatusConflict
                                                                  : kTDStatusNotFound;
    }

    __block TDStatus result = kTDStatusOK;
    __block bool delete_successful = NO;
    [_fmdbQueue inDatabase:^(FMDatabase *db) {

        if (![db executeUpdate:@"DELETE FROM localdocs WHERE docid=? AND revid=?", docID, revID]) {
            result = kTDStatusDBError;
            return;
        }

        delete_successful = (db.changes > 0);
    }];

    if (!delete_successful) {
        return [self getLocalDocumentWithID:docID revisionID:nil] ? kTDStatusConflict
                                                                  : kTDStatusNotFound;
    }

    return result;
}

@end
