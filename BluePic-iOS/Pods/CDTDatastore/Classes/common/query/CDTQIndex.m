//
//  CDTQIndex.m
//
//  Created by Al Finkelstein on 2015-04-20
//  Copyright (c) 2015 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "CDTQIndex.h"

#import "CDTQLogging.h"

NSString *const kCDTQJsonType = @"json";
NSString *const kCDTQTextType = @"text";

static NSString *const kCDTQTextTokenize = @"tokenize";
static NSString *const kCDTQTextDefaultTokenizer = @"simple";

@interface CDTQIndex ()

@end

@implementation CDTQIndex

// Static array of supported index types
+ (NSArray *)validTypes
{
    static NSArray *validTypesArray = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        validTypesArray = @[ kCDTQJsonType, kCDTQTextType ];
    });
    return validTypesArray;
}

// Static array of supported index settings
+ (NSArray *)validSettings
{
    static NSArray *validSettingsArray = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        validSettingsArray = @[ kCDTQTextTokenize ];
    });
    return validSettingsArray;
}

- (instancetype)initWithFields:(NSArray *)fieldNames
                     indexName:(NSString *)indexName
                     indexType:(NSString *)indexType
                 indexSettings:(NSDictionary *)indexSettings
{
    self = [super init];
    if (self) {
        _fieldNames = fieldNames;
        _indexName = indexName;
        _indexType = indexType;
        _indexSettings = indexSettings;
    }
    return self;
}

+ (instancetype)index:(NSString *)indexName withFields:(NSArray *)fieldNames
{
    return [[self class] index:indexName withFields:fieldNames ofType:kCDTQJsonType];
}

+ (instancetype)index:(NSString *)indexName
           withFields:(NSArray *)fieldNames
               ofType:(NSString *)indexType
{
    return [[self class] index:indexName withFields:fieldNames ofType:indexType withSettings:nil];
}

+ (instancetype)index:(NSString *)indexName
           withFields:(NSArray *)fieldNames
               ofType:(NSString *)indexType
         withSettings:(NSDictionary *)indexSettings
{
    if (fieldNames.count == 0) {
        LogError(@"No field names provided.");
        return nil;
    }
    
    if (indexName.length == 0) {
        LogError(@"No index name provided.");
        return nil;
    }
    
    if (indexType.length == 0) {
        LogError(@"No index type provided.");
        return nil;
    }
    
    if (![[CDTQIndex validTypes] containsObject:indexType.lowercaseString]) {
        LogError(@"Invalid index type %@.", indexType);
        return nil;
    }
    
    if ([indexType.lowercaseString isEqualToString:kCDTQJsonType] && indexSettings) {
        LogWarn(@"Index type is %@, index settings %@ ignored.", indexType, indexSettings);
        indexSettings = nil;
    } else if ([indexType.lowercaseString isEqualToString:kCDTQTextType]) {
        if (!indexSettings) {
            indexSettings = @{ kCDTQTextTokenize: kCDTQTextDefaultTokenizer };
            LogDebug(@"Index type is %@, defaulting settings to %@.", indexType, indexSettings);
        } else {
            for (NSString *parameter in [indexSettings allKeys]) {
                if (![[CDTQIndex validSettings] containsObject:parameter.lowercaseString]) {
                    LogError(@"Invalid parameter %@ in index settings %@.", parameter,
                                                                            indexSettings);
                    return nil;
                }
            }
        }
    }
    
    return [[[self class] alloc] initWithFields:fieldNames
                                      indexName:indexName
                                      indexType:indexType
                                  indexSettings:indexSettings];
}

-(BOOL) compareIndexTypeTo:(NSString *)indexType withIndexSettings:(NSString *)indexSettings
{
    if (![self.indexType.lowercaseString isEqualToString:indexType.lowercaseString]) {
        return NO;
    }
    
    if (!self.indexSettings && !indexSettings) {
        return YES;
    } else if (!self.indexSettings || !indexSettings) {
        return NO;
    }
    
    NSError *error;
    NSData *settingsData = [indexSettings dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *settingsDict = [NSJSONSerialization JSONObjectWithData:settingsData
                                                                 options:kNilOptions
                                                                   error:&error];
    if (!settingsDict) {
        LogError(@"Error processing index settings %@", indexSettings);
        return NO;
    }
    
    return [self.indexSettings isEqualToDictionary:settingsDict];
}

-(NSString *) settingsAsJSON {
    if (!self.indexSettings) {
        LogWarn(@"Index settings are nil.  Nothing to return.");
        return nil;
    }
    NSError *error;
    NSData *settingsData = [NSJSONSerialization dataWithJSONObject:self.indexSettings
                                                           options:kNilOptions
                                                             error:&error];
    if (!settingsData) {
        LogError(@"Error processing index settings %@", self.indexSettings);
        return nil;
    }
    
    return [[NSString alloc] initWithData:settingsData encoding:NSUTF8StringEncoding];
}

@end
