//
//  TDPusher.m
//  TouchDB
//
//  Created by Jens Alfke on 12/5/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.
//
//  Modifications for this distribution by Cloudant, Inc., Copyright(c) 2014 Cloudant, Inc.

#import "TDPusher.h"
#import "TD_Database.h"
#import "TD_Database+Insertion.h"
#import "TD_Revision.h"
#import "TDBatcher.h"
#import "TDMultipartUploader.h"
#import "TDInternal.h"
#import "TDCanonicalJSON.h"
#import "CDTLogging.h"

@interface TDPusher ()
- (BOOL)uploadMultipartRevision:(TD_Revision*)rev;
@end

@implementation TDPusher

@synthesize createTarget = _createTarget;

- (BOOL)isPush { return YES; }

// This is called before beginReplicating, if the target db might not exist
- (void)maybeCreateRemoteDB
{
    if (!_createTarget) return;
    CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"Remote db might not exist; creating it...");
    _creatingTarget = YES;
    [self asyncTaskStarted];
    [self sendAsyncRequest:@"PUT"
                      path:@""
                      body:nil
              onCompletion:^(id result, NSError* error) {
                  _creatingTarget = NO;
                  if (error && error.code != kTDStatusDuplicate) {
                      CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"Failed to create remote db: %@", error);
                      self.error = error;
                      [self stop];
                  } else {
                      CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"Created remote db");
                      _createTarget = NO;  // remember that I created the target
                      [self beginReplicating];
                  }
                  [self asyncTasksFinished:1];
              }];
}

- (void)beginReplicating
{
    // If we're still waiting to create the remote db, do nothing now. (This method will be
    // re-invoked after that request finishes; see -maybeCreateRemoteDB above.)
    if (_creatingTarget) return;

    _pendingSequences = [NSMutableIndexSet indexSet];
    // in TDPusher, _lastSequence is always an NSNumber
    _maxPendingSequence = [(NSNumber*)_lastSequence longLongValue];

    // Include conflicts so all conflicting revisions are replicated too
    TDChangesOptions options = kDefaultTDChangesOptions;
    options.includeConflicts = YES;
    // Process existing changes since the last push:
    [self addRevsToInbox:[_db changesSinceSequence:_maxPendingSequence
                                           options:&options
                                            filter:self.filter
                                            params:_filterParameters]];
    [_batcher flush];  // process up to the first 100 revs

    // Now listen for future changes (in continuous mode):
    if (_continuous && !_observing) {
        _observing = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(dbChanged:)
                                                     name:TD_DatabaseChangeNotification
                                                   object:_db];
    }

#ifdef GNUSTEP  // TODO: Multipart upload on GNUstep
    _dontSendMultipart = YES;
#endif
}

- (void)stopObserving
{
    if (_observing) {
        _observing = NO;
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:TD_DatabaseChangeNotification
                                                      object:_db];
    }
}

- (void)retry
{
    // This is called if I've gone idle but some revisions failed to be pushed.
    // I should start the _changes feed over again, so I can retry all the revisions.
    [super retry];

    [self beginReplicating];
}

- (BOOL)goOffline
{
    if (![super goOffline]) return NO;
    [self stopObserving];
    return YES;
}

- (void)stop
{
    _uploaderQueue = nil;
    _uploading = NO;
    [self stopObserving];
    [super stop];
}

// Adds a local revision to the "pending" set that are awaiting upload:
- (void)addPending:(TD_Revision*)rev
{
    SequenceNumber seq = rev.sequence;
    [_pendingSequences addIndex:(NSUInteger)seq];
    _maxPendingSequence = MAX(_maxPendingSequence, seq);
}

