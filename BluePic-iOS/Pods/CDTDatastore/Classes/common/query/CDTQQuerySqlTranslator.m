//
//  CDTQQuerySqlTranslator.m
//
//  Created by Michael Rhodes on 03/10/2014.
//  Copyright (c) 2014 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "CDTQQuerySqlTranslator.h"
#import "CDTQQueryConstants.h"

#import "CDTQQueryExecutor.h"
#import "CDTQIndexManager.h"
#import "CDTQLogging.h"
#import "CDTQQueryValidator.h"

@interface CDTQTranslatorState : NSObject

@property (nonatomic) BOOL atLeastOneIndexUsed;       // if NO, need to generate a return all query
@property (nonatomic) BOOL atLeastOneIndexMissing;    // i.e., we need to use posthoc matcher
@property (nonatomic) BOOL atLeastOneORIndexMissing;  //       we need to use posthoc matcher
@property (nonatomic) BOOL textIndexRequired;         // A text index needed for a text search
@property (nonatomic) BOOL textIndexMissing;          // if NO and is required, cannot perform query

@end

@implementation CDTQQueryNode

@end

@implementation CDTQChildrenQueryNode

- (instancetype)init
{
    self = [super init];
    if (self) {
        _children = [NSMutableArray array];
    }
    return self;
}

@end

@implementation CDTQAndQueryNode

@end

@implementation CDTQOrQueryNode

@end

@implementation CDTQSqlQueryNode

@end

@implementation CDTQTranslatorState

@end

@implementation CDTQQuerySqlTranslator


+ (CDTQQueryNode *)translateQuery:(NSDictionary *)query
                     toUseIndexes:(NSDictionary *)indexes
                indexesCoverQuery:(BOOL *)indexesCoverQuery
{
    CDTQTranslatorState *state = [[CDTQTranslatorState alloc] init];

    CDTQQueryNode *node =
        [CDTQQuerySqlTranslator translateQuery:query toUseIndexes:indexes state:state];

    if (state.textIndexMissing) {
        LogError(@"No text index defined, cannot execute query containing a text search.");
        return nil;
    } else if (state.textIndexRequired && state.atLeastOneIndexMissing) {
        LogError(@"Query %@ contains a text search but is missing json index(es).  "
                  "All indexes must exist in order to execute a query containing a text search.  "
                  "Create all necessary indexes for the query and re-execute.", query);
        return nil;
    } else if (!state.textIndexRequired &&
                  (!state.atLeastOneIndexUsed || state.atLeastOneORIndexMissing)) {
        // If we haven't used a single index or an OR clause is missing an index,
        // we need to return every document id, so that the post-hoc matcher can
        // run over every document to manually carry out the query.
        CDTQSqlQueryNode *sqlNode = [[CDTQSqlQueryNode alloc] init];
        NSSet *neededFields = [NSSet setWithObject:@"_id"];
        NSString *allDocsIndex = [CDTQQuerySqlTranslator chooseIndexForFields:neededFields
                                                                  fromIndexes:indexes];

        if (allDocsIndex.length > 0) {
            NSString *tableName = [CDTQIndexManager tableNameForIndex:allDocsIndex];
            NSString *sql = [NSString stringWithFormat:@"SELECT _id FROM %@;", tableName];
            sqlNode.sql = [CDTQSqlParts partsForSql:sql parameters:@[]];
        }

        CDTQAndQueryNode *root = [[CDTQAndQueryNode alloc] init];
        [root.children addObject:sqlNode];

        *indexesCoverQuery = NO;
        return root;
    } else {
        *indexesCoverQuery = !state.atLeastOneIndexMissing;
        return node;
    }
}

