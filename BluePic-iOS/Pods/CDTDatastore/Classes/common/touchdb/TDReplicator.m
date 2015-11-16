//
//  TDReplicator.m
//  TouchDB
//
//  Created by Jens Alfke on 12/6/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
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

#import "TDReplicator.h"
#import "TDPusher.h"
#import "TDPuller.h"
#import "TD_Database+Replication.h"
#import "TDRemoteRequest.h"
#import "TDAuthorizer.h"
#import "TDBatcher.h"
#import "TDInternal.h"
#import "TDMisc.h"
#import "TDBase64.h"
#import "TDCanonicalJSON.h"
#import "MYBlockUtils.h"
#import "TDReachability.h"
#import "MYURLUtils.h"
#import "CDTLogging.h"
#import "CDTURLSession.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIApplication.h>
#endif

#define kProcessDelay 0.5
#define kInboxCapacity 100

#define kRetryDelay 60.0

NSString* TDReplicatorProgressChangedNotification = @"TDReplicatorProgressChanged";
NSString* TDReplicatorStoppedNotification = @"TDReplicatorStopped";
NSString* TDReplicatorStartedNotification = @"TDReplicatorStarted";

@interface TDReplicator ()
@property (readwrite, nonatomic) BOOL running, active;
@property (readwrite, copy) NSDictionary* remoteCheckpoint;

//if cancelReplicator is YES, then it will not be started once it reaches the front of the queue.
@property (nonatomic) BOOL cancelReplicator;
//indicates that the replicator has started on the queue.
@property (nonatomic) BOOL replicatorStarted;

@property (nonatomic, strong) NSThread *replicatorThread;
@property (nonatomic) BOOL replicatorStopped;
@property (nonatomic, strong,readwrite) CDTURLSession *session;
@property (nonatomic, strong) NSArray* interceptors;

- (void) updateActive;
- (void) fetchRemoteCheckpointDoc;
- (void) saveLastSequence;
@end

@implementation TDReplicator

+ (NSString*)progressChangedNotification { return TDReplicatorProgressChangedNotification; }

+ (NSString*)stoppedNotification { return TDReplicatorStoppedNotification; }
- (instancetype)initWithDB:(TD_Database*)db
                    remote:(NSURL*)remote
                      push:(BOOL)push
                continuous:(BOOL)continuous
              interceptors:(NSArray*)interceptors
{
    NSParameterAssert(db);
    NSParameterAssert(remote);

    // TDReplicator is an abstract class; instantiating one actually instantiates a subclass.
    if ([self class] == [TDReplicator class]) {
        Class klass = push ? [TDPusher class] : [TDPuller class];
        return [[klass alloc] initWithDB:db
                                  remote:remote
                                    push:push
                              continuous:continuous
                            interceptors:interceptors];
    }

    self = [super init];
    if (self) {
        _thread = [NSThread currentThread];
        _db = db;
        _remote = remote;
        _continuous = continuous;
        Assert(push == self.isPush);

        static int sLastSessionID = 0;
        _sessionID = [$sprintf(@"repl%03d", ++sLastSessionID) copy];
        _replicatorThread = nil;
        _replicatorStopped = NO;
        _interceptors = interceptors;
    }
    return self;
}

- (void)dealloc
{
    [self stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_host stop];
}

- (void)databaseClosing
{
    //this can be called from another thread, but we need to execute it the replicator's thread
    [self performSelector:@selector(databaseClosingOnMyThread)
                 onThread:_replicatorThread
               withObject:nil
            waitUntilDone:NO];
}
- (void)databaseClosingOnMyThread
{
    [self stop];
}

- (NSString*) description {
    return $sprintf(@"%@ [%@]", [self class], TDCleanURLtoString(_remote));
}


@synthesize db=_db, remote=_remote, filterName=_filterName, filterParameters=_filterParameters, docIDs = _docIDs;
@synthesize running=_running, online=_online, active=_active, continuous=_continuous;
@synthesize error=_error, sessionID=_sessionID, options=_options;
@synthesize changesProcessed=_changesProcessed, changesTotal=_changesTotal;
@synthesize remoteCheckpoint=_remoteCheckpoint;
@synthesize authorizer=_authorizer;
@synthesize requestHeaders = _requestHeaders;

- (BOOL)isPush
{
    return NO;  // guess who overrides this?
}