// Removes a revision from the "pending" set after it's been uploaded. Advances checkpoint.
- (void)removePending:(TD_Revision*)rev
{
    SequenceNumber seq = rev.sequence;
    bool wasFirst = (seq == (SequenceNumber)_pendingSequences.firstIndex);
    if (![_pendingSequences containsIndex:(NSUInteger)seq])
        CDTLogWarn(CDTREPLICATION_LOG_CONTEXT, @"%@ removePending: sequence %lld not in set, for rev %@",
                self, seq, rev);
    [_pendingSequences removeIndex:(NSUInteger)seq];

    if (wasFirst) {
        // If I removed the first pending sequence, can advance the checkpoint:
        SequenceNumber maxCompleted = _pendingSequences.firstIndex;
        if (maxCompleted == NSNotFound)
            maxCompleted = _maxPendingSequence;
        else
            --maxCompleted;
        self.lastSequence = [NSNumber numberWithUnsignedLongLong:maxCompleted];
    }
}

- (void)dbChanged:(NSNotification*)n
{
    NSDictionary* userInfo = n.userInfo;
    // Skip revisions that originally came from the database I'm syncing to:
    if ([userInfo[@"source"] isEqual:_remote]) return;
    TD_Revision* rev = userInfo[@"rev"];

    if (!self.filter || !self.filter(rev, _filterParameters)) return;

    CDTLogVerbose(CDTREPLICATION_LOG_CONTEXT, @"%@: Queuing #%lld %@", self, rev.sequence, rev);
    [self addToInbox:rev];
}

- (void)processInbox:(TD_RevisionList*)changes
{
    // Generate a set of doc/rev IDs in the JSON format that _revs_diff wants:
    // <http://wiki.apache.org/couchdb/HttpPostRevsDiff>
    NSMutableDictionary* diffs = $mdict();
    for (TD_Revision* rev in changes) {
        NSString* docID = rev.docID;
        NSMutableArray* revs = diffs[docID];
        if (!revs) {
            revs = $marray();
            diffs[docID] = revs;
        }
        [revs addObject:rev.revID];
        [self addPending:rev];
    }

    // Call _revs_diff on the target db:
    [self asyncTaskStarted];
    [self sendAsyncRequest:@"POST"
                      path:@"_revs_diff"
                      body:diffs
              onCompletion:^(NSDictionary* results, NSError* error) {
                  if (error) {
                      self.error = error;
                      [self revisionFailed];
                  } else if (results.count) {
                      // Go through the list of local changes again, selecting the ones the
                      // destination server
                      // said were missing and mapping them to a JSON dictionary in the form
                      // _bulk_docs wants:
                      TD_RevisionList* revsToSend = [[TD_RevisionList alloc] init];
                      NSArray* docsToSend = [changes.allRevisions my_map:^id(TD_Revision* rev) {
                          NSDictionary* properties;
                          @autoreleasepool
                          {
                              // Is this revision in the server's 'missing' list?
                              NSDictionary* revResults = results[rev.docID];
                              NSArray* missing = revResults[@"missing"];
                              if (![missing containsObject:[rev revID]]) {
                                  [self removePending:rev];
                                  return nil;
                              }

                              // Get the revision's properties:
                              TDContentOptions options = kTDIncludeAttachments | kTDIncludeRevs;
                              if (!_dontSendMultipart) options |= kTDBigAttachmentsFollow;
                              if ([_db loadRevisionBody:rev options:options] >= 300) {
                                  CDTLogWarn(CDTREPLICATION_LOG_CONTEXT,
                                          @"%@: Couldn't get local contents of %@", self, rev);
                                  [self revisionFailed];
                                  return nil;
                              }
                              properties = rev.properties;
                              Assert(properties[@"_revisions"]);

                              // Strip any attachments already known to the target db:
                              if (properties[@"_attachments"]) {
                                  if (_sendAllDocumentsWithAttachmentsAsMultipart) {
                                      // We saw an error which indicates we should send all
                                      // documents
                                      // with attachments using multipart/related AND include all
                                      // attachment data (no stubs)
                                      // A combination of revpos=0 and attachmentsFollow=YES will
                                      // add
                                      // follows to all attachments, causing uploadMultipartRevision
                                      // to
                                      // send data inline.
                                      [TD_Database stubOutAttachmentsIn:rev
                                                           beforeRevPos:0
                                                      attachmentsFollow:YES];
                                      properties = rev.properties;
                                      if ([self uploadMultipartRevision:rev]) {
                                          return nil;
                                      }
                                  } else {
                                      // If we're still churning along fine -- which we should be --
                                      // stub
                                      // out attachments that we're sure the remote has by finding
                                      // the
                                      // common ancestor and stubbing out those older than that.
                                      NSArray* possible = revResults[@"possible_ancestors"];
                                      int minRevPos = findCommonAncestor(rev, possible);
                                      [TD_Database stubOutAttachmentsIn:rev
                                                           beforeRevPos:minRevPos + 1
                                                      attachmentsFollow:NO];
                                      properties = rev.properties;
                                      // If the rev has huge attachments, send it under separate
                                      // cover:
                                      if (!_dontSendMultipart && [self uploadMultipartRevision:rev])
                                          return nil;
                                  }
                              }
                          }
                          Assert(properties[@"_id"]);
                          [revsToSend addRev:rev];
                          return properties;
                      }];

                      // Post the revisions to the destination:
                      [self uploadBulkDocs:docsToSend changes:revsToSend];

                  } else {
                      // None of the revisions are new to the remote
                      for (TD_Revision* rev in changes.allRevisions) [self removePending:rev];
                  }
                  [self asyncTasksFinished:1];
              }];
}

