//
//  CDTQQueryValidator.m
//
//  Created by Rhys Short on 06/11/2014.
//  Copyright (c) 2014 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "CDTQQueryValidator.h"
#import "CDTQQueryConstants.h"

#import "CDTQLogging.h"

@implementation CDTQQueryValidator

// negatedShortHand is used for operator shorthand processing.
// A shorthand operator like $ne has a longhand representation
// that is { "$not" : { "$eq" : ... } }.  Therefore the negation
// of the $ne operator is $eq.
+ (NSDictionary *)negatedShortHand
{
    static NSDictionary *negatedShortHandDict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        negatedShortHandDict = @{ NE : EQ ,
                                  NIN : IN };
    });
    return negatedShortHandDict;
}

+ (NSDictionary *)normaliseAndValidateQuery:(NSDictionary *)query
{
    bool isWildCard = [query count] == 0;

    // First expand the query to include a leading compound predicate
    // if there isn't one already.
    query = [CDTQQueryValidator addImplicitAnd:query];

    // At this point we will have a single entry dict, key AND or OR,
    // forming the compound predicate.
    NSString *compoundOperator = [query allKeys][0];
    NSArray *predicates = query[compoundOperator];
    if ([predicates isKindOfClass:[NSArray class]]) {
        // Next make sure all the predicates have an operator -- the EQ
        // operator is implicit and we need to add it if there isn't one.
        // Take
        //     [ {"field1": "mike"}, ... ]
        // and make
        //     [ {"field1": { "$eq": "mike"} }, ... ]
        predicates = [CDTQQueryValidator addImplicitEq:predicates];
        
        // Then all shorthand operators like $ne, if present, need to be
        // converted to their logical longhand equivalent.
        // Take
        //     [ { "field1": { "$ne": "mike"} }, ... ]
        // and make
        //     [ { "field1": { "$not" : { "$eq": "mike"} } }, ... ]
        predicates = [CDTQQueryValidator handleShortHandOperators:predicates];
        
        // Now in the event that extraneous $not operators exist in the query,
        // these operators must be compressed down to the their logical equivalent.
        // Take
        //     [ { "field1": { "$not" : { $"not" : { "$eq": "mike"} } } }, ... ]
        // and make
        //     [ { "field1": { "$eq": "mike"} }, ... ]
        predicates = [CDTQQueryValidator compressMultipleNotOperators:predicates];
        
        // Here we ensure that all non-whole number arguments included in a $mod
        // clause are truncated.  This provides for consistent behavior between
        // the SQL engine and the unindexed matcher.
        // Take
        //     [ { "field1": { "$mod" : [ 2.6, 1.7] } }, ... ]
        // and make
        //     [ { "field1": { "$mod" : [ 2, 1 ] } }, ... ]
        predicates = [CDTQQueryValidator truncateModArguments:predicates];
    }

    NSDictionary *selector = @{compoundOperator : predicates};
    if (isWildCard) {
        return selector;
    } else if ([CDTQQueryValidator validateSelector:selector]) {
        return selector;
    }

    return nil;
}

#pragma mark Normalization methods
+ (NSDictionary *)addImplicitAnd:(NSDictionary *)query
{
    // query is:
    //  either @{ @"field1": @"value1", ... } -- we need to add $and
    //  or     @{ @"$and": @[ ... ] } -- we don't
    //  or     @{ @"$or": @[ ... ] } -- we don't

    if (query.count == 1 && (query[AND] || query[OR])) {
        return query;
    } else {
        // Take
        //     @{"field1": @"mike", ...}
        //     @{"field1": @[ @"mike", @"bob" ], ...}
        // and make
        //     @[ @{"field1": @"mike"}, ... ]
        //     @[ @{"field1": @[ @"mike", @"bob" ]}, ... ]

        NSMutableArray *andClause = [NSMutableArray array];
        for (NSString *k in query) {
            NSObject *predicate = query[k];
            [andClause addObject:@{k : predicate}];
        }
        return @{AND : [NSArray arrayWithArray:andClause]};
    }
}