- (bool)hasSameSettingsAs:(TDReplicator*)other
{
    return _db == other->_db && $equal(_remote, other->_remote) && self.isPush == other.isPush &&
           _continuous == other->_continuous && $equal(_filterName, other->_filterName) &&
           $equal(_filterParameters, other->_filterParameters) &&
           $equal(_options, other->_options) && $equal(_docIDs, other->_docIDs) &&
           $equal(_requestHeaders, other->_requestHeaders);
}

- (NSObject*)lastSequence { return _lastSequence; }

- (void)setLastSequence:(NSObject*)lastSequence
{
    if (!$equal(lastSequence, _lastSequence)) {
        CDTLogWarn(CDTREPLICATION_LOG_CONTEXT, @"%@: Setting lastSequence to %@ (from %@)", self,
                lastSequence, _lastSequence);
        _lastSequence = [lastSequence copy];
        if (!_lastSequenceChanged) {
            _lastSequenceChanged = YES;
            [self performSelector:@selector(saveLastSequence) withObject:nil afterDelay:5.0];
        }
    }
}

- (void)postProgressChanged
{
    CDTLogWarn(CDTREPLICATION_LOG_CONTEXT,
            @"%@: postProgressChanged (%u/%u, active=%d (batch=%u, net=%u), online=%d)", self,
            (unsigned)_changesProcessed, (unsigned)_changesTotal, _active, (unsigned)_batcher.count,
            _asyncTaskCount, _online);
    NSNotification* n =
        [NSNotification notificationWithName:TDReplicatorProgressChangedNotification object:self];
    [[NSNotificationQueue defaultQueue]
        enqueueNotification:n
               postingStyle:NSPostWhenIdle
               coalesceMask:NSNotificationCoalescingOnSender | NSNotificationCoalescingOnName
                   forModes:nil];
}

- (void)setChangesProcessed:(NSUInteger)processed
{
    _changesProcessed = processed;
    [self postProgressChanged];
}

- (void)setChangesTotal:(NSUInteger)total
{
    _changesTotal = total;
    [self postProgressChanged];
}

- (void)setError:(NSError*)error
{
    BOOL canSetError = YES;
    
    // protect against setting certain errors
    if (error.code == NSURLErrorCancelled && $equal(error.domain, NSURLErrorDomain)) {
        canSetError = NO;
    }

    // don't overwrite previously set errors that we know are fatal and need to retain
    // for proper error reporting
    if (_error.code == TDReplicatorErrorLocalDatabaseDeleted &&
        $equal(_error.domain, TDInternalErrorDomain)) {
        canSetError = NO;
    }
    
    if (_error != error && canSetError) {
        _error = error;
        [self postProgressChanged];
    }
}

- (void) start {
    
    if(_replicatorThread){
        return;
    }
    
    self.running = YES;
    
    _replicatorThread = [[NSThread alloc] initWithTarget: self
                                            selector: @selector(runReplicatorThread)
                                              object: nil];
    CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"Starting TDReplicator thread %@ ...", _replicatorThread);
    [_replicatorThread start];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(databaseWasDeleted:)
                                                 name: TD_DatabaseWillBeDeletedNotification
                                               object: _db];

    [self performSelector:@selector(checkIfNotCanceledThenStart)
                 onThread:_replicatorThread
               withObject:nil
            waitUntilDone:NO];
    
}

-(void) checkIfNotCanceledThenStart
{
    @synchronized(self) {
        if(self.cancelReplicator){
            return;
        }
        self.replicatorStarted = YES;
    }
    
    [self startReplicatorTasks];
}

- (BOOL) cancelIfNotStarted
{
    @synchronized(self) {
        if (self.replicatorStarted) {
            return NO;
        }
        self.cancelReplicator = YES;
        return YES;
    }
}


/**
 * Start a thread for each replicator
 * Taken from TDServer.m.
 */
- (void) runReplicatorThread {
    self.session = [[CDTURLSession alloc] initWithDelegate:nil
                                            callbackThread:_replicatorThread
                                       requestInterceptors:self.interceptors];
    @autoreleasepool {
        CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"TDReplicator thread starting...");
        
        [[NSThread currentThread]
         setName:[NSString stringWithFormat:@"TDReplicator: %@", self.sessionID]];

#ifndef GNUSTEP
        // Add a no-op source so the runloop won't stop on its own:
        CFRunLoopSourceContext context = {}; // all zeros
        CFRunLoopSourceRef source = CFRunLoopSourceCreate(NULL, 0, &context);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
        CFRelease(source);
#endif
        
        // Now run until stopped and async task count is zero:
        while ((!_replicatorStopped || _asyncTaskCount > 0) &&
               [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                                        beforeDate: [NSDate dateWithTimeIntervalSinceNow:0.1]])
            ;
        
        // clear the reference to the db
        _db = nil;
        
        CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"TDReplicator thread exiting");
    }
}


