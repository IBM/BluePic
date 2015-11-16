//
//  CDTDatastore+Conflicts.h
//
//
//  Created by G. Adam Cox on 13/03/2014.
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
@protocol CDTConflictResolver;

@interface CDTDatastore (Conflicts)

/**
 * Get all document ids in the datastore that have a conflict in its revision tree.
 *
 * @return an array of NSString* document ids.
 */
- (NSArray *)getConflictedDocumentIds;

/**
 Resolve conflicts for a specific document using an object that conforms to the
 CDTConflictResolver protocol

 This method creates an NSArry of CDTDocumentRevision objects representing each of the conflicting
 revisions in a particular document tree and passes that array to the given
 [CDTConflictResolver resolve:conflicts:]. The [CDTConflictResolver resolve:conflicts:] method
 must return the winning revision either chosen from the array or a new document revision defined
 with a CDTDocumentRevision. This method will check the returned revision for validity
 (eg CDTDocumentRevision has a parent revision) and then delete all losing revisions. This
 all happens within a single database transaction in order to ensure atomicity.

 It is envisioned that this method will be used in conjunction with getConflictedDocumentIds.

    CDTDatastore *datastore = ...;
    MyConflictResolver *myResolver = ...;

    for (NSString *docId in [datastore getConflictedDocumentIds]) {
        NSError *error;
        BOOL didResolve = [datastore resolveConflictsForDocument:docId
                                                        resolver:myResolver
                                                           error:&error];
        //check error, didResolve
    }

 @param docId id of Document to resolve conflicts
 @param resolver the CDTConflictResolver-conforming object used to resolve conflicts
 @param error error reporting
 @return YES/NO depending on success.

 @see CDTConflictResolver
 */
- (BOOL)resolveConflictsForDocument:(NSString *)docId
                           resolver:(NSObject<CDTConflictResolver> *)resolver
                              error:(NSError *__autoreleasing *)error;

@end
