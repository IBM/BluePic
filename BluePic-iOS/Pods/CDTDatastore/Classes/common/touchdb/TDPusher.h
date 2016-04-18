//
//  TDPusher.h
//  TouchDB
//
//  Created by Jens Alfke on 12/5/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//
//  Modifications for this distribution by Cloudant, Inc., Copyright (c) 2014 Cloudant, Inc.
//

#import "TDReplicator.h"
#import "TDMisc.h"

/** Replicator that pushes to a remote CouchDB. */
@interface TDPusher : TDReplicator {
    BOOL _createTarget;
    BOOL _creatingTarget;
    BOOL _observing;
    BOOL _uploading;
    NSMutableArray* _uploaderQueue;
    BOOL _dontSendMultipart;
    NSMutableIndexSet* _pendingSequences;
    SequenceNumber _maxPendingSequence;

    /** YES if all further documents with attachments should:
       * Be sent via multipart/related
       * Have all attachment data sent (not just stubs)
     */
    BOOL _sendAllDocumentsWithAttachmentsAsMultipart;
}

@property BOOL createTarget;

/** Block called to filter document revisions that are pushed to the remote server. */
@property (nonatomic, copy) TD_FilterBlock filter;

@end
