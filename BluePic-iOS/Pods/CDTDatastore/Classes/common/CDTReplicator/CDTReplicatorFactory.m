//
//  CDTReplicatorFactory.m
//
//
//  Created by Michael Rhodes on 10/12/2013.
//  Copyright (c) 2013 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "CDTReplicatorFactory.h"

#import "CDTDatastoreManager.h"
#import "CDTDatastore.h"
#import "CDTReplicator.h"
#import "CDTAbstractReplication.h"
#import "CDTPullReplication.h"
#import "CDTPushReplication.h"
#import "CDTDocumentRevision.h"
#import "CDTLogging.h"

#import "TDReplicatorManager.h"

static NSString *const CDTReplicatorFactoryErrorDomain = @"CDTReplicatorFactoryErrorDomain";

@interface CDTReplicatorFactory ()

@property (nonatomic, strong) CDTDatastoreManager *manager;

@property (nonatomic, strong) TDReplicatorManager *replicatorManager;

@end

@implementation CDTReplicatorFactory

#pragma mark Manage our TDReplicatorManager instance

- (id)initWithDatastoreManager:(CDTDatastoreManager *)dsManager
{
    self = [super init];
    if (self) {
        
        if(dsManager){
            _manager = dsManager;
            TD_DatabaseManager *dbManager = dsManager.manager;
            _replicatorManager = [[TDReplicatorManager alloc] initWithDatabaseManager:dbManager];
        } else {
            self = nil;
            CDTLogWarn(CDTREPLICATION_LOG_CONTEXT,
                       @"Datastore manager is nil, there isn't a local datastore to replicate with.");
        }
    }
    return self;
}


#pragma mark CDTReplicatorFactory interface methods

- (CDTReplicator *)onewaySourceDatastore:(CDTDatastore *)source targetURI:(NSURL *)target
{
    CDTPushReplication *push = [CDTPushReplication replicationWithSource:source target:target];

    return [self oneWay:push error:nil];
}

- (CDTReplicator *)onewaySourceURI:(NSURL *)source targetDatastore:(CDTDatastore *)target
{
    CDTPullReplication *pull = [CDTPullReplication replicationWithSource:source target:target];

    return [self oneWay:pull error:nil];
}

- (CDTReplicator *)oneWay:(CDTAbstractReplication *)replication
                    error:(NSError *__autoreleasing *)error
{
    NSError *localError;
    CDTReplicator *replicator =
        [[CDTReplicator alloc] initWithTDReplicatorManager:self.replicatorManager
                                               replication:replication
                                                     error:&localError];

    if (replicator == nil) {
        CDTLogWarn(CDTREPLICATION_LOG_CONTEXT,
                @"CDTReplicatorFactory -oneWay:error: Error. Unable to create CDTReplicator. "
                @"%@\n %@",
                [replication class], replication);

        if (error) {
            *error = localError;
        }

        return nil;
    }

    return replicator;
}

@end
