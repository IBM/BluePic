//
//  CDTReplicator.m
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

#import "CDTReplicator.h"

#import "CDTReplicatorFactory.h"
#import "CDTDocumentRevision.h"
#import "CDTPullReplication.h"
#import "CDTPushReplication.h"
#import "CDTLogging.h"

#import "TD_Revision.h"
#import "TD_Database.h"
#import "TD_Body.h"
#import "TDPusher.h"
#import "TDPuller.h"
#import "TDReplicatorManager.h"
#import "TDStatus.h"

const NSString *CDTReplicatorLog = @"CDTReplicator";
static NSString *const CDTReplicatorErrorDomain = @"CDTReplicatorErrorDomain";

@interface CDTReplicator ()

@property (nonatomic, strong) TDReplicatorManager *replicatorManager;
@property (nonatomic, strong) TDReplicator *tdReplicator;
@property (nonatomic, copy) CDTAbstractReplication *cdtReplication;
@property (nonatomic, strong) NSDictionary *replConfig;
// private readwrite properties
// the state property should be protected from multiple threads
@property (nonatomic, readwrite) CDTReplicatorState state;
@property (nonatomic, readwrite) NSInteger changesProcessed;
@property (nonatomic, readwrite) NSInteger changesTotal;
@property (nonatomic, readwrite) NSError *error;

@property (nonatomic, copy) CDTFilterBlock pushFilter;
@property (nonatomic) BOOL started;

@end

@implementation CDTReplicator

+ (NSString *)stringForReplicatorState:(CDTReplicatorState)state
{
    switch (state) {
        case CDTReplicatorStatePending:
            return @"CDTReplicatorStatePending";
        case CDTReplicatorStateStarted:
            return @"CDTReplicatorStateStarted";
        case CDTReplicatorStateStopped:
            return @"CDTReplicatorStateStopped";
        case CDTReplicatorStateStopping:
            return @"CDTReplicatorStateStopping";
        case CDTReplicatorStateComplete:
            return @"CDTReplicatorStateComplete";
        case CDTReplicatorStateError:
            return @"CDTReplicatorStateError";
    }
}

#pragma mark Initialise

- (id)initWithTDReplicatorManager:(TDReplicatorManager *)replicatorManager
                      replication:(CDTAbstractReplication *)replication
                            error:(NSError *__autoreleasing *)error
{
    if (replicatorManager == nil || replication == nil) {
        return nil;
    }

    self = [super init];
    if (self) {
        _replicatorManager = replicatorManager;
        _cdtReplication = [replication copy];

        NSError *localError;
        _replConfig = [_cdtReplication dictionaryForReplicatorDocument:&localError];
        if (!_replConfig) {
            if (error) *error = localError;
            return nil;
        }

        _state = CDTReplicatorStatePending;
        _started = NO;
    }
    return self;
}

- (void)dealloc
{
    if (self.tdReplicator.running) {
        //we are being deallocated while replication is still happening
        //report error
        NSError *deallocError;
        
        NSString *message = [NSString stringWithFormat: @"Object deallocated before completed "
                             @"replication. Keep a strong reference to the replicator object to "
                             @"avoid this.\n %@", self];
        
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey :
                                       NSLocalizedString(message, nil)
                                   };
        deallocError = [NSError errorWithDomain:CDTReplicatorErrorDomain
                                           code:CDTReplicatorErrorDeallocatedWhileReplicating
                                       userInfo:userInfo];
        //send nil to replicatorDidError since we're half-way through deallocation.
        [self.delegate replicatorDidError:nil info:deallocError];
        
        CDTLogWarn(CDTREPLICATION_LOG_CONTEXT, @"%@", message);
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString*) description
{
    NSString *replicationType;
    NSString *source;
    NSString *target;
    
    if ( self.tdReplicator.isPush ) {
        replicationType = @"push" ;
        source = self.tdReplicator.db.name;
        target = TDCleanURLtoString(self.tdReplicator.remote);
        
    }
    else {
        replicationType = @"pull" ;
        source = TDCleanURLtoString(self.tdReplicator.remote);
        target = self.tdReplicator.db.name;
    }
    
    NSString *fullinfo = [NSString stringWithFormat: @"CDTReplicator %@, source: %@, target: %@ "
                          @"filter name: %@, filter parameters %@, unique replication session "
                          @"ID: %@", replicationType, source, target, self.tdReplicator.filterName,
                          self.tdReplicator.filterParameters, self.tdReplicator.sessionID];
    
    return fullinfo;
}