+ (CDTQQueryNode *)translateQuery:(NSDictionary *)query
                     toUseIndexes:(NSDictionary *)indexes
                            state:(CDTQTranslatorState *)state
{
    // At this point we will have a root compound predicate, AND or OR, and
    // the query will be reduced to a single entry:
    // @{ @"$and": @[ ... predicates (possibly compound) ... ] }
    // @{ @"$or": @[ ... predicates (possibly compound) ... ] }

    CDTQChildrenQueryNode *root;
    NSArray *clauses;

    if (query[AND]) {
        clauses = query[AND];
        root = [[CDTQAndQueryNode alloc] init];
    } else if (query[OR]) {
        clauses = query[OR];
        root = [[CDTQOrQueryNode alloc] init];
    }

    // Compile a list of simple clauses to be handled below.  If a text clause is
    // encountered, store it separately from the simple clauses since it will be
    // handled later on its own.

    NSMutableArray *basicClauses = [NSMutableArray array];
    __block NSObject *textClause = nil;
    
    [clauses enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *clause = (NSDictionary *)obj;
        NSString *field = clause.allKeys[0];
        if (![field hasPrefix:@"$"]) {
            [basicClauses addObject:clauses[idx]];
        } else if ([field.lowercaseString isEqualToString:TEXT]) {
            textClause = clauses[idx];
        }
    }];

    // Handle the simple "field": { "$operator": "value" } clauses. These are
    // handled differently for AND and OR parents, so we need to have the
    // conditional logic below.
    if (basicClauses.count > 0) {
        if (query[AND]) {
            // For an AND query, we require a single compound index and we generate a
            // single SQL statement to use that index to satisfy the clauses.
            
            NSString *chosenIndex =
            [CDTQQuerySqlTranslator chooseIndexForAndClause:basicClauses fromIndexes:indexes];
            if (!chosenIndex) {
                state.atLeastOneIndexMissing = YES;
                
                LogWarn(@"No single index contains all of %@; add index for these fields to "
                        @"query efficiently.",
                        basicClauses);
            } else {
                state.atLeastOneIndexUsed = YES;
                
                // Execute SQL on that index with appropriate values
                CDTQSqlParts *select = [CDTQQuerySqlTranslator selectStatementForAndClause:
                                        basicClauses usingIndex:chosenIndex];
                
                if (!select) {
                    LogError(@"Error generating SELECT clause for %@", basicClauses);
                    return nil;
                }
                
                CDTQSqlQueryNode *sql = [[CDTQSqlQueryNode alloc] init];
                sql.sql = select;
                
                [root.children addObject:sql];
            }
            
        } else if (query[OR]) {
            // OR nodes require a query for each clause.
            //
            // We want to allow OR clauses to use separate indexes, unlike for AND, to allow
            // users to query over multiple indexes during a single query. This prevents users
            // having to create a single huge index just because one query in their application
            // requires it, slowing execution of all the other queries down.
            //
            // We could optimise for OR parts where we have an appropriate compound index,
            // but we don't for now.
            
            for (NSDictionary *clause in basicClauses) {
                NSArray *wrappedClause = @[ clause ];
                
                NSString *chosenIndex =
                [CDTQQuerySqlTranslator chooseIndexForAndClause:wrappedClause fromIndexes:indexes];
                if (!chosenIndex) {
                    state.atLeastOneIndexMissing = YES;
                    state.atLeastOneORIndexMissing = YES;
                    
                    LogWarn(@"No single index contains all of %@; add index for these fields to "
                            @"query efficiently.",
                            basicClauses);
                } else {
                    state.atLeastOneIndexUsed = YES;
                    
                    // Execute SQL on that index with appropriate values
                    CDTQSqlParts *select =
                    [CDTQQuerySqlTranslator selectStatementForAndClause:wrappedClause
                                                             usingIndex:chosenIndex];
                    
                    if (!select) {
                        LogError(@"Error generating SELECT clause for %@", basicClauses);
                        return nil;
                    }
                    
                    CDTQSqlQueryNode *sql = [[CDTQSqlQueryNode alloc] init];
                    sql.sql = select;
                    
                    [root.children addObject:sql];
                }
            }
        }
    }
    
    // A text clause such as { "$text" : { "$search" : "foo bar baz" } }
    // by nature uses its own text index.  It is therefore handled
    // separately from other simple clauses.
    if (textClause != nil) {
        state.textIndexRequired = YES;
        NSString *textIndex = [CDTQQuerySqlTranslator getTextIndexFromIndexes:indexes];
        if (textIndex == nil || textIndex.length == 0) {
            state.textIndexMissing = YES;
        } else {
            // The text clause must be an NSDictionary here otherwise it
            // would not have passed the normalization/validation step.
            CDTQSqlParts *select =
                [CDTQQuerySqlTranslator selectStatementForTextClause:(NSDictionary *)textClause
                                                          usingIndex:textIndex];
            if (!select) {
                LogError(@"Error generating SELECT clause for %@", textClause);
                return nil;
            }
            
            CDTQSqlQueryNode *sql = [[CDTQSqlQueryNode alloc] init];
            sql.sql = select;
            
            [root.children addObject:sql];
        }
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
            CDTQQueryNode *orNode = [CDTQQuerySqlTranslator translateQuery:clauses[idx]
                                                              toUseIndexes:indexes
                                                                     state:state];
            [root.children addObject:orNode];
        }
    }];

    // Add subclauses that are AND
    [clauses enumerateObjectsUsingBlock:^void(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *clause = (NSDictionary *)obj;
        NSString *field = clause.allKeys[0];
        if ([field isEqualToString:AND]) {
            CDTQQueryNode *andNode = [CDTQQuerySqlTranslator translateQuery:clauses[idx]
                                                               toUseIndexes:indexes
                                                                      state:state];
            [root.children addObject:andNode];
        }
    }];

    return root;
}

