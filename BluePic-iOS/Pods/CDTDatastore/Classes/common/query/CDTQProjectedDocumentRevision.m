//
//  CDTQProjectedDocumentRevision.m
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

#import "CDTQProjectedDocumentRevision.h"

#import <CloudantSync.h>

@interface CDTQProjectedDocumentRevision ()

@property (nonatomic, strong) CDTDatastore *datastore;

@end

@implementation CDTQProjectedDocumentRevision

- (id)initWithDocId:(NSString *)docId
         revisionId:(NSString *)revId
               body:(NSDictionary *)body
            deleted:(BOOL)deleted
        attachments:(NSDictionary *)attachments
           sequence:(SequenceNumber)sequence
          datastore:(CDTDatastore *)datastore
{
    self = [self initWithDocId:docId
                    revisionId:revId
                          body:body
                       deleted:deleted
                   attachments:attachments
                      sequence:sequence];
    if (self != nil) {
        _datastore = datastore;
    }
    return self;
}

/** A projection doesn't contain attachments, nor all fields from a document. */
- (BOOL)isFullRevision { return NO; }

- (CDTDocumentRevision *)copy
{
    CDTDocumentRevision *rev = [self.datastore getDocumentWithId:self.docId error:nil];
    if (rev == nil) {
        return nil;
    }

    // Don't want to return an updated version, breaks contract of mutableCopy
    if (![rev.revId isEqualToString:self.revId]) {
        return nil;
    }

    return rev;
}

@end