#pragma mark Lifecycle

- (BOOL)startWithError:(NSError *__autoreleasing *)error;
{
    @synchronized(self)
    {
        // check both self.started and self.state. While unlikely, it is possible for -stop to
        // be called before -startWithError. If -stop is called first on a particular instance,
        // the resulting state will 'stopped' and the object can no longer be started at that point.
        if (self.started || self.state != CDTReplicatorStatePending) {
            CDTLogInfo(CDTREPLICATION_LOG_CONTEXT,
                       @"-startWithError: CDTReplicator can only be started "
                       @"once and only from its initial state, CDTReplicatorStatePending. "
                       @"Current State: %@",
                       [CDTReplicator stringForReplicatorState:self.state]);

            if (error) {
                NSDictionary *userInfo = @{
                    NSLocalizedDescriptionKey : NSLocalizedString(@"Data sync failed.", nil)
                };
                *error = [NSError errorWithDomain:CDTReplicatorErrorDomain
                                             code:CDTReplicatorErrorAlreadyStarted
                                         userInfo:userInfo];
            }
            // do not change self.state or set self.error here. This is a non-fatal error since
            // the caller has previously called -startWithError.

            return NO;
        }

        self.started = YES;

        // doing this inside @synchronized lets us be certain that self.tdReplicator is either
        // created or nil throughout the rest of the code (especially in -stop)
        NSError *localError;
        self.tdReplicator = [self.replicatorManager createReplicatorWithProperties:self.replConfig
                                                                             error:&localError];

        if (!self.tdReplicator) {
            self.state = CDTReplicatorStateError;

            // report the error to the Log
            CDTLogWarn(CDTREPLICATION_LOG_CONTEXT, @"CDTReplicator -start: Unable to instantiate "
                       @"TDReplicator. TD Error: %@ Current State: %@",
                       localError, [CDTReplicator stringForReplicatorState:self.state]);

            if (error) {
                // build a CDT error
                NSDictionary *userInfo = @{
                    NSLocalizedDescriptionKey : NSLocalizedString(@"Data sync failed.", nil)
                };
                *error = [NSError errorWithDomain:CDTReplicatorErrorDomain
                                             code:CDTReplicatorErrorTDReplicatorNil
                                         userInfo:userInfo];
            }
            return NO;
        }
    }

    // create TD_FilterBlock that wraps the CDTFilterBlock and set the TDPusher.filter property.
    if ([self.cdtReplication isKindOfClass:[CDTPushReplication class]]) {
        CDTPushReplication *pushRep = (CDTPushReplication *)self.cdtReplication;
        if (pushRep.filter) {
            TDPusher *tdpusher = (TDPusher *)self.tdReplicator;
            CDTFilterBlock cdtfilter = [pushRep.filter copy];

            tdpusher.filter = ^(TD_Revision *rev, NSDictionary *params) {
                return cdtfilter([[CDTDocumentRevision alloc] initWithDocId:rev.docID
                                                                 revisionId:rev.revID
                                                                       body:rev.body.properties
                                                                    deleted:rev.deleted
                                                                attachments:@{}
                                                                   sequence:rev.sequence],
                                 params);
            };
        }
    }

    self.changesTotal = self.changesProcessed = 0;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(replicatorStopped:)
                                                 name:TDReplicatorStoppedNotification
                                               object:self.tdReplicator];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(replicatorProgressChanged:)
                                                 name:TDReplicatorProgressChangedNotification
                                               object:self.tdReplicator];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(replicatorStarted:)
                                                 name:TDReplicatorStartedNotification
                                               object:self.tdReplicator];

    [self.tdReplicator start];
    
    CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"start: Replicator starting %@, sessionID %@",
          [self.tdReplicator class], self.tdReplicator.sessionID);

    return YES;
}