#pragma mark Process single AND clause with no sub-clauses

+ (NSArray *)fieldsForAndClause:(NSArray *)clause
{
    NSMutableArray *fieldNames = [NSMutableArray array];
    for (NSDictionary *term in clause) {
        if (term.count == 1) {
            [fieldNames addObject:term.allKeys[0]];
        }
    }
    return [NSArray arrayWithArray:fieldNames];
}

+ (BOOL)isOperator:(NSString *)operator inClause:(NSArray *)clause
{
    BOOL found = NO;
    for (NSDictionary *term in clause) {
        if (term.count == 1 && [term.allValues[0] isKindOfClass:[NSDictionary class]]) {
            NSDictionary *predicate = (NSDictionary *) term.allValues[0];
            if (predicate[operator]) {
                found = YES;
                break;
            }
        }
    }
    
    return found;
}

+ (NSString *)chooseIndexForAndClause:(NSArray *)clause fromIndexes:(NSDictionary *)indexes
{
    if ([CDTQQuerySqlTranslator isOperator:SIZE inClause:clause]) {
        LogInfo(@"$size operator found in clause %@.  Indexes are not used with $size operations.",
                clause);
        return nil;
    }
    NSSet *neededFields = [NSSet setWithArray:[self fieldsForAndClause:clause]];

    if (neededFields.count == 0) {
        LogError(@"Invalid clauses in $and clause %@", clause);
        return nil;  // no point in querying empty set of fields
    }

    return [CDTQQuerySqlTranslator chooseIndexForFields:neededFields fromIndexes:indexes];
}

+ (NSString *)chooseIndexForFields:(NSSet *)neededFields fromIndexes:(NSDictionary *)indexes
{
    NSString *chosenIndex = nil;
    for (NSString *indexName in indexes) {
        
        // Don't choose a text index for a non-text query clause
        NSString *indexType = indexes[indexName][@"type"];
        if ([indexType.lowercaseString isEqualToString:@"text"]) {
            continue;
        }
        
        NSSet *providedFields = [NSSet setWithArray:indexes[indexName][@"fields"]];
        if ([neededFields isSubsetOfSet:providedFields]) {
            chosenIndex = indexName;
            break;
        }
    }

    return chosenIndex;
}

+ (NSString *)getTextIndexFromIndexes:(NSDictionary *)indexes
{
    NSString *textIndex = nil;
    for (NSString *indexName in [indexes allKeys]) {
        NSString *indexType = indexes[indexName][@"type"];
        if ([indexType.lowercaseString isEqualToString:@"text"]) {
            textIndex = indexName;
            break;
        }
    }
    
    return textIndex;
}