+ (NSArray *)addImplicitEq:(NSArray *)andClause
{
    NSMutableArray *accumulator = [NSMutableArray array];

    for (NSDictionary *fieldClause in andClause) {
        // fieldClause is:
        //  either @{ @"field1": @"mike"} -- we need to add the $eq operator
        //  or     @{ @"field1": @{ @"$operator": @"value" } -- we don't
        //  or     @{ @"$and": @[ ... ] } -- we don't
        //  or     @{ @"$or": @[ ... ] } -- we don't
        NSObject *predicate = nil;
        NSString *fieldName = nil;
        if ([fieldClause isKindOfClass:[NSDictionary class]] && [fieldClause count] != 0) {
            fieldName = fieldClause.allKeys[0];
            predicate = fieldClause[fieldName];
        } else {
            // if this isn't a dictionary, we don't know what to do so add the clause
            // to the accumulator to be dealt with later as part of the final selector
            // validation.
            [accumulator addObject:fieldClause];
            continue;
        }

        // If the clause isn't a special clause (the field name starts with
        // $, e.g., $and), we need to check whether the clause already
        // has an operator. If not, we need to add the implicit $eq.
        if (![fieldName hasPrefix:@"$"]) {
            if (![predicate isKindOfClass:[NSDictionary class]]) {
                predicate = @{EQ : predicate};
            }
        } else if ([predicate isKindOfClass:[NSArray class]]) {
            predicate = [CDTQQueryValidator addImplicitEq:(NSArray *)predicate];
        }

        [accumulator addObject:@{fieldName : predicate}];  // can't put nil in this
    }

    return [NSArray arrayWithArray:accumulator];
}

+ (NSArray *)handleShortHandOperators:(NSArray *)clause
{
    NSMutableArray *accumulator = [NSMutableArray array];
    
    for (NSDictionary *fieldClause in clause) {
        NSObject *predicate = nil;
        NSString *fieldName = nil;
        if ([fieldClause isKindOfClass:[NSDictionary class]] && [fieldClause count] != 0) {
            fieldName = fieldClause.allKeys[0];
            predicate = fieldClause[fieldName];
            if ([fieldName hasPrefix:@"$"] && [predicate isKindOfClass:[NSArray class]]) {
                predicate = [CDTQQueryValidator handleShortHandOperators:(NSArray *) predicate];
            } else if ([predicate isKindOfClass:[NSDictionary class]] &&
                       [(NSDictionary *)predicate count] != 0) {
                // if the clause isn't a special clause (the field name starts with
                // $, e.g., $and), we need to check whether the clause has a shorthand
                // operator like $ne. If it does, we need to convert it to its longhand
                // version.
                // Take:  { "$ne" : ... }
                // Make:  { "$not" : { "$eq" : ... } }
                predicate = [CDTQQueryValidator replaceWithLonghand:(NSDictionary *)predicate];
            } else {
                [accumulator addObject:fieldClause];
                continue;
            }
        } else {
            // if this isn't a dictionary, we don't know what to do so add the clause
            // to the accumulator to be dealt with later as part of the final selector
            // validation.
            [accumulator addObject:fieldClause];
            continue;
        }
        
        [accumulator addObject:@{fieldName : predicate}];  // can't put nil in this
    }
    
    return [NSArray arrayWithArray:accumulator];
}

/**
 * This method traverses the predicate dictionary until it reaches the last operator
 * in the tree, it then checks it for a shorthand representation.  If one exists then
 * that shorthand representation is replaced with its longhand version.
 * For example:   { "$ne" : ... }
 * is replaced by { "$not" : { "$eq" : ... } }
 */
+ (NSDictionary *)replaceWithLonghand:(NSDictionary *)predicate
{
    if (!predicate || [predicate count] == 0) {
        return predicate;
    }
    
    NSString *operator = predicate.allKeys[0];
    NSObject *subPredicate = predicate[operator];
    if ([subPredicate isKindOfClass:[NSDictionary class]]) {
        // Recurse down nested predicates, like { $not: { $not: { $ne: "blah" } } }
        return @{ operator: [CDTQQueryValidator replaceWithLonghand:(NSDictionary *)subPredicate] };
    } else if ([CDTQQueryValidator negatedShortHand][operator]) {
        // We got to the end and found an expandable operator, { $ne: "blah" }
        return @{ NOT: @{ [CDTQQueryValidator negatedShortHand][operator] : subPredicate } };
    } else {
        // We got to the end and found an normal operator, { $eq: "blah" }
        return @{ operator: subPredicate };
    }
    
}

/**
 * This method takes a string of $not operators down to either none or a single $not
 * operator.  For example:  { "$not" : { "$not" : { "$eq" : "mike" } } }
 * should compress down to  { "$not" : { "$eq" : "mike" } }
 */