- (BOOL)stop
{
    CDTReplicatorState oldstate = self.state;
    BOOL informDelegate = YES;
    BOOL stopSuccessful = YES;

    @synchronized(self)
    {
        // can only stop once. If state == 'stopped', 'stopping', 'complete', or 'error'
        // then -stop has either already been called, or the replicator stopped due to
        // completion or error. This is the default case below.

        switch (self.state) {
            case CDTReplicatorStatePending:

                if (self.started) {
                    //-startWithError was called and self.tdReplicator was successfully
                    //instantiated (otherwise state == 'error')
                    if ([self.tdReplicator cancelIfNotStarted]) {
                        self.state = CDTReplicatorStateStopped;
                    } else {
                        stopSuccessful = NO;
                    }
                } else {
                    self.state = CDTReplicatorStateStopped;
                }
                break;

            case CDTReplicatorStateStarted:
                self.state = CDTReplicatorStateStopping;
                break;

            // we've already stopped or are about to.
            case CDTReplicatorStateStopped:
            case CDTReplicatorStateStopping:
            case CDTReplicatorStateComplete:
            case CDTReplicatorStateError:
                informDelegate = NO;
                break;
        }
    }

    if (informDelegate) {
        [self recordProgressAndInformDelegateFromOldState:oldstate];
    }

    if (oldstate == CDTReplicatorStateStarted && self.state == CDTReplicatorStateStopping) {
        // self.tdReplicator -stop eventually notifies self.replicatorStopped.
        [self.tdReplicator stop];
    }

    return stopSuccessful;
}

#pragma mark Methods that may be called by TD_Replicator notifications

// Notified that a TDReplicator has stopped:
- (void)replicatorStopped:(NSNotification *)n
{
    // As NSNotificationCenter only has weak references, it appears possible
    // for this instance to be deallocated during the call if we don't take
    // a strong reference.
    CDTReplicator *strongSelf = self;
    if (!strongSelf) {
        return;
    }

    TDReplicator *repl = n.object;

    CDTLogInfo(CDTREPLICATION_LOG_CONTEXT,
               @"replicatorStopped: %@. type: %@ sessionId: %@ CDTstate: %@", n.name, [repl class],
               repl.sessionID, [CDTReplicator stringForReplicatorState:self.state]);

    CDTReplicatorState oldState = strongSelf.state;

    @synchronized(strongSelf)
    {  // lock out other processes from changing state
        switch (strongSelf.state) {
            case CDTReplicatorStatePending:
            case CDTReplicatorStateStopping:

                if (strongSelf.tdReplicator.error) {
                    strongSelf.state = CDTReplicatorStateError;
                } else {
                    strongSelf.state = CDTReplicatorStateStopped;
                }

                break;

            case CDTReplicatorStateStarted:

                if (strongSelf.tdReplicator.error) {
                    strongSelf.state = CDTReplicatorStateError;
                } else {
                    strongSelf.state = CDTReplicatorStateComplete;
                }

            // do nothing if the state is already 'complete' or 'error'.
            default:
                break;
        }
    }

    [strongSelf recordProgressAndInformDelegateFromOldState:oldState];

    [[NSNotificationCenter defaultCenter] removeObserver:strongSelf
                                                    name:nil
                                                  object:strongSelf.tdReplicator];
}

// Notified that a TDReplicator has started:
- (void)replicatorStarted:(NSNotification *)n
{
    // As NSNotificationCenter only has weak references, it appears possible
    // for this instance to be deallocated during the call if we don't take
    // a strong reference.
    CDTReplicator *strongSelf = self;
    if (!strongSelf) {
        return;
    }

    TDReplicator *repl = n.object;

    CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"replicatorStarted: %@ type: %@ sessionId: %@", n.name,
               [repl class], repl.sessionID);

    CDTReplicatorState oldState = strongSelf.state;
    @synchronized(strongSelf) {  // lock out other processes from changing state. strongSelf.state = CDTReplicatorStateStarted; }

        id<CDTReplicatorDelegate> delegate = strongSelf.delegate;

        BOOL stateChanged = (oldState != strongSelf.state);
        if (stateChanged && [delegate respondsToSelector:@selector(replicatorDidChangeState:)]) {
            [delegate replicatorDidChangeState:strongSelf];
        }
    }
}

/*
 * Called when progress has been reported by the TDReplicator.
 */
