//
//  CDTReplicatorDelegate.h
//
//
//  Created by Michael Rhodes on 07/02/2014.
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

@class CDTReplicator;
@class CDTReplicationErrorInfo;

/**
 The delegate of a CDTReplicator must adopt the CDTReplicatorDelegate protocol. The protocol
 allows the delegate to be notified of updates during replication. All methods are optional.
 */
@protocol CDTReplicatorDelegate <NSObject>

// all methods are optional
@optional

/**
 * <p>Called when the replicator changes state.</p>
 *
 * <p>May be called from any worker thread.</p>
 *
 * @param replicator the replicator issuing the event.
 */
- (void)replicatorDidChangeState:(CDTReplicator *)replicator;

/**
 * <p>Called whenever the replicator changes progress</p>
 *
 * <p>May be called from any worker thread.</p>
 *
 * @param replicator the replicator issuing the event.
 */
- (void)replicatorDidChangeProgress:(CDTReplicator *)replicator;

/**
 * <p>Called when a state transition to COMPLETE or STOPPED is
 * completed.</p>
 *
 * <p>May be called from any worker thread.</p>
 *
 * <p>Continuous replications (when implemented) will never complete.</p>
 *
 * @param replicator the replicator issuing the event.
 */
- (void)replicatorDidComplete:(CDTReplicator *)replicator;

/**
 * <p>Called when a state transition to ERROR is completed.</p>
 *
 * <p>Errors may include things such as:</p>
 *
 * <ul>
 *      <li>incorrect credentials</li>
 *      <li>network connection unavailable</li>
 * </ul>
 *
 *
 * <p>May be called from any worker thread.</p>
 *
 * @param replicator the replicator issuing the event.
 * @param info information about the error that occurred.
 */
- (void)replicatorDidError:(CDTReplicator *)replicator info:(NSError *)info;

@end
