//
//  CDTPushReplication.h
//
//
//  Created by Adam Cox on 4/8/14.
//  Copyright (c) 2014 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "CDTAbstractReplication.h"
@class CDTDocumentRevision;

typedef BOOL (^CDTFilterBlock)(CDTDocumentRevision *revision, NSDictionary *params);

/**
 CDTPushReplication objects are used to configure a replication of a local
 CDTDatastore to a remote Cloudant/CouchDB datastore. At minimum, source and
 target must be specified.

 Example usage:

    CDTDatastoreManager *manager = [...];
    CDTDatastore *datastore = [...];
    CDTReplicatorFactory *replicatorFactory = [...];

    NSURL *remote = [NSURL URLwithString:@"https://user:password@account.cloudant.com/myremotedb"];

    CDTPushReplication* push = [CDTPushReplication replicationWithSource:datastore
                                                                  target:remote];

    NSError *error;
    CDTReplicator *myrep = [replicatorFactory oneWay:push error:&error];

    //check for error

    [myrep start];

 @see CDTAbstractReplication
*/

@interface CDTPushReplication : CDTAbstractReplication <NSCopying>

/**
 @name Creating a replication configuration
 */

/** All CDTPushReplication objects must have a source and target.

 @param source the local datastore from which the data is replicated.
 @param target the remote server URL to which the data is replicated.
 @return a CDTPushReplication object.

 */
+ (instancetype)replicationWithSource:(CDTDatastore *)source target:(NSURL *)target;

/**
 @name Accessing the replication source and target
 */

/** The NSURL for the target remote datastore

     protocol://[user:password@]host[:port]/remoteDatabaseName

 Only _http_ and _https_ are valid protocols.

 Consider using NSURLComponents if you need to set each component individually.

 @see CDTAbstractReplication.
 */
@property (nonatomic, strong, readonly) NSURL *target;

/**
 The CDTDatastore from which the data is replicated.
 */
@property (nonatomic, strong, readonly) CDTDatastore *source;

/**
 @name Filtered push replication
 */

/**
 The block function used to filter local documents during a push replication.

 If this property is nil, the default, then no filter is used in the replication.

 One may require to push only a subset of documents found in the local source
 database to the remote target. In order to select that subset of documents,
 a filter is used. A CDTDocumentRevision in the local source database, along with
 the NSDictionary filterParams, is passed to the CDTDFilterBlock. The CDTFilterBlock
 must return either YES or NO to specifiy if the CDTDocumentRevision is to be
 pushed to the remote target.

 For example (compare to the documentation for CDTPullReplication),
 consider a local database with documents that contain the following JSON bodies:

    {
        '_id':'foo',
        '_rev': '1-x',
        'user': {
                    'age' : 34
                }
        ...
    }

 In order to push replicate a subset of the documents in this database to the
 remote database using a filter, first define the CDTFilterBlock

    CDTFilterBlock myFilter = ^BOOL(CDTDocumentRevision *rev, NSDictionary *param){
        NSInteger age = [[rev documentAsDictionary][@"user"][@"age"] integerValue];
        NSInteger min = [param[@"min"] integerValue];
        NSInteger max = [param[@"max"] integerValue];

        return age >= min && age < max;
    };

 Set the properties

    CDTPushReplication* push = ...

    push.filter = myFilter;
    push.filterParams = @{@"min":@23, @"max":@43};

 Then create and start the replication process as usual

    NSError *error;
    CDTReplicator *myrep = [replicatorFactory oneWay:push error:&error];
    //check for error

    [myrep start];

 */
@property (nonatomic, copy) CDTFilterBlock filter;

/** The filter function query parameters

 @see -filter
 */
@property (nonatomic, copy) NSDictionary *filterParams;

@end