/**
 Upload documents to the remote using _bulk_docs.

 http://wiki.apache.org/couchdb/HTTP_Bulk_Document_API

 Using "new_edits":NO means the server will add the revisions verbatim, that is,
 using the rev ID we send rather than creating new ones.

 @param docsToSend Contains document dictionaries in the format _bulk_docs expects
    them, including conflicting revisions. This is passed as-is into the _bulk_docs
    call.
 @param changes Contains the list of TD_Revision objects for the documents we are
    sending.
 */
- (void)uploadBulkDocs:(NSArray*)docsToSend changes:(TD_RevisionList*)changes
{
    NSUInteger numDocsToSend = docsToSend.count;
    if (numDocsToSend == 0) return;
    CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"%@: Sending %u revisions", self, (unsigned)numDocsToSend);
    CDTLogVerbose(CDTREPLICATION_LOG_CONTEXT, @"%@: Sending %@", self, changes.allRevisions);
    self.changesTotal += numDocsToSend;
    [self asyncTaskStarted];
    [self sendAsyncRequest:@"POST"
                      path:@"_bulk_docs"
                      body:$dict({ @"docs", docsToSend }, { @"new_edits", $false })
              onCompletion:^(NSDictionary* response, NSError* error) {

                  TD_RevisionList* revisionsToRetry = [[TD_RevisionList alloc] init];

                  if (!error) {
                      NSMutableSet* failedIDs = [NSMutableSet set];

                      // _bulk_docs response is really an array, not a dictionary
                      for (NSDictionary* item in $castIf(NSArray, response)) {
                          TDStatus status = statusFromBulkDocsResponseItem(item);

                          if (!TDStatusIsError(status)) {
                              continue;
                          }

                          // This item (doc) failed to save correctly
                          CDTLogWarn(CDTREPLICATION_LOG_CONTEXT, @"%@: _bulk_docs got an error: %@", self,
                                  item);

                          NSString* docID;
                          NSURL* url;
                          switch (status) {
                              // 403/Forbidden means validation failed; don't treat it as an error
                              // because I did my job in sending the revision. Other statuses are
                              // actual replication errors.
                              case kTDStatusForbidden:
                              case kTDStatusUnauthorized:
                                  break;

                              // 412 is likely to mean that the attachment stubs we sent were
                              // rejected by CouchDB. We need to resend the rev with all current
                              // attachments using multipart/related. If this fails, we really
                              // failed.
                              case kTDStatusDuplicate:
                                  docID = item[@"id"];
                                  for (TD_Revision* rev in [changes revsWithDocID:docID]) {
                                      [revisionsToRetry addRev:rev];
                                  }
                                  _sendAllDocumentsWithAttachmentsAsMultipart = YES;

                                  // The rev also failed, so don't remove from pending
                                  [failedIDs addObject:docID];

                                  break;

                              // Replication error
                              default:
                                  docID = item[@"id"];
                                  [failedIDs addObject:docID];
                                  url = nil;
                                  if (docID) {
                                      url = [_remote URLByAppendingPathComponent:docID];
                                  }
                                  error = TDStatusToNSError(status, url);
                                  break;
                          }
                      }

                      // Remove from the pending list all the revs that didn't fail
                      for (TD_Revision* rev in changes.allRevisions) {
                          if (![failedIDs containsObject:rev.docID]) {
                              [self removePending:rev];
                          }
                      }

                      CDTLogVerbose(CDTREPLICATION_LOG_CONTEXT, @"%@: Sent %@", self,
                                 changes.allRevisions);

                  } else if (error && error.code == kTDStatusDuplicate) {
                      // A 412 for the whole batch means we don't know what caused the
                      // failure. Therefore retry all, and be sure to send all attachment
                      // data, as the 412 is caused by mismatched stubs.
                      for (TD_Revision* rev in changes.allRevisions) {
                          [revisionsToRetry addRev:rev];
                      }
                      _sendAllDocumentsWithAttachmentsAsMultipart = YES;
                  } else if (error) {
                      // Another error in the request as a whole; fail replication.
                      self.error = error;
                      [self revisionFailed];
                  }

                  self.changesProcessed += (numDocsToSend - revisionsToRetry.count);

                  if (revisionsToRetry.count > 0) {
                      [self addRevsToInbox:revisionsToRetry];
                  }

                  [self asyncTasksFinished:1];
              }];
}