// Notified that our database is being deleted; stop replication
- (void) databaseWasDeleted: (NSNotification*)n {
    
    //this can be called from another thread, but we need to execute it the replicator's thread
    [self performSelector:@selector(databaseWasDeletedOnMyThread:)
                 onThread:_replicatorThread
               withObject:n
            waitUntilDone:NO];
}
-(void) databaseWasDeletedOnMyThread:(id)n
{
    TD_Database* db = ((NSNotification*)n).object;
    Assert(db == _db, @"database objects should be the same!");
    
    NSString *msg = @"Local database deleted during synchronization.";
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(msg, nil)};
    self.error = [NSError errorWithDomain:TDInternalErrorDomain
                                     code:TDReplicatorErrorLocalDatabaseDeleted
                                 userInfo:userInfo];
    CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"During replication %@. databaseWasDeleted block. "
               @"setting error: %@", self, self.error);
    [self stop];

}

- (void) startReplicatorTasks {

    Assert(_db, @"Can't restart an already stopped TDReplicator");
    CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"%@ STARTING ...", self);

    [_db addActiveReplicator:self];

    // Did client request a reset (i.e. starting over from first sequence?)
    if (_options[@"reset"] != nil) {
        [_db setLastSequence:nil withCheckpointID:self.remoteCheckpointDocID];
    }

    // Note: This is actually a ref cycle, because the block has a (retained) reference to 'self',
    // and _batcher retains the block, and of course I retain _batcher.
    // The cycle is broken in -stopped when I release _batcher.
    _batcher = [[TDBatcher alloc] initWithCapacity:kInboxCapacity
                                             delay:kProcessDelay
                                         processor:^(NSArray* inbox) {
                                             CDTLogWarn(CDTREPLICATION_LOG_CONTEXT,
                                                     @"*** %@: BEGIN processInbox (%u sequences)",
                                                     self, (unsigned)inbox.count);
                                             TD_RevisionList* revs =
                                                 [[TD_RevisionList alloc] initWithArray:inbox];
                                             [self processInbox:revs];
                                             CDTLogWarn(CDTREPLICATION_LOG_CONTEXT,
                                                     @"*** %@: END processInbox (lastSequence=%@)",
                                                     self, _lastSequence);
                                             [self updateActive];
                                         }];

    // If client didn't set an authorizer, use basic auth if credential is available:
    if (!_authorizer) {
        _authorizer = [[TDBasicAuthorizer alloc] initWithURL:_remote];
        if (_authorizer)
            CDTLogWarn(CDTREPLICATION_LOG_CONTEXT, @"%@: Found credential, using %@", self, _authorizer);
    }

    _startTime = CFAbsoluteTimeGetCurrent();

    [[NSNotificationCenter defaultCenter] postNotificationName:TDReplicatorStartedNotification
                                                        object:self];

#if TARGET_OS_IPHONE
    // Register for foreground/background transition notifications, on iOS:
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appBackgrounding:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
#endif

    _online = NO;

    // Start reachability checks. (This creates another ref cycle, because
    // the block also retains a ref to self. Cycle is also broken in -stopped.)
    _host = [[TDReachability alloc] initWithHostName:_remote.host];
    __weak id weakSelf = self;
    _host.onChange = ^{
        TDReplicator* strongSelf = weakSelf;
        [strongSelf reachabilityChanged:strongSelf->_host];
    };
    [_host start];

    [self reachabilityChanged:_host];
}

- (void)beginReplicating
{
    // Subclasses implement this
}

- (void)stop
{
    if (!_running) return;
    CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"%@ STOPPING...", self);
    [_batcher flushAll];
    _continuous = NO;
#if TARGET_OS_IPHONE
    // Unregister for background transition notifications, on iOS:
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
#endif
    [self stopRemoteRequests];

    [NSObject cancelPreviousPerformRequestsWithTarget: self
                                             selector: @selector(retryIfReady) object: nil];

    //this just sets the isCanceled BOOL on the object. It's
    //our responsibility to actually stop the thread.
    [_replicatorThread cancel];
    
    if (_running && _asyncTaskCount == 0) {
        [self stopped];
    }
    
}

