//
//  CDTDatastore+Conflicts.m
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

#import "CDTDatastore+Conflicts.h"
#import "CDTDatastore+Internal.h"
#import "TD_Database+Attachments.h"
#import "CDTDocumentRevision.h"
#import "CDTDatastore+Attachments.h"
#import "CDTAttachment.h"
#import "TD_Revision.h"
#import "TD_Database+Conflicts.h"
#import "TD_Database+Insertion.h"
#import "CDTConflictResolver.h"
#import "TDStatus.h"
#import "TDInternal.h"
#import <FMDB/FMDB.h>
#import "TD_Body.h"
#import "CDTLogging.h"

@implementation CDTDatastore (Conflicts)

- (NSArray *)getConflictedDocumentIds
{
    // This property is not synthesized, it is a method that already ensures that the
    // database is open (or return nil)
    return (self.database ? [self.database getConflictedDocumentIds] : nil);
}

- (BOOL)resolveConflictsForDocument:(NSString *)docId
                           resolver:(NSObject<CDTConflictResolver> *)resolver
                              error:(NSError *__autoreleasing *)error
{
    if (!self.database) {
        *error = TDStatusToNSError(kTDStatusException, nil);
        return NO;
    }

    NSArray *revsArray = [self activeRevisionsForDocumentId:docId];
    NSString *winningRev;

    if (revsArray.count <= 1) {  // no conflicts for this doc
        return kTDStatusOK;
    }

    CDTDocumentRevision *resolvedRev = [resolver resolve:docId conflicts:revsArray];
    NSMutableArray *downloadedAttachments = [NSMutableArray array];
    NSMutableArray *attachmentsToCopy = [NSMutableArray array];

    BOOL isNewRevision = resolvedRev.isChanged;

    if (resolvedRev == nil) {  // do nothing
        return kTDStatusOK;
    } else if (isNewRevision) {
        CDTDocumentRevision *mutableResolvedRev = (CDTDocumentRevision *)resolvedRev;

        if (mutableResolvedRev.revId == nil) {
            [NSException raise:@"Source Revision cannot be nil" format:@""];
        } else {
            winningRev = mutableResolvedRev.revId;

            // need to download attachments to the blob store if there are any which are not saved

            if (mutableResolvedRev.attachments) {
                for (NSString *key in mutableResolvedRev.attachments) {
                    CDTAttachment *attachment = [mutableResolvedRev.attachments objectForKey:key];

                    if (![attachment isKindOfClass:[CDTSavedAttachment class]]) {
                        NSDictionary *attachmentData =
                            [self streamAttachmentToBlobStore:attachment error:error];
                        if (attachmentData == nil) {
                            // well we failed to download lets just move on and return false
                            // error is set by streamAttachmentToBlobStore so no need to set
                            return NO;
                        }
                        [downloadedAttachments addObject:attachmentData];

                    } else {
                        // umm need to add this to the array to copy;;
                        [attachmentsToCopy addObject:attachment];
                    }
                }
            }
        }
    }
    __block NSError *localError;
    __weak CDTDatastore *weakSelf = self;

    TDStatus retStatus = [self.database inTransaction:^TDStatus(FMDatabase *db) {

        CDTDatastore *strongSelf = weakSelf;
        localError = nil;

        // insert at specfied rev
        // I assume thats already attached so I just insert
        TDStatus status;

        if (isNewRevision) {
            TD_Revision *converted =
                [[TD_Revision alloc] initWithDocID:resolvedRev.docId revID:nil deleted:NO];
            converted.body = [[TD_Body alloc] initWithProperties:resolvedRev.body];

            TD_Revision *winner = [strongSelf.database putRevision:converted
                                                    prevRevisionID:winningRev
                                                     allowConflict:NO
                                                            status:&status
                                                          database:db];
            if (TDStatusIsError(status)) {
                // well conflic res failed
                localError = TDStatusToNSError(status, nil);
                return status;
            }

            // okay we have the new winner, need to insert the attachments
            // start with the new ones
            for (NSDictionary *attachment in downloadedAttachments) {
                if (![strongSelf addAttachment:attachment
                                         toRev:[[CDTDocumentRevision alloc]
                                                   initWithDocId:winner.docID
                                                      revisionId:winner.revID
                                                            body:winner.body.properties
                                                         deleted:winner.deleted
                                                     attachments:@{}
                                                        sequence:winner.sequence]
                                    inDatabase:db]) {
                    localError = TDStatusToNSError(kTDStatusAttachmentError, nil);
                    return kTDStatusAttachmentError;
                }
            }
            for (CDTSavedAttachment *attachment in attachmentsToCopy) {
                status = [strongSelf.database copyAttachmentNamed:attachment.name
                                                     fromSequence:attachment.sequence
                                                       toSequence:winner.sequence
                                                       inDatabase:db];

                if (TDStatusIsError(status)) {
                    localError = TDStatusToNSError(status, nil);
                    return status;
                }
            }
        }

        //
        // set all remaining conflicted revisions to deleted
        //
        for (CDTDocumentRevision *theRev in revsArray) {
            if (theRev == resolvedRev || [theRev.revId isEqualToString:winningRev]) {
                continue;
            }

            TD_Revision *toPutRevision =
                [[TD_Revision alloc] initWithDocID:docId revID:nil deleted:YES];

            TDStatus status;
            [strongSelf.database putRevision:toPutRevision
                              prevRevisionID:theRev.revId
                               allowConflict:NO
                                      status:&status
                                    database:db];

            if (TDStatusIsError(status)) {
                localError = TDStatusToNSError(status, nil);
                CDTLogWarn(CDTDATASTORE_LOG_CONTEXT,
                        @"CDTDatastore+Conflicts -resolveConflictsForDocument: Failed"
                        @" to delete non-winning revision (%@) for document %@",
                        theRev.revId, docId);
                return status;
            }
        }

        return kTDStatusOK;
    }];

    *error = localError;
    return retStatus == kTDStatusOK;
}

@end
