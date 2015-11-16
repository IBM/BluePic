//
//  CDTQUnindexedMatcher.m
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

#import "CDTQUnindexedMatcher.h"
#import "CDTQQueryConstants.h"

#import "CDTQQuerySqlTranslator.h"
#import "CDTQLogging.h"
#import "CDTQValueExtractor.h"
#import "CDTQQueryValidator.h"

#import "CDTDocumentRevision.h"

@implementation CDTQOperatorExpressionNode

@end

@interface CDTQUnindexedMatcher ()

@property (nonatomic, strong) CDTQChildrenQueryNode *root;

@end

@implementation CDTQUnindexedMatcher

#pragma mark Creating matcher

+ (CDTQUnindexedMatcher *)matcherWithSelector:(NSDictionary *)selector
{
    CDTQChildrenQueryNode *root = [CDTQUnindexedMatcher buildExecutionTreeForSelector:selector];

    if (!root) {
        return nil;
    }

    CDTQUnindexedMatcher *matcher = [[CDTQUnindexedMatcher alloc] init];
    matcher.root = root;
    return matcher;
}

+ (CDTQChildrenQueryNode *)buildExecutionTreeForSelector:(NSDictionary *)selector
{
    // At this point we will have a root compound predicate, AND or OR, and
    // the query will be reduced to a single entry:
    // @{ @"$and": @[ ... predicates (possibly compound) ... ] }
    // @{ @"$or": @[ ... predicates (possibly compound) ... ] }

    CDTQChildrenQueryNode *root;
    NSArray *clauses;

    if (selector[AND]) {
        clauses = selector[AND];
        root = [[CDTQAndQueryNode alloc] init];
    } else if (selector[OR]) {
        clauses = selector[OR];
        root = [[CDTQOrQueryNode alloc] init];
    }

    //
    // First handle the simple @"field": @{ @"$operator": @"value" } clauses.
    //

    NSMutableArray *basicClauses = [NSMutableArray array];

    [clauses enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *clause = (NSDictionary *)obj;
        NSString *field = clause.allKeys[0];
        if (![field hasPrefix:@"$"]) {
            [basicClauses addObject:clauses[idx]];
        }
    }];

    // Execution step will evaluate each child node and AND or OR the results.
    for (NSDictionary *expression in basicClauses) {
        CDTQOperatorExpressionNode *node = [[CDTQOperatorExpressionNode alloc] init];
        node.expression = expression;
        [root.children addObject:node];
    }

    //
    // AND and OR subclauses are handled identically whatever the parent is.
    // We go through the query twice to order the OR clauses before the AND
    // clauses, for predictability.
    //

    // Add subclauses that are OR
    [clauses enumerateObjectsUsingBlock:^void(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *clause = (NSDictionary *)obj;
        NSString *field = clause.allKeys[0];
        if ([field isEqualToString:OR]) {
            CDTQQueryNode *orNode =
                [CDTQUnindexedMatcher buildExecutionTreeForSelector:clauses[idx]];
            [root.children addObject:orNode];
        }
    }];

    // Add subclauses that are AND
    [clauses enumerateObjectsUsingBlock:^void(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *clause = (NSDictionary *)obj;
        NSString *field = clause.allKeys[0];
        if ([field isEqualToString:AND]) {
            CDTQQueryNode *andNode =
                [CDTQUnindexedMatcher buildExecutionTreeForSelector:clauses[idx]];
            [root.children addObject:andNode];
        }
    }];

    return root;
}

#pragma mark Matching documents

- (BOOL)matches:(CDTDocumentRevision *)rev
{
    return [self executeSelectorTree:self.root onRevision:rev];
}

#pragma mark Tree walking

