//
//  CDTChangedArray.m
//
//
//  Created by Michael Rhodes on 17/08/2015.
//  Copyright (c) 2015 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.
//

#import "CDTChangedArray.h"

#import "CDTChangedDictionary.h"

@interface CDTChangedArray ()

@property (nonatomic, strong) NSMutableArray *wrappedArray;

@end

@implementation CDTChangedArray

+ (CDTChangedArray *)emptyArray
{
    return [[CDTChangedArray alloc] initWithMutableArray:[@[] mutableCopy]];
}

- (instancetype)initWithMutableArray:(nonnull NSMutableArray *)array
{
    self = [self init];
    if (self) {
        _wrappedArray = array;
    }
    return self;
}

- (void)setChanged:(bool)changed
{
    _changed = changed;

    if (_changed && self.delegate) {
        [self.delegate contentOfObjectDidChange:self];
    }
}

- (void)contentOfObjectDidChange:(NSObject *)object { self.changed = YES; }

#pragma mark NSMutableArray primitives

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    self.changed = YES;
    [self.wrappedArray insertObject:anObject atIndex:index];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    self.changed = YES;
    [self.wrappedArray removeObjectAtIndex:index];
}

- (void)addObject:(id)anObject
{
    self.changed = YES;
    [self.wrappedArray addObject:anObject];
}

- (void)removeLastObject
{
    self.changed = YES;
    [self.wrappedArray removeLastObject];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    self.changed = YES;
    [self.wrappedArray replaceObjectAtIndex:index withObject:anObject];
}

#pragma mark NSArray primitives

- (NSUInteger)count { return self.wrappedArray.count; }

- (id)objectAtIndex:(NSUInteger)index { return [self.wrappedArray objectAtIndex:index]; }

@end
