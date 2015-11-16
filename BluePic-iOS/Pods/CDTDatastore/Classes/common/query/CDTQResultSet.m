//
//  CDTQResultSet.m
//
//  Created by Mike Rhodes on 2014-09-27
//  Copyright (c) 2014 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "CDTQResultSet.h"
#import "CDTQLogging.h"
#import "CDTQProjectedDocumentRevision.h"
#import "CDTQUnindexedMatcher.h"

#import <CloudantSync.h>

@interface CDTQResultSet ()
@property (nonatomic, strong, readwrite) NSArray *fields;
@property (nonatomic) NSUInteger skip;
@property (nonatomic) NSUInteger limit;
@property (nonatomic, strong) CDTQUnindexedMatcher *matcher;
@end

@implementation CDTQResultSetBuilder

- (CDTQResultSet *)build;
{
    return [[CDTQResultSet alloc] initWithBuilder:self];
}

@end

@implementation CDTQResultSet

- (instancetype)initWithBuilder:(CDTQResultSetBuilder *)builder
{
    self = [super init];
    if (self) {
        _originalDocumentIds = builder.docIds;
        _datastore = builder.datastore;
        _fields = builder.fields;
        _skip = builder.skip;
        _limit = builder.limit;
        _matcher = builder.matcher;
    }
    return self;
}

+ (instancetype)resultSetWithBlock:(CDTQResultSetBuilderBlock)block
{
    NSParameterAssert(block);

    CDTQResultSetBuilder *builder = [[CDTQResultSetBuilder alloc] init];
    block(builder);
    return [builder build];
}

- (NSArray /* NSString */ *)documentIds
{
    // This is implemented using -enumerateObjectsUsingBlock so that when we're using
    // skip, limit or post hoc matching the documentIds array is output correctly.
    NSMutableArray *accumulator = [NSMutableArray array];
    [self enumerateObjectsUsingBlock:^(CDTDocumentRevision *rev, NSUInteger idx, BOOL *stop) {
        [accumulator addObject:rev.docId];
    }];
    return [NSArray arrayWithArray:accumulator];
}

- (void)enumerateObjectsUsingBlock:(void (^)(CDTDocumentRevision *rev, NSUInteger idx,
                                             BOOL *stop))block
{
    NSUInteger idx = 0;

    NSUInteger nSkipped = 0;   // used for skip
    NSUInteger nReturned = 0;  // used for limit

    // Avoid method calls in the loop
    NSUInteger skip = self.skip;
    NSUInteger limit = self.limit;
    CDTQUnindexedMatcher *matcher = self.matcher;
    NSArray *fields = self.fields;

    BOOL stop = NO;  // user stopped, or we returned `limit` results
    NSUInteger batchSize = 50;
    NSRange range = NSMakeRange(0, batchSize);
    while (range.location < _originalDocumentIds.count) {
        range.length = MIN(batchSize, _originalDocumentIds.count - range.location);
        NSArray *batch = [_originalDocumentIds subarrayWithRange:range];

        NSArray *docs = [_datastore getDocumentsWithIds:batch];

        for (CDTDocumentRevision *rev in docs) {
            CDTDocumentRevision *innerRev = rev;  // allows us to replace later if projecting

            // Apply post-hoc matcher
            if (matcher && ![matcher matches:innerRev]) {
                continue;
            }

            // Apply skip (skip == 0 means disable)
            if (skip > 0 && nSkipped < skip) {
                nSkipped++;
                continue;
            }

            // Apply projection if result matches
            if (fields) {
                innerRev =
                    [CDTQResultSet projectFields:self.fields fromRevision:rev datastore:_datastore];
            }

            // Run callback
            block(innerRev, idx, &stop);
            if (stop) {
                break;
            }
            idx++;

            // Apply limit (limit == 0 means disable)
            nReturned++;
            if (limit > 0 && nReturned >= limit) {
                stop = YES;
                break;
            }
        }

        if (stop) {
            break;
        }

        range.location += range.length;
    }
}

+ (CDTDocumentRevision *)projectFields:(NSArray *)fields
                          fromRevision:(CDTDocumentRevision *)rev
                             datastore:(CDTDatastore *)datastore
{
    // grab the dictionary filter fields and rebuild object
    NSDictionary *body = [rev.body dictionaryWithValuesForKeys:fields];
    return [[CDTQProjectedDocumentRevision alloc] initWithDocId:rev.docId
                                                     revisionId:rev.revId
                                                           body:body
                                                        deleted:rev.deleted
                                                    attachments:rev.attachments
                                                       sequence:rev.sequence
                                                      datastore:datastore];
}

@end
