//
//  CDTConflictResolver.h
//
//
//  Created by G. Adam Cox on 11/03/2014.
//  Copyright (c) 2014 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.
//
#import <Foundation/Foundation.h>

@class CDTDocumentRevision;

/**
 Protocol adopted by classes that implement a conflict resolution algorithm.

 These classes are supplied as an argument to
 + [CDTDatastore resolveConflictsForDocument:resolver:error:].

 @see CDTDatastore
 */

@protocol CDTConflictResolver

/**
 * The implementation of this method should examine the conflicted revisions and return
 * a winning CDTDocumentRevision from the conflicts array. You may not create a new
 * CDTDocumentRevision. If you wish to merge revisions to create a new winning revision,
 * call mutableCopy on a CDTDocumentRevision you wish to be parent revision, and then merge
 * the data from the conflicted revisions into the new revision.
 *
 * This method will be called by [CDTDatastore resolveConflictsForDocument:resolver:error:]
 * if there are conflicts found for the document ID.
 *
 * When called by [CDTDatastore resolveConflictsForDocument:resolver:error:],
 * the returned CDTDocumentRevision is declared the winner and all
 * other conflicting revisions in the tree will be deleted. This all happens within a single
 * database transaction in order to ensure atomicity.
 *
 * The output of this method should be deterministic. That is, for the given docId and
 * conflict set, the same CDTDocumentRevision should be returned for
 * all calls.
 *
 * Additionally, this method should not modify other documents or attempt to query the database
 * (via calls to CDTDatastore methods). Doing so will create a blocking transaction to
 * the database; the code will never excute and this method will hang indefinitely.
 *
 * Finally, if `nil` is returned by this method, nothing will be changed in the database and the
 * document will remain conflicted.
 *
 *
 * @param docId id of the document with conflicts
 * @param conflicts array of conflicted CDTDocumentRevision, including the current winner
 * @return the new winning CDTDocumentRevision, or `nil` if the document should be left as it
 + *         currently is (i.e., leave the database unchanged).
 *
 */
- (CDTDocumentRevision *)resolve:(NSString *)docId conflicts:(NSArray *)conflicts;

@end
