//
// FMDatabase+LongLong.m
// fmkit
//
// Extracted from FMDatabaseAdditions.m
// Created by August Mueller on 10/30/05.
// Copyright 2005 Flying Meat Inc.. All rights reserved.
//
// LongLong feature added by Jens Alfke
// https://github.com/couchbaselabs/fmdb/commit/1a3cf0f872b9d017eb1eb977df85cfeedce45156
//
//
// Modified for distribution by IBM Cloudant, (c) copyright IBM Cloudant 2015

#import "FMDatabase+LongLong.h"

#import <FMDB/FMDatabase.h>
#import <FMDB/FMDatabaseAdditions.h>

@interface FMDatabase (PrivateStuff)
- (FMResultSet *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray*)arrayArgs orDictionary:(NSDictionary *)dictionaryArgs orVAList:(va_list)args;
@end


@implementation FMDatabase (LongLong)

#define RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(type, sel)             \
va_list args;                                                        \
va_start(args, query);                                               \
FMResultSet *resultSet = [self executeQuery:query withArgumentsInArray:0x00 orDictionary:0x00 orVAList:args];   \
va_end(args);                                                        \
if (![resultSet next]) { return (type)0; }                           \
type ret = [resultSet sel:0];                                        \
[resultSet close];                                                   \
[resultSet setParentDB:nil];                                         \
return ret;

- (long long)longLongForQuery:(NSString*)query, ... {
    RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(long long, longLongIntForColumnIndex);
}

@end