- (BOOL)executeSelectorTree:(CDTQQueryNode *)node onRevision:(CDTDocumentRevision *)rev
{
    if ([node isKindOfClass:[CDTQAndQueryNode class]]) {
        BOOL passed = YES;

        CDTQAndQueryNode *andNode = (CDTQAndQueryNode *)node;

//        if ([andNode.children count] == 0) {
//            // well this isn't right, something has gone wrong
//            return NO;
//        }

        for (CDTQQueryNode *child in andNode.children) {
            passed = passed && [self executeSelectorTree:child onRevision:rev];
        }

        return passed;
    }
    if ([node isKindOfClass:[CDTQOrQueryNode class]]) {
        BOOL passed = NO;

        CDTQOrQueryNode *orNode = (CDTQOrQueryNode *)node;
        for (CDTQQueryNode *child in orNode.children) {
            passed = passed || [self executeSelectorTree:child onRevision:rev];
        }

        return passed;

    } else if ([node isKindOfClass:[CDTQOperatorExpressionNode class]]) {
        NSDictionary *expression = ((CDTQOperatorExpressionNode *)node).expression;

        // Here we could have:
        //   { fieldName: { operator: value } }
        // or
        //   { fieldName: { $not: { operator: value } } }

        // Next evaluate the result
        NSString *fieldName = expression.allKeys[0];
        NSDictionary *operatorExpression = expression[fieldName];

        NSString *operator= operatorExpression.allKeys[0];

        // First work out whether we need to invert the result when done
        BOOL invertResult = [operator isEqualToString:NOT];
        if (invertResult) {
            operatorExpression = operatorExpression[NOT];
            operator = operatorExpression.allKeys[0];
        }

        NSObject *expected = operatorExpression[operator];
        NSObject *actual = [CDTQValueExtractor extractValueForFieldName:fieldName fromRevision:rev];
        
        BOOL passed = NO;
        NSArray *specialCaseOperators = @[ MOD, SIZE ];
        if ([specialCaseOperators containsObject:operator]) {
            // If an operator like $mod or $size is found we need to treat the
            // comparison as a special case.
            //
            // $mod: perform modulo arithmetic on the actual value using the first
            //       element in the expected array as the divisor before comparing
            //       the result to the second element in the expected array.
            //
            // $size: check whether the actual value is an array, then compare the
            //        actual array size with the expected value.
            passed = [self actualValue:actual matchesOperator:operator andExpectedValue:expected];
        } else {
            // Since $in is the same as a series of $eq comparisons -
            // Treat them the same by:
            // - Ensuring that both expected and actual are NSArrays.
            // - Convert the $in operator to the $eq operator.
            if (![expected isKindOfClass:[NSArray class]]) {
                expected = @[ expected ];
            }
            if (![actual isKindOfClass:[NSArray class]]) {
                actual = actual ? @[ actual ] : @[ [NSNull null] ];
            }
            if ([operator isEqualToString:IN]) {
                operator = EQ;
            }
            
            for (NSObject *expectedItem in (NSArray *)expected) {
                for (NSObject *actualItem in (NSArray *)actual) {
                    // OR since any actual item can match any value in the expected NSArray
                    passed = passed || [self actualValue:actualItem
                                         matchesOperator:operator
                                        andExpectedValue:expectedItem];
                }
            }
        }
        return invertResult ? !passed : passed;
    } else {
        // We constructed the tree, so shouldn't end up here; error if we do.
        LogError(@"Found unexpected selector execution tree: %@", node);
        return NO;
    }
}

- (BOOL)actualValue:(NSObject *)actual
     matchesOperator:(NSString *) operator
    andExpectedValue:(NSObject *)expected
{
    BOOL passed = NO;

    if ([operator isEqualToString:EQ]) {
        passed = [self eqL:actual R:expected];

    } else if ([operator isEqualToString:LT]) {
        passed = [self ltL:actual R:expected];

    } else if ([operator isEqualToString:LTE]) {
        passed = [self lteL:actual R:expected];

    } else if ([operator isEqualToString:GT]) {
        passed = [self gtL:actual R:expected];

    } else if ([operator isEqualToString:GTE]) {
        passed = [self gteL:actual R:expected];

    } else if ([operator isEqualToString:MOD]) {
        passed = [self modL:actual R:expected];
        
    } else if ([operator isEqualToString:SIZE]) {
        passed = [self sizeL:actual R:expected];
        
    } else if ([operator isEqualToString:EXISTS]) {
        BOOL expectedBool = [((NSNumber *)expected)boolValue];
        BOOL exists = (![actual isEqual:[NSNull null]]);
        passed = (exists == expectedBool);

    } else {
        LogWarn(@"Found unexpected operator in selector: %@", operator);
        passed = NO;  // didn't understand
    }

    return passed;
}

#pragma mark matchers

- (BOOL)eqL:(NSObject *)l R:(NSObject *)r { return [l isEqual:r]; }

