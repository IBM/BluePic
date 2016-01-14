//
//  CDTQUnindexedMatcher.h
//  Pods
//
//  Created by Michael Rhodes on 31/10/2014.
//  Copyright (c) 2014 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import <Foundation/Foundation.h>

#import "CDTQQuerySqlTranslator.h"

@class CDTDocumentRevision;

@interface CDTQOperatorExpressionNode : CDTQQueryNode

@property (nonatomic, strong) NSDictionary *expression;

@end

/**
 Determine whether a document matches a selector.

 This class is used when a selector cannot be satisfied using
 indexes alone. It takes a selector, compiles it into an internal
 representation and is able to then determine whether a document
 matches that selector.

 The matcher works by first creating a simple tree, which is then
 executed against each document it's asked to match.


 Some examples:

 AND : [ { x: X }, { y: Y } ]

 This can be represented by a two operator expressions and AND tree node:

        AND
       /   \
 { x: X }  { y: Y }


 OR : [ { x: X }, { y: Y } ]

 This is a single OR node and two operator expressions:

         OR
       /    \
 { x: X }  { y: Y }

 The interpreter then unions the results.


 OR : [ { AND : [ { x: X }, { y: Y } ] }, { y: Y } ]

 This requires a more complex tree:

               OR
              /   \
          AND    { y: Y }
         /   \
  { x: X }  { y: Y }


 AND : [ { OR : [ { x: X }, { y: Y } ] }, { y: Y } ]

 This is really the most complex situation:

               AND
              /   \
           OR   { y: Y }
         /    \
  { x: X }  { y: Y }

 These basic patterns can be composed into more complicate structures.
 */
@interface CDTQUnindexedMatcher : NSObject

/**
 Return a new initialised matcher.

 Assumes selector is valid as we're calling this late in
 the query processing.
 */
+ (CDTQUnindexedMatcher *)matcherWithSelector:(NSDictionary *)selector;

/**
 Returns YES if a document matches this matcher's selector.
 */
- (BOOL)matches:(CDTDocumentRevision *)rev;

@end
