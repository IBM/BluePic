//
//  CDTDatastore+Internal.h
//
//  Created by G. Adam Cox on 27/03/2014.
//  Copyright (c) 2014 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "CDTDatastore.h"
@class FMDatabase;

@interface CDTDatastore (Internal)

/**
 * Get all the active revisions for a document.
 *
 * An active revision is a non-deleted terminal node
 * in a document revision tree.
 *
 * For example, if a document revision tree looks like
 *
 *  ----- 2-c (deleted = 1)
 * /
 * 1-a --- 2-a --- 3-a (deleted = 0)
 *  \
 *   ---- 2-b (deleted = 0)
 *
 * then the 3-a and 2-b revisions will be returned.
 *
 * The NSArray* contains the CDTDocumentRevision objects for each revision.
 *
 * If there are >1 revisions in the array, then this document is considered
 * to be conflicted.
 *
 * Only to be used within a queued database transaction. You should also
 * ensure that the database exists and is open before you call this method
 * (TD_Database -open:).
 *
 * @param docId the document ID
 * @param db the FMDatabase object being used in the current database transaction
 */
- (NSArray *)activeRevisionsForDocumentId:(NSString *)docId database:(FMDatabase *)db;

/**
 This method is the same as above, but opens a separate database transaction
 */
- (NSArray *)activeRevisionsForDocumentId:(NSString *)docId;

@end
