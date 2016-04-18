//
//  CDTChangedDictionary.m
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

#import "CDTChangedDictionary.h"

#import "CDTChangedArray.h"

@interface CDTChangedDictionary ()

@property (nonatomic, strong, readonly) NSMutableDictionary *wrappedDictionary;

@end

@implementation CDTChangedDictionary

+ (CDTChangedDictionary *)emptyDictionary
{
    return [[CDTChangedDictionary alloc] initWithDictionary:[@{} mutableCopy]];
}

- (instancetype)initWithDictionary:(NSMutableDictionary *)dictionary
{
    self = [self init];
    if (self) {
        _wrappedDictionary = dictionary;
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

#pragma mark NSMutableDictionary primitive methods

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey
{
    self.changed = YES;
    [self.wrappedDictionary setObject:anObject forKey:aKey];
}

- (void)removeObjectForKey:(id)aKey
{
    self.changed = YES;
    [self.wrappedDictionary removeObjectForKey:aKey];
}

#pragma mark NSDictionary primitive methods

- (id)initWithObjects:(const id[])objects
              forKeys:(const id<NSCopying> [])keys
                count:(NSUInteger)count
{
    self = [self init];
    if (self) {
        _wrappedDictionary =
            [[NSMutableDictionary alloc] initWithObjects:objects forKeys:keys count:count];
    }
    return self;
}

- (NSUInteger)count { return self.wrappedDictionary.count; }

- (id)objectForKey:(id)aKey { return [self.wrappedDictionary objectForKey:aKey]; }

- (NSEnumerator *)keyEnumerator { return [self.wrappedDictionary keyEnumerator]; }

+ (CDTChangedDictionary *)dictionaryCopyingContents:(NSDictionary *)dictionary
{
    // We need to create the changed dictionary at the end to avoid setting
    // isChanged prematurely.
    CDTChangedDictionary *changedDict = [CDTChangedDictionary emptyDictionary];

    for (NSString *key in dictionary) {
        NSObject *ob = dictionary[key];
        if ([ob isKindOfClass:[NSDictionary class]]) {
            CDTChangedDictionary *tmp =
                [CDTChangedDictionary dictionaryCopyingContents:(NSDictionary *)ob];
            tmp.delegate = changedDict;
            changedDict[key] = tmp;
        } else if ([ob isKindOfClass:[NSArray class]]) {
            CDTChangedArray *tmp = [CDTChangedDictionary arrayCopyingContents:(NSArray *)ob];
            tmp.delegate = changedDict;
            changedDict[key] = tmp;
        } else {
            changedDict[key] = ob;
        }
    }

    // Reset changed flag -- it will have been set while we built the dictionary
    changedDict.changed = NO;

    return changedDict;
}

+ (CDTChangedArray *)arrayCopyingContents:(NSArray *)array
{
    CDTChangedArray *changedArray = [CDTChangedArray emptyArray];

    for (NSObject *ob in array) {
        if ([ob isKindOfClass:[NSDictionary class]]) {
            CDTChangedDictionary *tmp =
                [CDTChangedDictionary dictionaryCopyingContents:(NSDictionary *)ob];
            tmp.delegate = changedArray;
            [changedArray addObject:tmp];
        } else if ([ob isKindOfClass:[NSArray class]]) {
            CDTChangedArray *tmp = [CDTChangedDictionary arrayCopyingContents:(NSArray *)ob];
            tmp.delegate = changedArray;
            [changedArray addObject:tmp];
        } else {
            [changedArray addObject:ob];
        }
    }

    // Reset changed flag -- it will have been set while we built the dictionary
    changedArray.changed = NO;

    return changedArray;
}

@end
