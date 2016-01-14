//
//  TD_Database+Conflicts
//
//
//  Created by G. Adam Cox on 13/03/2014.
//  Copyright (c) 2014 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "TD_Database+Conflicts.h"
#import <FMDB/FMDatabase.h>
#import <FMDB/FMResultSet.h>
#import <FMDB/FMDatabaseQueue.h>

@implementation TD_Database (Conflicts)

/** Only call from within a queued transaction **/
- (NSArray *)getConflictedDocumentIdsWithDatabase:(FMDatabase *)db
{
    NSString *sql = @"SELECT docs.docid, COUNT(*) " @"FROM docs,revs "
        @"WHERE revs.doc_id = docs.doc_id AND deleted = 0 " @"AND revs.sequence NOT IN "
        @"(SELECT DISTINCT parent FROM revs " @"WHERE parent NOT NULL) "
        @"GROUP BY docs.docid HAVING COUNT(*) > 1";
    FMResultSet *r = [db executeQuery:sql];
    if (!r) return nil;
    NSMutableArray *docs = [[NSMutableArray alloc] init];
    while ([r next]) {
        [docs addObject:[r stringForColumn:@"docid"]];
    }
    [r close];
    return docs;
}

- (NSArray *)getConflictedDocumentIds
{
    __block NSArray *result;
    __weak TD_Database *weakSelf = self;
    [_fmdbQueue inDatabase:^(FMDatabase *db) {
        TD_Database *strongSelf = weakSelf;
        result = [strongSelf getConflictedDocumentIdsWithDatabase:db];
    }];
    return result;
}

@end