static TDStatus statusFromBulkDocsResponseItem(NSDictionary* item)
{
    NSString* errorStr = item[@"error"];
    if (!errorStr) return kTDStatusOK;
    // 'status' property is nonstandard; TouchDB returns it, others don't.
    TDStatus status = $castIf(NSNumber, item[@"status"]).intValue;
    if (status >= 400) return status;
    // If no 'status' present, interpret magic hardcoded CouchDB error strings:
    if ($equal(errorStr, @"unauthorized"))
        return kTDStatusUnauthorized;
    else if ($equal(errorStr, @"forbidden"))
        return kTDStatusForbidden;
    else if ($equal(errorStr, @"conflict"))
        return kTDStatusConflict;
    else
        return kTDStatusUpstreamError;
}

- (BOOL)uploadMultipartRevision:(TD_Revision*)rev
{
    // Find all the attachments with "follows" instead of a body, and put 'em in a multipart stream.
    // It's important to scan the _attachments entries in the same order in which they will appear
    // in the JSON, because CouchDB expects the MIME bodies to appear in that same order (see #133).
    TDMultipartWriter* bodyStream = nil;
    NSDictionary* attachments = rev[@"_attachments"];
    for (NSString* attachmentName in [TDCanonicalJSON orderedKeys:attachments]) {
        NSDictionary* attachment = attachments[attachmentName];
        if (attachment[@"follows"]) {
            if (!bodyStream) {
                // Create the HTTP multipart stream:
                bodyStream = [[TDMultipartWriter alloc] initWithContentType:@"multipart/related"
                                                                   boundary:nil];
                [bodyStream setNextPartsHeaders:$dict({ @"Content-Type", @"application/json" })];
                // Use canonical JSON encoder so that _attachments keys will be written in the
                // same order that this for loop is processing the attachments.
                NSData* json = [TDCanonicalJSON canonicalData:rev.properties];
                [bodyStream addData:json];
            }
            NSString* disposition =
                $sprintf(@"attachment; filename=%@", TDQuoteString(attachmentName));
            NSString* contentType = attachment[@"type"];
            NSString* contentEncoding = attachment[@"encoding"];
            [bodyStream setNextPartsHeaders:$dict({ @"Content-Disposition", disposition },
                                                  { @"Content-Type", contentType },
                                                  { @"Content-Encoding", contentEncoding })];
            
            id<CDTBlobReader> blob = [_db blobForAttachmentDict:attachment];
            UInt64 length = 0;
            NSInputStream* inputStream = [blob inputStreamWithOutputLength:&length];
            [bodyStream addStream:inputStream length:length];
        }
    }
    if (!bodyStream) return NO;

    // OK, we are going to upload this on its own:
    self.changesTotal++;
    [self asyncTaskStarted];

    NSString* path = $sprintf(@"%@?new_edits=false", TDEscapeID(rev.docID));
    TDMultipartUploader* uploader =
    [[TDMultipartUploader alloc] initWithSession:self.session URL:TDAppendToURL(_remote, path)
                                        streamer:bodyStream
                                  requestHeaders:self.requestHeaders
                                    onCompletion:^(TDMultipartUploader* uploader, NSError* error) {
                                        if (error) {
                                            if ($equal(error.domain, TDHTTPErrorDomain) &&
                                                error.code == kTDStatusUnsupportedType) {
                                                // Server doesn't like multipart, eh? Fall back to
                                                // JSON.
                                                _dontSendMultipart = YES;
                                                [self uploadJSONRevision:rev];
                                            } else {
                                                self.error = error;
                                                [self revisionFailed];
                                            }
                                        } else {
                                            CDTLogVerbose(CDTREPLICATION_LOG_CONTEXT,
                                                       @"%@: Sent multipart %@", self, rev);
                                            [self removePending:rev];
                                        }
                                        self.changesProcessed++;
                                        [self asyncTasksFinished:1];
                                        [self removeRemoteRequest:uploader];

                                        _uploading = NO;
                                        [self startNextUpload];
                                    }];
    uploader.authorizer = _authorizer;
    [self addRemoteRequest:uploader];
    CDTLogVerbose(CDTREPLICATION_LOG_CONTEXT, @"%@: Queuing %@ (multipart, %lldkb)", self, uploader,
               bodyStream.length / 1024);
    if (!_uploaderQueue) _uploaderQueue = [[NSMutableArray alloc] init];
    [_uploaderQueue addObject:uploader];
    [self startNextUpload];
    return YES;
}

