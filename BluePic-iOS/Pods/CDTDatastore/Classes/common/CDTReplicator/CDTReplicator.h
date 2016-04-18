//
//  CDTReplicator.h
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

#import <Foundation/Foundation.h>

#import "CDTReplicatorDelegate.h"

@class CDTDatastore;
@class TDReplicatorManager;
@class CDTAbstractReplication;

/**
 * Replicator errors.
 */
typedef NS_ENUM(NSInteger, CDTReplicatorErrors) {
    /**
     * CDTReplicator -start: was previously called
     */
    CDTReplicatorErrorAlreadyStarted = 1,
    /**
     Internal error: unable to create a new TDReplicator object
     */
    CDTReplicatorErrorTDReplicatorNil = 2,
    /**
     Internal error: TDReplicator object of wrong type.
     */
    CDTReplicatorErrorTDReplicatorWrongType = 3,
    /**
     Internal error: TDReplicator reports local database deleted
     */
    CDTReplicatorErrorLocalDatabaseDeleted = 4,
    /**
     Programming error: CDTReplicator was deallocated while replication was ongoing. 
     Retain a strong reference to the replicator until replication completes.
     */
    CDTReplicatorErrorDeallocatedWhileReplicating = 5
};

/**
 * Describes the state of a CDTReplicator at a given moment.

 @see CDTReplicator
 */
typedef NS_ENUM(NSInteger, CDTReplicatorState) {
    /**
     * The replicator is initialised and is ready to start.
     */
    CDTReplicatorStatePending,
    /**
     * A replication is in progress.
     */
    CDTReplicatorStateStarted,
    /**
     * The last replication was stopped using -stop
     */
    CDTReplicatorStateStopped,
    /**
     * -stop has been called and the replicator is being removed from the replication thread.
     */
    CDTReplicatorStateStopping,
    /**
     * The last replication successfully completed.
     */
    CDTReplicatorStateComplete,
    /**
     * The last replication completed in error.
     */
    CDTReplicatorStateError
};

/**
 A CDTReplicator instance represents a replication job.

 In CouchDB terms, it wraps a document in the `_replicator` database.

 Use CDTReplicatorFactory to create instances of this class.

 @see CDTReplicatorFactory
 */
@interface CDTReplicator : NSObject

/**---------------------------------------------------------------------------------------
 * @name Replication status
 *  --------------------------------------------------------------------------------------
 */

/**
 The current replication state.

 @see CDTReplicatorState
 */
@property (nonatomic, readonly) CDTReplicatorState state;

/**
 The number of changes from the source's `_changes` feed this
 replicator has processed.
 */
@property (nonatomic, readonly) NSInteger changesProcessed;

/** Total number of changes read so far from the source's `_changes`
 feed.

 Note that this will increase as the replication continues and
 further reads of the `_changes` feed happen.
 */
@property (nonatomic, readonly) NSInteger changesTotal;

/**
 * Set the replicator's delegate.
 *
 * This allows for more efficient tracking of replication state than polling.
 *
 * @see CDTReplicatorDelegate
 */
@property (nonatomic, weak) NSObject<CDTReplicatorDelegate> *delegate;

/**
 Returns true if the state is `CDTReplicatorStatePending`, `CDTReplicatorStateStarted` or
 `CDTReplicatorStateStopping`.

 @see CDTReplicatorState
 */
- (BOOL)isActive;

/**
 Returns a string representation of a CDTReplicatorState value.

 @param state state to return string representation
 */
+ (NSString *)stringForReplicatorState:(CDTReplicatorState)state;

/*
 Private so no docs
 */
-(id)initWithTDReplicatorManager:(TDReplicatorManager*)replicatorManager
                     replication:(CDTAbstractReplication*)replication
                           error:(NSError * __autoreleasing*)error;

/*
 Access the underlying NSThread execution state.
 See NSThread Class Reference
 
 These methods are private (no docs) and are used for testing. They may 
 be removed without warning.
 */
-(BOOL) threadExecuting;
-(BOOL) threadFinished;
-(BOOL) threadCanceled;

/**---------------------------------------------------------------------------------------
 * @name Controlling replication
 *  --------------------------------------------------------------------------------------
 */

/**
 * Starts a replication.
 *
 * The replication will continue until the replication is caught up with the source database;
 * that is, until there are no current changes to replicate.
 *
 * -startWithError can be called from any thread and will immediately return. It queues its work
 * on a separate replication thread. The methods on the CDTReplicatorDelegate
 * may be called from the background threads.
 *
 * A given CDTReplicator instance cannot be reused. Calling this method more than once will
 * return NO. Only when in `CDTReplicatorStatePending` will replication.
 *
 * @param error the error describing a failure.
 * @return YES or NO depending on success.
 *
 * @see CDTReplicatorState
 */
- (BOOL)startWithError:(NSError *__autoreleasing *)error;

/**
 * Stop an in-progress replication or attempt to stop a replication that has not yet started.
 *
 * Replications are queued on a separate thread. If the replication is already running,
 * this method, which can be called from any thread, is guaranteed to initiate the shutdown
 * process and will return YES immediately.
 *
 * Already replicated changes will remain in the datastore.
 *
 * The shutdown process may take time as we need to wait for in-flight
 * network requests to complete before background threads can be safely
 * stopped.
 *
 * Consumers should check -state if they need
 * to know when the replicator has fully stopped. After -stop is
 * called, the replicator will be in the `CDTReplicatorStateStopping`
 * state while operations complete and will move to the
 * `CDTReplicatorStateStopped` state when the replicator has fully
 * shutdown. The delegate will be informed for these changes in state
 * via -replicatorDidChangeState.
 *
 * It is also possible the replicator moves to the
 * `CDTReplicatorStateError` state if an error happened during the
 * shutdown process.
 *
 * If the replication has not yet begun on the separate thread, this method will attempt
 * to stop the replication before it starts. If it cannot stop the replication, this method
 * will return NO and replication will start and progress as normal.
 *
 * If -startWithError was never called, this method will move the state from
 * CDTRelicatorStatePending to CDTReplicatorStateStopped, inform the delegate and return YES.
 *
 *
 * @return YES or NO depending on success.
 *
 *
 * @see CDTReplicatorState
 */
- (BOOL)stop;

/**
 If -state is equal to CDTReplicatorStateError, this will contain the error message.
 This error information is also sent to the delegate object.
 */
@property (nonatomic, readonly) NSError *error;

@end
