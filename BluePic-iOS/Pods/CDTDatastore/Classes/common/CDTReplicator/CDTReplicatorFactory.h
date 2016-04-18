//
//  CDTReplicatorFactory.h
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

@class CDTDatastore;
@class CDTReplicator;
@class CDTDatastoreManager;
@class CDTAbstractReplication;

/**
 Factory for CDTReplicator objects.

 Use CDTReplicatorFactory to create CDTReplicator objects based on the parameters set in a
 CDTPushReplication or CDTPullReplication object. The CDTPush/PullReplication objects
 configure the replication, while the CDTReplicator starts the process.

 Example usage:

    CDTDatastoreManager *manager = [...];
    CDTDatastore *datastore = [...];
    NSURL *remote = [NSURL URLwithString:@"https://user:password@account.cloudant.com/myremotedb"];
    
    CDTReplicatorFactory *replicatorFactory = [CDTReplicatorFactory initWithDatastoreManager:manager];
 
    CDTPullReplication* pull = [CDTPullReplication replicationWithSource:remote target:datastore];

    NSError *error;
    CDTReplicator *rep = [replicatorFactory oneWay:pull error:&error];

    //check for error
    [rep start];

*/
@interface CDTReplicatorFactory : NSObject

/**---------------------------------------------------------------------------------------
 * @name Setup and control
 *  --------------------------------------------------------------------------------------
 */

/**
 Initialise with a datastore manager object.

 This manager is used for the `_replicator` database used to manage
 replications internally.

 @param dsManager the manager of the datastores that this factory will replicate to and from.
 */
- (id)initWithDatastoreManager:(CDTDatastoreManager *)dsManager;


/**---------------------------------------------------------------------------------------
 * @name Creating replication jobs
 *  --------------------------------------------------------------------------------------
 */

/**
 * Create a CDTReplicator object set up to replicate changes from the
 * local datastore to a remote database.
 *
 * CDTPullReplication and CDTPushReplication (subclasses of CDTAbstractReplication)
 * provide configuration parameters for the construction of the CDTReplicator.
 *
 * @param replication a CDTPullReplication or CDTPushReplication
 * @param error report error information
 *
 * @return a CDTReplicator instance which can be used to start and
 *  stop the replication itself.
 */
- (CDTReplicator *)oneWay:(CDTAbstractReplication *)replication
                    error:(NSError *__autoreleasing *)error;

/**
 @name Deprecated
 */

/**
 * Create a CDTReplicator object set up to replicate changes from the
 * local datastore to a remote database.
 *
 * @param source local CDTDatastore to replicate changes from.
 * @param target remote database to replicate changes to.
 *
 * @return a CDTReplicator instance which can be used to start and
 *  stop the replication itself.
 * @warning This will soon be deprecated. Use -oneWay:error:.
 */
- (CDTReplicator *)onewaySourceDatastore:(CDTDatastore *)source targetURI:(NSURL *)target;

/**
 * Create a CDTReplicator object set up to replicate changes from a
 * remote database to the local datastore.
 *
 * @param source remote database to replicate changes from.
 * @param target local CDTDatastore to replicate changes to.
 *
 * @return a CDTReplicator instance which can be used to start and
 *  stop the replication itself.
 * @warning This will soon be deprecated. Use -oneWay:error:.
 */
- (CDTReplicator *)onewaySourceURI:(NSURL *)source targetDatastore:(CDTDatastore *)target;

@end