// Fallback to upload a revision if uploadMultipartRevision failed due to the server's rejecting
// multipart format.
- (void)uploadJSONRevision:(TD_Revision*)rev
{
    // Get the revision's properties:
    NSError* error;
    if (![_db inlineFollowingAttachmentsIn:rev error:&error]) {
        self.error = error;
        [self revisionFailed];
        return;
    }

    [self asyncTaskStarted];
    NSString* path = $sprintf(@"%@?new_edits=false", TDEscapeID(rev.docID));
    [self sendAsyncRequest:@"PUT"
                      path:path
                      body:rev.properties
              onCompletion:^(id response, NSError* error) {
                  if (error) {
                      self.error = error;
                      [self revisionFailed];
                  } else {
                      CDTLogVerbose(CDTREPLICATION_LOG_CONTEXT, @"%@: Sent %@ (JSON), response=%@", self,
                                 rev, response);
                      [self removePending:rev];
                  }
                  [self asyncTasksFinished:1];
              }];
}

- (void)startNextUpload
{
    if (!_uploading && _uploaderQueue.count > 0) {
        _uploading = YES;
        TDMultipartUploader* uploader = _uploaderQueue[0];
        CDTLogVerbose(CDTREPLICATION_LOG_CONTEXT, @"%@: Starting %@", self, uploader);
        [uploader start];
        [_uploaderQueue removeObjectAtIndex:0];
    }
}

// Given a revision and an array of revIDs, finds the latest common ancestor revID
// and returns its generation #. If there is none, returns 0.
// static designation was removed in order to use this function outside of this file
// however, it was not declared in the header because we don't really want to expose
// it to users. although it's not needed, specifically state 'extern' here
// in order to be clear on intent.
// Adam Cox, Cloudant, Inc. (2014)
extern int findCommonAncestor(TD_Revision* rev, NSArray* possibleRevIDs)
{
    if (possibleRevIDs.count == 0) return 0;
    NSArray* history = [TD_Database parseCouchDBRevisionHistory:rev.properties];
    NSString* ancestorID = [history firstObjectCommonWithArray:possibleRevIDs];
    if (!ancestorID) return 0;
    int generation;
    if (![TD_Revision parseRevID:ancestorID intoGeneration:&generation andSuffix:NULL])
        generation = 0;
    return generation;
}

@end