+ (NSArray *)compressMultipleNotOperators:(NSArray *)clause
{
    NSMutableArray *accumulator = [NSMutableArray array];
    
    for (NSDictionary *fieldClause in clause) {
        NSObject *predicate = nil;
        NSString *fieldName = nil;
        if ([fieldClause isKindOfClass:[NSDictionary class]] && [fieldClause count] != 0) {
            fieldName = fieldClause.allKeys[0];
            predicate = fieldClause[fieldName];
        } else {
            // if this isn't a dictionary, we don't know what to do so add the clause
            // to the accumulator to be dealt with later as part of the final selector
            // validation.
            [accumulator addObject:fieldClause];
            continue;
        }
        
        if ([fieldName hasPrefix:@"$"] && [predicate isKindOfClass:[NSArray class]]) {
            predicate = [CDTQQueryValidator compressMultipleNotOperators:(NSArray *) predicate];
        } else {
            NSObject *operatorPredicate = nil;
            NSString *operator = nil;
            if ([predicate isKindOfClass:[NSDictionary class]] &&
                [(NSDictionary *)predicate count] != 0) {
                operator = ((NSDictionary *)predicate).allKeys[0];
                operatorPredicate = ((NSDictionary *)predicate)[operator];
            } else {
                // if this isn't a dictionary, we don't know what to do so add the clause
                // to the accumulator to be dealt with later as part of the final selector
                // validation.
                [accumulator addObject:fieldClause];
                continue;
            }
            if ([operator isEqualToString:NOT]) {
                // If a $not operator is encountered we need to check for
                // a series of nested $not operators.
                BOOL notOpFound = YES;
                BOOL negateOperator = NO;
                NSObject *originalOperatorPredicate = operatorPredicate;
                while (notOpFound) {
                    // if a series of nested $not operators are found then they need to
                    // be compressed down to one $not operator or in the case of an
                    // even set of $not operators, down to zero $not operators.
                    if ([operatorPredicate isKindOfClass:[NSDictionary class]]) {
                        NSDictionary *notClause = (NSDictionary *)operatorPredicate;
                        NSString *nextOperator = notClause.allKeys[0];
                        if ([nextOperator isEqualToString:NOT]) {
                            // Each time we find a $not operator we flip the negateOperator's
                            // boolean value.
                            negateOperator = !negateOperator;
                            operatorPredicate = notClause[nextOperator];
                        } else {
                            notOpFound = NO;
                        }
                    } else {
                        // unexpected condition - revert back to original
                        operatorPredicate = originalOperatorPredicate;
                        negateOperator = NO;
                        notOpFound = NO;
                    }
                }
                if (negateOperator) {
                    NSDictionary *operatorPredicateDict = (NSDictionary *)operatorPredicate;
                    operator = operatorPredicateDict.allKeys[0];
                    operatorPredicate = operatorPredicateDict[operator];
                }
                predicate = @{ operator : operatorPredicate };
            }
        }
        
        [accumulator addObject:@{fieldName : predicate}];  // can't put nil in this
    }
    
    return [NSArray arrayWithArray:accumulator];
}

+ (NSArray *)truncateModArguments:(NSArray *)clause
{
    NSMutableArray *accumulator = [NSMutableArray array];
    
    for (NSDictionary *fieldClause in clause) {
        NSObject *predicate = nil;
        NSString *fieldName = nil;
        if ([fieldClause isKindOfClass:[NSDictionary class]] && [fieldClause count] != 0) {
            fieldName = fieldClause.allKeys[0];
            predicate = fieldClause[fieldName];
        } else {
            // if this isn't a dictionary, we don't know what to do so add the clause
            // to the accumulator to be dealt with later as part of the final selector
            // validation.
            [accumulator addObject:fieldClause];
            continue;
        }
        
        // If the clause isn't a special clause (the field name starts with
        // $, e.g., $and), we need to check whether the clause has a $mod
        // operator.  If it does then "truncate" all decimal notation
        // in the arguments array by casting the array elements as NSInteger.
        if (![fieldName hasPrefix:@"$"]) {
            if ([predicate isKindOfClass:[NSDictionary class]]) {
                // If $mod operator is found as a key and the value is an array
                if ([((NSDictionary *)predicate)[MOD] isKindOfClass:[NSArray class]]) {
                    // Step through the array and cast all numbers as integers
                    NSArray *rawArguments = ((NSDictionary *)predicate)[MOD];
                    NSMutableArray *arguments = [NSMutableArray array];
                    for (NSObject *rawArgument in rawArguments) {
                        if ([rawArgument isKindOfClass:[NSNumber class]]) {
                            NSInteger argument = [(NSNumber *)rawArgument integerValue];
                            [arguments addObject:[NSNumber numberWithInteger:argument]];
                        } else {
                            // If not a number then this will be caught during upcoming validation.
                            [arguments addObject:rawArgument];
                        }
                    }
                    predicate = @{ MOD: [NSArray arrayWithArray:arguments] };
                }
            }
        } else if ([predicate isKindOfClass:[NSArray class]]) {
            predicate = [CDTQQueryValidator truncateModArguments:(NSArray *)predicate];
        }
        
        [accumulator addObject:@{fieldName : predicate}];  // can't put nil in this
    }
    
    return [NSArray arrayWithArray:accumulator];
}