- (void)stopped
{
    CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"%@ STOPPED", self);
    CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"Replication: %@ took %.3f sec; error=%@", self,
            CFAbsoluteTimeGetCurrent() - _startTime, _error);
    self.running = NO;

    [[NSNotificationCenter defaultCenter] postNotificationName:TDReplicatorStoppedNotification
                                                        object:self];
    [self saveLastSequence];

    _batcher = nil;
    [_host stop];
    _host = nil;
    
    CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"STOP %@", self);
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    _replicatorStopped = YES;
}

-(BOOL) threadExecuting
{
    return [self.replicatorThread isExecuting];
}
-(BOOL) threadFinished
{
    return [self.replicatorThread isFinished];
}
-(BOOL) threadCanceled
{
    return [self.replicatorThread isCancelled];
}

// Called after a continuous replication has gone idle, but it failed to transfer some revisions
// and so wants to try again in a minute. Should be overridden by subclasses.
- (void)retry {}

- (void)retryIfReady
{
    if (!_running) return;

    if (_online) {
        CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"%@ RETRYING, to transfer missed revisions...", self);
        _revisionsFailed = 0;
        [NSObject cancelPreviousPerformRequestsWithTarget:self
                                                 selector:@selector(retryIfReady)
                                                   object:nil];
        [self retry];
    } else {
        [self performSelector:@selector(retryIfReady) withObject:nil afterDelay:kRetryDelay];
    }
}

- (BOOL)goOffline
{
    if (!_online) return NO;
    CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"%@: Going offline", self);
    _online = NO;
    [self stopRemoteRequests];
    [self postProgressChanged];
    return YES;
}

- (BOOL)goOnline
{
    if (_online) return NO;
    CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"%@: Going online", self);
    _online = YES;

    if (_running) {
        _lastSequence = nil;
        self.error = nil;

        [self checkSession];
        [self postProgressChanged];
    }
    return YES;
}

- (void)reachabilityChanged:(TDReachability*)host
{
    CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"%@: Reachability state = %@ (%02X)", self, host,
            host.reachabilityFlags);

    if (host.reachable)
        [self goOnline];
    else if (host.reachabilityKnown)
        [self goOffline];
}

#if TARGET_OS_IPHONE
- (void)appBackgrounding:(NSNotification*)n
{
    // Danger: This is called on the main thread!
    MYOnThread(_thread, ^{
        CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"%@: App going into background", self);
        [self stop];
    });
}
#endif

- (void)updateActive
{
    BOOL active = _batcher.count > 0 || _asyncTaskCount > 0;
    if (active != _active) {
        self.active = active;
        [self postProgressChanged];
        if (!_active) {
            // Replicator is now idle. If it's not continuous, stop.
            if (!_continuous) {
                [self stopped];
            } else if (_revisionsFailed > 0) {
                CDTLogInfo(CDTREPLICATION_LOG_CONTEXT,
                        @"%@: Failed to xfer %u revisions; will retry in %g sec", self,
                        _revisionsFailed, kRetryDelay);
                [NSObject cancelPreviousPerformRequestsWithTarget:self
                                                         selector:@selector(retryIfReady)
                                                           object:nil];
                [self performSelector:@selector(retryIfReady)
                           withObject:nil
                           afterDelay:kRetryDelay];
            }
        }
    }
}

- (void)asyncTaskStarted
{
    if (_asyncTaskCount++ == 0) [self updateActive];
}

- (void)asyncTasksFinished:(NSUInteger)numTasks
{
    _asyncTaskCount -= numTasks;
    Assert(_asyncTaskCount >= 0);
    if (_asyncTaskCount == 0) {
        [self updateActive];
    }
}

- (void)addToInbox:(TD_Revision*)rev
{
    Assert(_running);
    [_batcher queueObject:rev];
    [self updateActive];
}

- (void)addRevsToInbox:(TD_RevisionList*)revs
{
    Assert(_running);
    CDTLogWarn(CDTREPLICATION_LOG_CONTEXT, @"%@: Received %llu revs", self, (UInt64)revs.count);
    [_batcher queueObjects:revs.allRevisions];
    [self updateActive];
}

- (void)processInbox:(NSArray*)inbox {}

- (void)revisionFailed
{
    // Remember that some revisions failed to transfer, so we can later retry.
    ++_revisionsFailed;
}

