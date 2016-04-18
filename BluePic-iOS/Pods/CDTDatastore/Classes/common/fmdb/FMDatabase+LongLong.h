//
// FMDatabase+LongLong.h
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

#import <Foundation/Foundation.h>
#import <FMDB/FMDatabase.h>

@interface FMDatabase (LongLong)

- (long long)longLongForQuery:(NSString*)objs, ...;

@end