#pragma validation class methods

/**
 * This method runs the list of clauses making up the selector through a series of
 * validation steps and returns whether the clause list is valid or not.  An error 
 * is logged if the clause list is found to be invalid.
 *
 * @param clauses An NSArray of clauses making up a query selector
 * @param textClauseLimitReached A flag used to track the text clause limit
 *                               throughout the validation process.  The
 *                               current limit is one text clause per query.
 * @return YES/NO whether the list of clauses passed validation.
 */
+ (BOOL)validateCompoundOperatorClauses:(NSArray *)clauses
                    withTextClauseLimit:(BOOL *)textClauseLimitReached
{
    BOOL valid = NO;

    for (id obj in clauses) {
        valid = NO;
        if (![obj isKindOfClass:[NSDictionary class]]) {
            LogError(@"Operator argument must be a dictionary %@", [clauses description]);
            break;
        }
        NSDictionary *clause = (NSDictionary *)obj;
        if ([clause count] != 1) {
            LogError(@"Operator argument clause should only have one key value pair: %@",
                     [clauses description]);
            break;
        }

        NSString *key = [obj allKeys][0];
        if ([@[ OR, NOT, AND ] containsObject:key]) {
            // this should have an array as top level type
            id compoundClauses = [obj objectForKey:key];
            if ([CDTQQueryValidator validateCompoundOperatorOperand:compoundClauses]) {
                // validate array
                valid = [CDTQQueryValidator validateCompoundOperatorClauses:compoundClauses
                                                        withTextClauseLimit:textClauseLimitReached];
            }
        } else if (![key hasPrefix:@"$"]) {
            // this should have a dict
            // send this for validation
            valid = [CDTQQueryValidator validateClause:[obj objectForKey:key]];
        } else if ([key.lowercaseString isEqualToString:TEXT]) {
            // this should have a dict
            // send this for validation
            
            valid = [CDTQQueryValidator validateTextClause:clause[key]
                                       withTextClauseLimit:textClauseLimitReached];
        } else {
            LogError(@"%@ operator cannot be a top level operator", key);
            break;
        }

        if (!valid) {
            break;  // if we have gotten here with valid being no, we should abort
        }
    }

    return valid;
}

+ (BOOL)validateClause:(NSDictionary *)clause
{
    // The replaceWithLonghand: method translates something like { "$ne" : "blah" }
    // to { "$not" : { "$eq" : "blah" } } before reaching this validation.  So
    // operators like $ne and $nin will be negated $eq and $in by the time this
    // validation is reached.
    NSArray *validOperators =  @[ EQ, LT, GT, EXISTS, NOT, GTE, LTE, IN, MOD, SIZE ];

    if ([clause count] == 1) {
        NSString *operator= [clause allKeys][0];

        if ([validOperators containsObject:operator]) {
            // contains correct operator
            id clauseOperand = [clause objectForKey:[clause allKeys][0]];
            // handle special case, $not is the only op that expects a dict
            if ([operator isEqualToString:NOT]) {
                return [clauseOperand isKindOfClass:[NSDictionary class]] &&
                       [CDTQQueryValidator validateClause:clauseOperand];

            } else if ([operator isEqualToString:IN]) {
                return [clauseOperand isKindOfClass:[NSArray class]] &&
                       [CDTQQueryValidator validateListValues:clauseOperand];
            } else {
                return [CDTQQueryValidator validatePredicateValue:clauseOperand
                                                      forOperator:operator];
            }
        }
    }

    return NO;
}

/**
 * This method handles the special case where a text search clause is encountered.
 * This case is special because a $text operator expects an NSDictionary value whose 
 * key can only be the $search operator.
 *
 * @param clause The text clause to validate
 * @param textClauseLimitReached A flag used to track the text clause limit
 *                               throughout the validation process.  The
 *                               current limit is one text clause per query.
 * @return YES/NO whether the clause is valid
 */