//
// Try to respect SQLite's ordering semantics:
//  1. NULL
//  2. INT/REAL
//  3. TEXT
//  4. BLOB
- (BOOL)ltL:(NSObject *)l R:(NSObject *)r
{
    if ([l isEqual:[NSNull null]]) {
        return NO;  // NSNull fails all lt/gt/lte/gte tests

    } else if (!([l isKindOfClass:[NSString class]] || [l isKindOfClass:[NSNumber class]])) {
        LogWarn(@"Value in document not NSNumber or NSString: %@", l);
        return NO;  // Not sure how to compare values that are not numbers or strings

    } else if ([l isKindOfClass:[NSString class]]) {
        if ([r isKindOfClass:[NSNumber class]]) {
            return NO;  // INT < STRING
        }

        NSString *lStr = (NSString *)l;
        NSString *rStr = (NSString *)r;

        NSComparisonResult result = [lStr compare:rStr];
        return (result == NSOrderedAscending);

    } else if ([l isKindOfClass:[NSNumber class]]) {
        if ([r isKindOfClass:[NSString class]]) {
            return YES;  // INT < STRING
        }

        NSNumber *lNum = (NSNumber *)l;
        NSNumber *rNum = (NSNumber *)r;

        NSComparisonResult result = [lNum compare:rNum];
        return (result == NSOrderedAscending);

    } else {
        return NO;  // Catch all which we cannot reach
    }
}

- (BOOL)lteL:(NSObject *)l R:(NSObject *)r
{
    if ([l isEqual:[NSNull null]]) {
        return NO;  // NSNull fails all lt/gt/lte/gte tests
    }

    if (!([l isKindOfClass:[NSString class]] || [l isKindOfClass:[NSNumber class]])) {
        LogWarn(@"Value in document not NSNumber or NSString: %@", l);
        return NO;  // Not sure how to compare values that are not numbers or strings
    }

    return [self ltL:l R:r] || [l isEqual:r];
}

- (BOOL)gtL:(NSObject *)l R:(NSObject *)r
{
    if ([l isEqual:[NSNull null]]) {
        return NO;  // NSNull fails all lt/gt/lte/gte tests
    }

    if (!([l isKindOfClass:[NSString class]] || [l isKindOfClass:[NSNumber class]])) {
        LogWarn(@"Value in document not NSNumber or NSString: %@", l);
        return NO;  // Not sure how to compare values that are not numbers or strings
    }

    return ![self lteL:l R:r];
}

- (BOOL)gteL:(NSObject *)l R:(NSObject *)r
{
    if ([l isEqual:[NSNull null]]) {
        return NO;  // NSNull fails all lt/gt/lte/gte tests
    }

    if (!([l isKindOfClass:[NSString class]] || [l isKindOfClass:[NSNumber class]])) {
        LogWarn(@"Value in document not NSNumber or NSString: %@", l);
        return NO;  // Not sure how to compare values that are not numbers or strings
    }

    return ![self ltL:l R:r];
}

- (BOOL)modL:(NSObject *)l R:(NSObject *)r
{
    if (![l isKindOfClass:[NSNumber class]]) {
        return NO;
    }

    // r should be an NSArray containing two numbers.  These two numbers are assured
    // to be integers and the divisor is assured to not be 0.  This would have been
    // handled during normalization and validation.
    NSInteger divisor = [((NSArray *)r)[0] integerValue];
    NSInteger expectedRemainder = [((NSArray *)r)[1] integerValue];
    
    // Calculate the actual remainder based on the truncated whole
    // number value of l which is the actual number from the document.
    // This is the desired behavior to relicate the SQL engine.
    NSInteger actualRemainder = [(NSNumber *)l integerValue] % divisor;
    
    return actualRemainder == expectedRemainder;
}

- (BOOL)sizeL:(NSObject *)l R:(NSObject *)r
{
    // The actual value must be an array and the expected value must be a number in
    // order to perform a size comparison.
    if (![l isKindOfClass:[NSArray class]] || ![r isKindOfClass:[NSNumber class]]) {
        return NO;
    }
    
    NSNumber *actualSize = [NSNumber numberWithInteger:((NSArray *) l).count];
    NSNumber *expectedSize = (NSNumber *)r;
    
    return [actualSize isEqualToNumber:expectedSize];
}

@end