- (void)replicatorProgressChanged:(NSNotification *)n
{
    // As NSNotificationCenter only has weak references, it appears possible
    // for this instance to be deallocated during the call if we don't take
    // a strong reference.
    CDTReplicator *strongSelf = self;
    if (!strongSelf) {
        return;
    }

    CDTReplicatorState oldState = strongSelf.state;

    @synchronized(strongSelf)
    {
        if (strongSelf.tdReplicator.running)
            strongSelf.state = CDTReplicatorStateStarted;
        else if (self.tdReplicator.error)
            strongSelf.state = CDTReplicatorStateError;
        else
            strongSelf.state = CDTReplicatorStateComplete;
    }

    [strongSelf recordProgressAndInformDelegateFromOldState:oldState];
}

#pragma mark Internal methods

- (void)recordProgressAndInformDelegateFromOldState:(CDTReplicatorState)oldState
{
    BOOL progressChanged = [self updateProgress];
    BOOL stateChanged = (oldState != self.state);

    // Lots of possible delegate messages at this point
    id<CDTReplicatorDelegate> delegate = self.delegate;

    if (progressChanged && [delegate respondsToSelector:@selector(replicatorDidChangeProgress:)]) {
        [delegate replicatorDidChangeProgress:self];
    }

    if (stateChanged && [delegate respondsToSelector:@selector(replicatorDidChangeState:)]) {
        [delegate replicatorDidChangeState:self];
    }

    // We're completing this time if we're transitioning from an active state into an inactive
    // non-error state.
    BOOL completingTransition = (stateChanged && self.state != CDTReplicatorStateError &&
                                 [self isActiveState:oldState] && ![self isActiveState:self.state]);
    if (completingTransition && [delegate respondsToSelector:@selector(replicatorDidComplete:)]) {
        [delegate replicatorDidComplete:self];
    }

    // We've errored if we're transitioning from an active state into an error state.
    BOOL erroringTransition =
        (stateChanged && self.state == CDTReplicatorStateError && [self isActiveState:oldState]);
    if (erroringTransition && [delegate respondsToSelector:@selector(replicatorDidError:info:)]) {
        [delegate replicatorDidError:self info:self.error];
    }
}

- (BOOL)updateProgress
{
    BOOL progressChanged = NO;
    if (self.changesProcessed != self.tdReplicator.changesProcessed ||
        self.changesTotal != self.tdReplicator.changesTotal) {
        self.changesProcessed = self.tdReplicator.changesProcessed;
        self.changesTotal = self.tdReplicator.changesTotal;
        progressChanged = YES;
    }
    return progressChanged;
}

#pragma mark Status information

- (BOOL)isActive { return [self isActiveState:self.state]; }

/*
 * Returns whether `state` is an active state for the replicator.
 */
- (BOOL)isActiveState:(CDTReplicatorState)state
{
    return state == CDTReplicatorStatePending || state == CDTReplicatorStateStarted ||
           state == CDTReplicatorStateStopping;
}

- (NSError *)error
{
    // this protects against reporting an error if the replication is still ongoing.
    // according to the TDReplicator documentation, it is possible for TDReplicator to encounter
    // a non-fatal error, which we do not want to report unless the replicator gives up and quits.
    if ([self isActive]) {
        return nil;
    }

    if (!_error && self.tdReplicator.error) {
        // convert TD-level replication errors to CDT level
        NSDictionary *userInfo;

        if ([self.tdReplicator.error.domain isEqualToString:TDInternalErrorDomain]) {
            switch (self.tdReplicator.error.code) {
                
                case TDReplicatorErrorLocalDatabaseDeleted:
                    userInfo =
                    @{NSLocalizedDescriptionKey: NSLocalizedString(@"Data sync failed.", nil)};
                    self.error = [NSError errorWithDomain:CDTReplicatorErrorDomain
                                                     code:CDTReplicatorErrorLocalDatabaseDeleted
                                                 userInfo:userInfo];
                    break;

                default:
                    // just point directly to tdReplicator error if we don't have a conversion
                    self.error = self.tdReplicator.error;
                    break;
            }

        } else {
            self.error = self.tdReplicator.error;
        }
    }

    return _error;
}


-(BOOL) threadExecuting;
{
    return self.tdReplicator.threadExecuting;
}
-(BOOL) threadFinished
{
    return self.tdReplicator.threadFinished;
}
-(BOOL) threadCanceled
{
    return self.tdReplicator.threadCanceled;
}

@end