+ (BOOL)validateTextClause:(NSObject *)clause withTextClauseLimit:(BOOL *)textClauseLimitReached
{
    if (![clause isKindOfClass:[NSDictionary class]]) {
        LogError(@"Text search expects an NSDictionary, found %@ instead.", clause);
        return NO;
    }
    
    NSDictionary *textClause = (NSDictionary *) clause;
    if ([textClause count] != 1) {
        LogError(@"Unexpected content %@ in text search.", textClause);
        return NO;
    }
    
    NSString *operator = [textClause allKeys][0];
    if (![operator isEqualToString:SEARCH]) {
        LogError(@"Invalid operator %@ in text search.", operator);
        return NO;
    }
    
    if (*textClauseLimitReached) {
        LogError(@"Multiple text search clauses not allowed in a query.  "
                  "Rewrite query to contain at most one text search clause.");
        return NO;
    }
    
    *textClauseLimitReached = YES;
    return [CDTQQueryValidator validatePredicateValue:textClause[operator] forOperator:operator];
}

+ (BOOL)validateListValues:(NSArray *)listValues
{
    BOOL valid = YES;
    
    for (NSObject *value in listValues) {
        if (![CDTQQueryValidator validatePredicateValue:value forOperator:IN]) {
            valid = NO;
            break;
        }
    }
    
    return valid;
}

+ (BOOL)validatePredicateValue:(NSObject *)predicateValue forOperator:(NSString *) operator
{
    if([operator isEqualToString:EXISTS]){
        return [CDTQQueryValidator validateExistsArgument:predicateValue];
    } else if ([operator isEqualToString:MOD]) {
        return [CDTQQueryValidator validateModArgument:predicateValue];
    } else if ([operator isEqualToString:SEARCH]) {
        return [CDTQQueryValidator validateTextSearchArgument:predicateValue];
    } else {
        return (([predicateValue isKindOfClass:[NSString class]] ||
                 [predicateValue isKindOfClass:[NSNumber class]]));
    }
}

+ (BOOL)validateModArgument:(NSObject *)modulus
{
    BOOL valid = YES;
    
    // The argument must be an array containing two NSNumber elements.  The first element
    // a.k.a the divisor, is always treated as an integer.  Therefore, its value is always
    // rounded down, or truncated to a whole number.  This will be handled by the SQL engine
    // and the unindexed matcher code.  The divisor also cannot be 0, since division by 0 is
    // not a valid mathematical operation.  That validation is handled here.
    if(![modulus isKindOfClass:[NSArray class]] ||
       ((NSArray *) modulus).count != 2 ||
       ![((NSArray *) modulus)[0] isKindOfClass:[NSNumber class]] ||
       ![((NSArray *) modulus)[1] isKindOfClass:[NSNumber class]] ||
       [((NSArray *) modulus)[0] integerValue] == 0) {
        valid = NO;
        LogError(@"$mod operator requires a two element NSArray containing NSNumbers "
                 @"where the first number, the divisor, is not zero.  As in: "
                 @"{ \"$mod\" : [ 2, 1 ] }.  Where 2 is the divisor and 1 is the remainder.");
    }
    
    return valid;
}

+ (BOOL)validateTextSearchArgument:(NSObject *)textSearch
{
    BOOL valid = YES;
    
    if(![textSearch isKindOfClass:[NSString class]]){
        valid = NO;
        LogError(@"$search operator requires an NSString");
    }
    
    return valid;
}

+ (BOOL)validateExistsArgument:(NSObject *)exists
{
    BOOL valid = YES;

    if (![exists isKindOfClass:[NSNumber class]]) {
        valid = NO;
        LogError(@"$exists operator expects YES or NO");
    }

    return valid;
}

+ (BOOL)validateCompoundOperatorOperand:(NSObject *)operand
{
    if (![operand isKindOfClass:[NSArray class]]) {
        LogError(@"Argument to compound operator is not an NSArray: %@", [operand description]);
        return NO;
    }
    return YES;
}

// we are going to need to walk the query tree to validate it before executing it
// this isn't going to be fun :'(

+ (BOOL)validateSelector:(NSDictionary *)selector
{
    // after normalising we should have a few top level selectors

    NSString *topLevelOp = [selector allKeys][0];

    // top level op can only be $and after normalisation

    if ([@[ AND, OR ] containsObject:topLevelOp]) {
        // top level should be $and or $or they should have arrays
        id topLevelArg = [selector objectForKey:topLevelOp];

        if ([topLevelArg isKindOfClass:[NSArray class]]) {
            // safe we know its an NSArray
            BOOL textClauseLimitReached = NO;
            return [CDTQQueryValidator validateCompoundOperatorClauses:topLevelArg
                                                   withTextClauseLimit:&textClauseLimitReached];
        }
    }
    return NO;
}

@end