+ (CDTQSqlParts *)wherePartsForAndClause:(NSArray *)clause usingIndex:(NSString *)indexName
{
    if (clause.count == 0) {
        return nil;  // no point in querying empty set of fields
    }

    // @[@{@"fieldName": @"mike"}, ...]

    NSMutableArray *sqlClauses = [NSMutableArray array];
    NSMutableArray *sqlParameters = [NSMutableArray array];
    NSDictionary *operatorMap = @{
        EQ : @"=",
        GT : @">",
        GTE : @">=",
        LT : @"<",
        LTE : @"<=",
        IN : @"IN",
        MOD : @"%"
    };

    for (NSDictionary *component in clause) {
        if (component.count != 1) {
            LogError(@"Expected single predicate per clause dictionary, got %@", component);
            return nil;
        }

        NSString *fieldName = component.allKeys[0];
        NSDictionary *predicate = component[fieldName];

        if (predicate.count != 1) {
            LogError(@"Expected single operator per predicate dictionary, got %@", component);
            return nil;
        }

        NSString *operator= predicate.allKeys[0];

        // $not specifies ALL documents NOT in the set of documents that match the operator.
        if ([operator isEqualToString:NOT]) {
            NSDictionary *negatedPredicate = predicate[NOT];

            if (negatedPredicate.count != 1) {
                LogError(@"Expected single operator per predicate dictionary, got %@", component);
                return nil;
            }

            NSString *operator= negatedPredicate.allKeys[0];
            NSObject *predicateValue = nil;

            if([operator isEqualToString:EXISTS]){
                // what we do here depends on the value of the exists are
                predicateValue = negatedPredicate[operator];

                BOOL exists = ![(NSNumber *)predicateValue boolValue];
                // since this clause is negated we need to negate the bool value
                [sqlClauses
                    addObject:[self convertExistsToSqlClauseForFieldName:fieldName exists:exists]];
                    [sqlParameters addObject:negatedPredicate[operator]];

            } else {
                NSString *sqlClause;
                NSString *sqlOperator = operatorMap[operator];
                NSString *tableName = [CDTQIndexManager tableNameForIndex:indexName];
                NSString *placeholder;
                if ([operator isEqualToString:IN]) {
                    // The predicate dictionary value must be an NSArray here.
                    // This was validated during normalization.
                    NSArray *inList = negatedPredicate[operator];
                    placeholder =
                        [CDTQQuerySqlTranslator placeholdersForList:inList
                                            updatingParameterValues:sqlParameters];
                } else if ([operator isEqualToString:MOD]) {
                    // The predicate dictionary value must be a two element NSArray
                    // containing numbers here.  This was validated during normalization.
                    NSArray *modulus = negatedPredicate[operator];
                    placeholder = [NSString stringWithFormat:@"? %@ ?", operatorMap[EQ]];
                    [sqlParameters addObject:modulus[0]];
                    [sqlParameters addObject:modulus[1]];
                } else {
                    // The predicate dictionary value must be either a
                    // NSString or a NSNumber here.
                    // This was validated during normalization.
                    predicateValue = negatedPredicate[operator];
                    placeholder = @"?";
                    [sqlParameters addObject:predicateValue];
                }

                sqlClause = [CDTQQuerySqlTranslator whereClauseForNot:fieldName
                                                        usingOperator:sqlOperator
                                                             forTable:tableName
                                                           forOperand:placeholder];
                [sqlClauses addObject:sqlClause];
            }
        } else {
            if ([operator isEqualToString:EXISTS]){
                    BOOL  exists = [(NSNumber *)predicate[operator] boolValue];
                    [sqlClauses addObject:[self convertExistsToSqlClauseForFieldName:fieldName
                                                                              exists:exists]];
                    [sqlParameters addObject:predicate[operator]];

            } else {
                NSString *sqlClause;
                NSString *sqlOperator = operatorMap[operator];
                NSString *placeholder;
                if ([operator isEqualToString:IN]) {
                    // The predicate dictionary value must be an NSArray here.
                    // This was validated during normalization.
                    NSArray *inList = predicate[operator];
                    placeholder =
                        [CDTQQuerySqlTranslator placeholdersForList:inList
                                            updatingParameterValues:sqlParameters];
                } else if ([operator isEqualToString:MOD]) {
                    // The predicate dictionary value must be a two element NSArray
                    // containing numbers here.  This was validated during normalization.
                    NSArray *modulus = predicate[operator];
                    placeholder = [NSString stringWithFormat:@"? %@ ?", operatorMap[EQ]];
                    [sqlParameters addObject:modulus[0]];
                    [sqlParameters addObject:modulus[1]];
                } else {
                    NSObject * predicateValue = predicate[operator];
                    placeholder = @"?";
                    [sqlParameters addObject:predicateValue];
                }

                sqlClause = [NSString stringWithFormat:@"\"%@\" %@ %@", fieldName,
                                                                        sqlOperator,
                                                                        placeholder];
                [sqlClauses addObject:sqlClause];
            }
        }
    }

    return [CDTQSqlParts partsForSql:[sqlClauses componentsJoinedByString:@" AND "]
                          parameters:sqlParameters];
}

