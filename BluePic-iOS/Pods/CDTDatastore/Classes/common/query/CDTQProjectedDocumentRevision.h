//
//  CDTQProjectedDocumentRevision.h
//
//  Created by Michael Rhodes on 18/10/2014.
//  Copyright (c) 2014 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "CDTDocumentRevision.h"

@class CDTDatastore;

/**
 A document revision that has been projected.

 This class implements a version of mutableCopy which returns the full
 document when called, to prevent accidental data loss which might come
 from saving a projected document.
 */
@interface CDTQProjectedDocumentRevision : CDTDocumentRevision

/**
 Initialise with a datastore so mutableCopy can return a full document.
 */
- (id)initWithDocId:(NSString *)docId
         revisionId:(NSString *)revId
               body:(NSDictionary *)body
            deleted:(BOOL)deleted
        attachments:(NSDictionary *)attachments
           sequence:(SequenceNumber)sequence
          datastore:(CDTDatastore *)datastore;

@end