// Before doing anything else, determine whether we have an active login session.
- (void)checkSession
{
    if (![_authorizer respondsToSelector:@selector(loginParametersForSite:)]) {
        [self fetchRemoteCheckpointDoc];
        return;
    }

    // First check whether a session exists
    [self asyncTaskStarted];
    [self sendAsyncRequest:@"GET"
                      path:@"/_session"
                      body:nil
              onCompletion:^(id result, NSError* error) {
                  if (error) {
                      CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"%@: Session check failed: %@", self,
                              error);
                      self.error = error;
                  } else {
                      NSString* username = $castIf(
                          NSString, [[result objectForKey:@"userCtx"] objectForKey:@"name"]);
                      if (username) {
                          CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"%@: Active session, logged in as '%@'",
                                  self, username);
                          [self fetchRemoteCheckpointDoc];
                      } else {
                          [self login];
                      }
                  }
                  [self asyncTasksFinished:1];
              }];
}

// If there is no login session, attempt to log in, if the authorizer knows the parameters.
- (void)login
{
    NSDictionary* loginParameters = [_authorizer loginParametersForSite:_remote];
    if (loginParameters == nil) {
        CDTLogInfo(CDTREPLICATION_LOG_CONTEXT,
                @"%@: Authorizer has no login parameters, so skipping login", self);
        [self fetchRemoteCheckpointDoc];
        return;
    }

    NSString* loginPath = [_authorizer loginPathForSite:_remote];
    CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"%@: Logging in with %@ at %@ ...", self, _authorizer.class,
            loginPath);
    [self asyncTaskStarted];
    [self sendAsyncRequest:@"POST"
                      path:loginPath
                      body:loginParameters
              onCompletion:^(id result, NSError* error) {
                  if (error) {
                      CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"%@: Login failed!", self);
                      self.error = error;
                  } else {
                      CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"%@: Successfully logged in!", self);
                      [self fetchRemoteCheckpointDoc];
                  }
                  [self asyncTasksFinished:1];
              }];
}

#pragma mark - HTTP REQUESTS:

- (TDRemoteJSONRequest*)sendAsyncRequest:(NSString*)method
                                    path:(NSString*)path
                                    body:(id)body
                            onCompletion:(TDRemoteRequestCompletionBlock)onCompletion
{
    CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"%@: %@ %@", self, method, path);
    NSURL* url;
    if ([path hasPrefix:@"/"]) {
        url = [[NSURL URLWithString:path relativeToURL:_remote] absoluteURL];
    } else {
        url = TDAppendToURL(_remote, path);
    }
    onCompletion = [onCompletion copy];

    // under ARC, using variable req used directly inside the block results in a compiler error (it
    // could have undefined value).
    __weak TDReplicator* weakSelf = self;
    __block TDRemoteJSONRequest* req = nil;
    req = [[TDRemoteJSONRequest alloc] initWithSession:self.session method:method
                                                  URL:url
                                                 body:body
                                       requestHeaders:self.requestHeaders
                                         onCompletion:^(id result, NSError* error) {
                                             TDReplicator* strongSelf = weakSelf;
                                             [strongSelf removeRemoteRequest:req];
                                             id<TDAuthorizer> auth = req.authorizer;
                                             if (auth && auth != _authorizer && error.code != 401) {
                                                 CDTLogInfo(CDTREPLICATION_LOG_CONTEXT,
                                                         @"%@: Updated to %@", self, auth);
                                                 _authorizer = auth;
                                             }
                                             onCompletion(result, error);
                                         }];
    req.authorizer = _authorizer;
    [self addRemoteRequest:req];
    [req start];
    return req;
}

- (void)addRemoteRequest:(TDRemoteRequest*)request
{
    if (!_remoteRequests) _remoteRequests = [[NSMutableArray alloc] init];
    [_remoteRequests addObject:request];
}

- (void)removeRemoteRequest:(TDRemoteRequest*)request
{
    [_remoteRequests removeObjectIdenticalTo:request];
}

- (void)stopRemoteRequests
{
    if (!_remoteRequests) return;
    CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"Stopping %u remote requests",
            (unsigned)_remoteRequests.count);
    // Clear _remoteRequests before iterating, to ensure that re-entrant calls to this won't
    // try to re-stop any of the requests. (Re-entrant calls are possible due to replicator
    // error handling when it receives the 'canceled' errors from the requests I'm stopping.)
    NSArray* requests = _remoteRequests;
    _remoteRequests = nil;
    [requests makeObjectsPerformSelector:@selector(stop)];
}

- (NSArray*)activeRequestsStatus
{
    return [_remoteRequests my_map:^id(TDRemoteRequest* request) { return request.statusInfo; }];
}

#pragma mark - CHECKPOINT STORAGE:

- (void)maybeCreateRemoteDB
{
    // TDPusher overrides this to implement the .createTarget option
}

/** This is the _local document ID stored on the remote server to keep track of state.
    It's based on the local database UUID (the private one, to make the result unguessable),
    the remote database's URL, and the filter name and parameters (if any). */
- (NSString*)remoteCheckpointDocID
{
    NSMutableDictionary* spec =
        $mdict({ @"localUUID", _db.privateUUID }, { @"remoteURL", _remote.absoluteString },
               { @"push", @(self.isPush) }, { @"filter", _filterName },
               { @"filterParams", _filterParameters });
    return TDHexSHA1Digest([TDCanonicalJSON canonicalData:spec]);
}

- (void)fetchRemoteCheckpointDoc
{
    _lastSequenceChanged = NO;
    NSString* checkpointID = self.remoteCheckpointDocID;
    NSObject* localLastSequence = [_db lastSequenceWithCheckpointID:checkpointID];

    [self asyncTaskStarted];
    TDRemoteJSONRequest* request = [self
        sendAsyncRequest:@"GET"
                    path:[@"_local/" stringByAppendingString:checkpointID]
                    body:nil
            onCompletion:^(id response, NSError* error) {
                // Got the response:
                if (error && error.code != kTDStatusNotFound) {
                    CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"%@: Error fetching last sequence: %@", self,
                            error.localizedDescription);
                    self.error = error;
                } else {
                    if (error.code == kTDStatusNotFound) [self maybeCreateRemoteDB];
                    response = $castIf(NSDictionary, response);
                    self.remoteCheckpoint = response;
                    NSObject* remoteLastSequence = response[@"lastSequence"];

                    if ($equal(remoteLastSequence, localLastSequence)) {
                        _lastSequence = localLastSequence;
                        CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"%@: Replicating from lastSequence=%@",
                                self, _lastSequence);
                    } else {
                        CDTLogInfo(
                            CDTREPLICATION_LOG_CONTEXT,
                            @"%@: lastSequence mismatch: I had %@, remote had %@ (response = %@)",
                            self, localLastSequence, remoteLastSequence, response);
                    }
                    [self beginReplicating];
                }
                [self asyncTasksFinished:1];
            }];
    [request dontLog404];
}

#if DEBUG
@synthesize savingCheckpoint = _savingCheckpoint;  // for unit tests
#endif

- (void)saveLastSequence
{
    if (!_lastSequenceChanged) return;
    if (_savingCheckpoint) {
        // If a save is already in progress, don't do anything. (The completion block will trigger
        // another save after the first one finishes.)
        _overdueForSave = YES;
        return;
    }
    _lastSequenceChanged = _overdueForSave = NO;

    CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"%@ checkpointing sequence=%@", self, _lastSequence);
    NSMutableDictionary* body = [_remoteCheckpoint mutableCopy];
    if (!body) body = $mdict();
    [body setValue:_lastSequence forKey:@"lastSequence"];
    
    _savingCheckpoint = YES;
    NSString* checkpointID = self.remoteCheckpointDocID;
    [self asyncTaskStarted];
    [self sendAsyncRequest:@"PUT"
                      path:[@"_local/" stringByAppendingString:checkpointID]
                      body:body
              onCompletion:^(id response, NSError* error) {
                  _savingCheckpoint = NO;
                  if (error) {
                      CDTLogWarn(CDTREPLICATION_LOG_CONTEXT, @"%@: Unable to save remote checkpoint: %@",
                              self, error);
                      // TODO: If error is 401 or 403, and this is a pull, remember that remote is
                      // read-only and don't attempt to read its checkpoint next time.
                  } else if (_db) {
                      id rev = response[@"rev"];
                      if (rev) body[@"_rev"] = rev;
                      self.remoteCheckpoint = body;
                      [_db setLastSequence:_lastSequence withCheckpointID:checkpointID];
                  }

                  CDTLogVerbose(CDTREPLICATION_LOG_CONTEXT,
                                @"PUT last sequence %@ to checkpoint doc response: %@",
                                _lastSequence, response);
                  [self asyncTasksFinished:1];
                  if (_replicatorStopped) {
                      CDTLogVerbose(CDTREPLICATION_LOG_CONTEXT,
                                    @"%@ Final PUT checkpoint. Run loop will be stopped.", self);
                  }

                  if (_db && _overdueForSave)
                      [self saveLastSequence];  // start a save that was waiting on me
              }];
}

@end