+ (NSString *)placeholdersForList:(NSArray *)values
            updatingParameterValues:(NSMutableArray *)sqlParameters
{
    NSMutableArray *operands = [NSMutableArray array];
    for (NSObject *value in values) {
        [operands addObject:@"?"];
        [sqlParameters addObject:value];
    }
    
    NSString *joined = [operands componentsJoinedByString:@", "];
    return [NSString stringWithFormat:@"( %@ )", joined];
}

/**
 * WHERE clause representation of $not must be handled by using a
 * sub-SELECT statement of the operator which is then applied to
 * _id NOT IN (...).  This is because this process is the only
 * way that we can ensure that documents that contain arrays are
 * handled correctly.
 *
 */
+ (NSString *)whereClauseForNot:(NSString *)fieldName
                  usingOperator:(NSString *)sqlOperator
                       forTable:(NSString *)tableName
                     forOperand:(NSString *)operand;
{
    NSString *whereForSubSelect = [NSString stringWithFormat:@"\"%@\" %@ %@",
                                   fieldName,
                                   sqlOperator,
                                   operand];
    NSString *subSelect = [NSString stringWithFormat:@"SELECT _id FROM %@ WHERE %@",
                           tableName,
                           whereForSubSelect];
    
    return [NSString stringWithFormat:@"_id NOT IN (%@)", subSelect];
}

+ (NSString *)convertExistsToSqlClauseForFieldName:(NSString *)fieldName exists:(BOOL)exists
{
    NSString *sqlClause;
    if (exists) {
        // so this field needs to exist
        sqlClause = [NSString stringWithFormat:@"(\"%@\" IS NOT NULL)", fieldName];
    } else {
        // must not exist
        sqlClause = [NSString stringWithFormat:@"(\"%@\" IS NULL)", fieldName];
    }
    return sqlClause;
}

+ (CDTQSqlParts *)selectStatementForAndClause:(NSArray *)clause usingIndex:(NSString *)indexName
{
    if (clause.count == 0) {
        return nil;  // no query here
    }

    if (!indexName) {
        return nil;
    }

    CDTQSqlParts *where = [CDTQQuerySqlTranslator wherePartsForAndClause:clause
                                                              usingIndex:indexName];

    if (!where) {
        return nil;
    }

    NSString *tableName = [CDTQIndexManager tableNameForIndex:indexName];

    NSString *sql = @"SELECT _id FROM %@ WHERE %@;";
    sql = [NSString stringWithFormat:sql, tableName, where.sqlWithPlaceholders];

    CDTQSqlParts *parts = [CDTQSqlParts partsForSql:sql parameters:where.placeholderValues];
    return parts;
}

+ (CDTQSqlParts *)selectStatementForTextClause:(NSDictionary *)textClause
                                    usingIndex:(NSString *)indexName
{
    if (textClause.count == 0) {
        return nil;  // no query here
    }
    
    if (!indexName) {
        return nil;
    }
    
    NSString *tableName = [CDTQIndexManager tableNameForIndex:indexName];
    NSString *search = textClause[TEXT][SEARCH];
    
    NSString *sql = @"SELECT _id FROM %@ WHERE %@ MATCH ?;";
    sql = [NSString stringWithFormat:sql, tableName, tableName];
    
    CDTQSqlParts *parts = [CDTQSqlParts partsForSql:sql parameters:@[ search ]];
    return parts;
}

@end
