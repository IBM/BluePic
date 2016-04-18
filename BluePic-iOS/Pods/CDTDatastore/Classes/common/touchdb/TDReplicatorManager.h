//
//  TDReplicatorManager.h
//  TouchDB
//
//  Created by Jens Alfke on 2/15/12.
//  Copyright (c) 2012 Couchbase, Inc. All rights reserved.
//
//  Modifications for this distribution by Cloudant, Inc., Copyright (c) 2014 Cloudant, Inc.
//

#import "TD_Database.h"
@class TD_DatabaseManager;
@class TDReplicator;
@protocol TDAuthorizer;

/** Manages the creation of TDReplicator objects -- this is now just a factory for TDReplicators.
 */
@interface TDReplicatorManager : NSObject
{
    TD_DatabaseManager* _dbManager;
}
@property (nonatomic, strong, readonly) NSMutableArray *replicators;

- (id)initWithDatabaseManager:(TD_DatabaseManager*)dbManager;


- (TDReplicator* ) createReplicatorWithProperties:(NSDictionary*) properties
                                            error:(NSError *__autoreleasing*)error;



@end
