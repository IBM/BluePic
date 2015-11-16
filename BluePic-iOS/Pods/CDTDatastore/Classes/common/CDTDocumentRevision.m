//
//  CDTDocumentRevision.m
//  CloudantSync
//
//  Created by Michael Rhodes on 02/07/2013.
//  Copyright (c) 2013 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "CDTDocumentRevision.h"
#import "Attachments/CDTAttachment.h"
#import "TDJSON.h"
#import "TD_Revision.h"
#import "TD_Body.h"
#import "TD_Database.h"
#import "CDTLogging.h"

#import "CDTChangedDictionary.h"

@interface CDTDocumentRevision ()

@property (nonatomic, strong, readonly) TD_RevisionList *revs;
@property (nonatomic, strong, readonly) NSArray *revsInfo;
@property (nonatomic, strong, readonly) NSArray *conflicts;
@property (nonatomic, strong, readonly) TD_Body *td_body;

@end

@implementation CDTDocumentRevision

@synthesize docId = _docId;
@synthesize revId = _revId;
@synthesize deleted = _deleted;
@synthesize sequence = _sequence;

+ (CDTDocumentRevision *)revision
{
    return [[CDTDocumentRevision alloc] initWithDocId:nil
                                           revisionId:nil
                                                 body:[NSMutableDictionary dictionary]
                                          attachments:[NSMutableDictionary dictionary]];
}

+ (CDTDocumentRevision *)revisionWithDocId:(NSString *)docId
{
    return [[CDTDocumentRevision alloc] initWithDocId:docId
                                           revisionId:nil
                                                 body:[NSMutableDictionary dictionary]
                                          attachments:[NSMutableDictionary dictionary]];
}

+ (CDTDocumentRevision *)revisionWithDocId:(NSString *)docId revId:(NSString *)revId
{
    return [[CDTDocumentRevision alloc] initWithDocId:docId
                                           revisionId:revId
                                                 body:[NSMutableDictionary dictionary]
                                          attachments:[NSMutableDictionary dictionary]];
}

+ (CDTDocumentRevision *)createRevisionFromJson:(NSDictionary *)jsonDict
                                    forDocument:(NSURL *)documentURL
                                          error:(NSError *__autoreleasing *)error
{
    // these values are defined http://docs.couchdb.org/en/latest/api/document/common.html

    NSArray *allowed_prefixedValues = @[
        @"_id",
        @"_rev",
        @"_deleted",
        @"_attachments",
        @"_conflicts",
        @"_deleted_conflicts",
        @"_local_seq",
        @"_revs_info",
        @"_revisions"
    ];
    if (*error) return nil;

    NSPredicate *_prefixPredicate = [NSPredicate predicateWithFormat:@" self BEGINSWITH '_' \
                                                                        && NOT (self IN %@)",
                                                                     allowed_prefixedValues];

    NSArray *invalidKeys = [[jsonDict allKeys] filteredArrayUsingPredicate:_prefixPredicate];

    if ([invalidKeys count] != 0) {
        *error = TDStatusToNSError(kTDStatusBadJSON, nil);
        return nil;
    }

    NSString *docId = [jsonDict objectForKey:@"_id"];
    NSString *revId = [jsonDict objectForKey:@"_rev"];
    BOOL deleted = [[jsonDict objectForKey:@"_deleted"] boolValue];
    NSDictionary *attachmentData = [jsonDict objectForKey:@"_attachments"];

    NSMutableDictionary *attachments = [NSMutableDictionary dictionary];

    // build the attachment objects
    for (NSString *key in [attachmentData allKeys]) {
        
        NSURLComponents *documentUrlComponents = [NSURLComponents componentsWithString:[documentURL absoluteString]];
        NSString *documentPathString = documentUrlComponents.path;
        NSString *attachmentPath = [NSString stringWithFormat:@"%@/%@", documentPathString,key];
        documentUrlComponents.path = attachmentPath;
        
        
        CDTSavedHTTPAttachment *attachment =
            [CDTSavedHTTPAttachment createAttachmentWithName:key
                                                    JSONData:[attachmentData objectForKey:key]
                                               attachmentURL:[documentUrlComponents URL]
                                                       error:error];
        if (*error) {
            return nil;
        }

        [attachments setObject:attachment forKey:key];
    }

    NSMutableDictionary *body = [jsonDict mutableCopy];
    [body removeObjectsForKeys:allowed_prefixedValues];

    return [[CDTDocumentRevision alloc] initWithDocId:docId
                                           revisionId:revId
                                                 body:body
                                              deleted:deleted
                                          attachments:attachments
                                             sequence:0];
}

- (id)initWithDocId:(NSString *)docId
         revisionId:(NSString *)revId
               body:(NSMutableDictionary *)body
        attachments:(NSMutableDictionary *)attachments
{
    return [self initWithDocId:docId
                    revisionId:revId
                          body:body
                       deleted:NO
                   attachments:attachments
                      sequence:0];
}

- (id)initWithDocId:(NSString *)docId
         revisionId:(NSString *)revId
               body:(NSDictionary *)body
            deleted:(BOOL)deleted
        attachments:(NSDictionary *)attachments
           sequence:(SequenceNumber)sequence
{
    self = [super init];

    if (self) {
        _docId = docId;
        _revId = revId;
        _deleted = deleted;
        _attachments = [CDTChangedDictionary dictionaryCopyingContents:attachments];
        _sequence = sequence;
        if (!deleted && body) {
            NSMutableDictionary *mutableCopy = [body mutableCopy];

            NSPredicate *_prefixPredicate =
                [NSPredicate predicateWithFormat:@" self BEGINSWITH '_'"];

            NSArray *keysToRemove = [[body allKeys] filteredArrayUsingPredicate:_prefixPredicate];

            [mutableCopy removeObjectsForKeys:keysToRemove];
            _body = [CDTChangedDictionary dictionaryCopyingContents:mutableCopy];
        } else {
            _body = [CDTChangedDictionary dictionaryCopyingContents:@{}];
        }

        _changed = NO;
        ((CDTChangedDictionary *)_body).delegate = self;
        ((CDTChangedDictionary *)_attachments).delegate = self;
    }
    return self;
}

- (BOOL)isFullRevision { return YES; }

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (NSData *)documentAsDataError:(NSError *__autoreleasing *)error
{
    NSError *innerError = nil;

    NSData *json = [[TDJSON dataWithJSONObject:self.body options:0 error:&innerError] copy];

    if (!json) {
        CDTLogWarn(CDTDOCUMENT_REVISION_LOG_CONTEXT, @"CDTDocumentRevision: couldn't convert to JSON");
        *error = innerError;
        return nil;
    }

    return json;
}

- (CDTDocumentRevision *)copy
{
    CDTDocumentRevision *copy = [[CDTDocumentRevision alloc] initWithDocId:self.docId
                                                                revisionId:self.revId
                                                                      body:self.body
                                                               attachments:self.attachments];
    return copy;
}

- (void)contentOfObjectDidChange:(NSObject *)object { self.changed = YES; }

- (void)setBody:(NSDictionary *)body
{
    self.changed = YES;

    // No need to wrap the dictionary with a CDTChangedDictionary
    // because we've already marked ourselves as changed.
    _body = [body mutableCopy];
}

- (void)setAttachments:(NSMutableDictionary *)attachments
{
    self.changed = YES;

    // No need to wrap the dictionary with a CDTChangedDictionary
    // because we've already marked ourselves as changed.
    _attachments = [attachments mutableCopy];
}

@end
