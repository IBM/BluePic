//
//  CDTFetchChanges.h
//  CloudantSync
//
//  Created by Michael Rhodes on 31/03/2015.
//  Copyright (c) 2015 IBM Cloudant. All rights reserved.
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
@class CDTDocumentRevision;

/**
 CDTFetchChanges objects report changes to a database. The changes include documents which
 have been created, updated or deleted. Use this class to update your user interface efficiently
 when notified a replication is complete, for example, by updating elements for only those
 documents that have changed.

 CDTFetchChanges provides callbacks for updated and created documents (documentChangedBlock)
 and deleted documents (documentWithIDWasDeletedBlock). It also provides a completion block
 for when all changes have been received and processed (fetchRecordChangesCompletionBlock).
 The documentChangedBlock is passed the current revision of each document, the
 documentWithIDWasDeletedBlock is just passed the id of the deleted document.

 In addition, CDTFetchChanges is able to report on changes since a given point. The completion
 block provides a sequence value which can be passed to future operations to have only changes
 from that point reported. This allows your application to make incremental updates
 in response to changes in a database.

 The sequence value should be treated as an opaque value, but can be saved and used across
 application sessions.

 The blocks you assign to process the fetched documents are executed serially. Your blocks must
 be capable of executing on a background thread, so any tasks that require access to the main
 thread must be redirected accordingly.
 */
@interface CDTFetchChanges : NSOperation

#pragma mark Properties

/**
 The datastore whose changes should be reported.

 Typically this is set with the initialiser.
 */
@property (nonatomic, strong) CDTDatastore *datastore;

/**
 The sequence value identifying the starting point for reading changes.

 The value to use for this is returned by the completion block for a fetch operation. This
 sequence value can be used to receive changes that have occured since the previous operation.

 Treat the sequence value as an opaque string; different implementations may provide
 differently formatted values. A given sequence value should only be used with the
 database that it was received from.

 Typically this is set with the initialiser.
 */
@property (nonatomic, copy) NSString *startSequenceValue;

/**
 Use this property to limit the total number of results you want to get.
 
 By default, its value 0 which means that it will returns as many as possible.
 
 Set it before executing the operation or submitting it to a queue.
 */
@property(nonatomic, assign) NSUInteger resultsLimit;

/**
 It will be YES only if there are more results available.
 
 A CDTFetchChanges instance will deliver all results available unless a limit is set with
 resultsLimit.
 
 This property will set to YES before calling fetchRecordChangesCompletionBlock.
 
 @see resultsLimit
 @see fetchRecordChangesCompletionBlock
 */
@property(nonatomic, readonly) BOOL moreComing;

#pragma mark Callbacks

/**
 The block to execute for each changed document.

 The block returns no value and takes the following parameter:

 <dl>
 <dt>revision</dt>
 <dd>The winning revision for the document that changed.</dd>
 </dl>

 The operation object executes this block once for each document in the database that changed
 since the previous fetch operation. Each time the block is executed, it is executed
 serially with respect to the other progress blocks of the operation. If no documents
 changed, the block is not executed.

 If you intend to use this block to process results, set it before executing the
 operation or submitting it to a queue.
 */
@property (nonatomic, copy) void (^documentChangedBlock)(CDTDocumentRevision *revision);

/**
 The block to execute for each deleted document.

 The block returns no value and takes the following parameters:

 <dl>
 <dt>docId</dt>
 <dd>The document id for the deleted document.</dd>
 </dl>

 The operation object executes this block once for each document in the database that
 was deleted since the previous fetch operation. Each time the block is executed, it
 is executed serially with respect to the other progress blocks of the operation.
 If no documents were deleted, the block is not executed.

 If you intend to use this block to process results, set it before executing the
 operation or submitting it to a queue.
 */
@property (nonatomic, copy) void (^documentWithIDWasDeletedBlock)(NSString *docId);

/**
 The block to execute when all changes have been reported.

 The block returns no value and takes the following parameters:

 <dl>
 <dt>newSequenceValue</dt>
 <dd>The new sequence value from the database. You can store this value locally and use it
 during subsequent fetch operations to limit the results to documents that changed since
 this operation executed. A sequence value is only valid for the database it was
 originally retrieved from.</dd>

 <dt>startSequenceValue</dt>
 <dd>The sequence value you specified when you initialized the operation object.</dd>

 <dt>fetchError</dt>
 <dd>An error object containing information about a problem, or nil if the changes are
 retrieved successfully.</dd>
 </dl>

 The operation object executes this block only once, at the conclusion of the operation. It
 is executed after all individual change blocks.
 The block is executed serially with respect to the other progress blocks of the operation.

 If you intend to use this block to process results, set it before executing the operation or
 submitting the operation object to a queue.
 */
@property (nonatomic, copy) void (^fetchRecordChangesCompletionBlock)
    (NSString *newSequenceValue, NSString *startSequenceValue, NSError *fetchError);

#pragma mark Initialisers

/**
 Initializes and returns an object configured to fetch changes in the specified database.

 When initializing the fetch operation, use the sequence value from a previous fetch operation if
 you have one. You can archive sequence values and write them to disk for later use if needed.

 After initializing the operation, associate at least one progress block with the operation
 object (excluding the completion block) to process the results.

 @param datastore The datastore containing the changes that should be fetched.
 @param previousServerChangeToken The sequence value from a previous fetch operation. This
            is the value passed to the completionHandler for this object. This value limits
            the changes retrieved to those occuring after this sequence value. Pass `nil` to
            receive all changes.

 @return An initialised fetch operation.
 */
- (instancetype)initWithDatastore:(CDTDatastore *)datastore
               startSequenceValue:(NSString *)startSequenceValue;


@end
