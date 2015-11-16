//
//  TDReplicatorManager.m
//  TouchDB
//
//  Created by Jens Alfke on 2/15/12.
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
//
//  http://wiki.apache.org/couchdb/Replication#Replicator_database
//  http://www.couchbase.com/docs/couchdb-release-1.1/index.html

#import "TDReplicatorManager.h"
#import "TD_Database.h"
#import "TD_Database+Insertion.h"
#import "TD_Database+Replication.h"
#import "TDPusher.h"
#import "TDPuller.h"
#import "TD_View.h"
#import "TDInternal.h"
#import "TDMisc.h"
#import "MYBlockUtils.h"
#import "CDTLogging.h"
#import "TDStatus.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIApplication.h>
#endif

@implementation TDReplicatorManager

- (id) initWithDatabaseManager: (TD_DatabaseManager*)dbManager {
    self = [super init];
    if (self) {
        _dbManager = dbManager;
    }
    return self;
}


- (TDReplicator* ) createReplicatorWithProperties:(NSDictionary*) properties
                                            error:(NSError *__autoreleasing*)error
{
    TDStatus outStatus;
    TDReplicator *repl = [_dbManager replicatorWithProperties:properties status:&outStatus];

    if (!repl) {
        if (error) {
            *error = TDStatusToNSError(outStatus, nil);
        }
        CDTLogWarn(CDTREPLICATION_LOG_CONTEXT, @"ReplicatorManager: Can't create replicator for %@",
                properties);
        return nil;
    }
    repl.sessionID = TDCreateUUID();
        
    return repl;
}

@end
