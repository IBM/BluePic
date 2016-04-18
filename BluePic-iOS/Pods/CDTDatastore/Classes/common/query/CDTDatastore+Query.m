//
//  CDTDatastore+Query.m
//
//  Created by Rhys Short on 19/11/2014.
//
//  Copyright (c) 2014 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "CDTDatastore+Query.h"
#import <objc/runtime.h>

@implementation CDTDatastore (Query)

- (CDTQIndexManager *)CDTQManager
{
    if (objc_getAssociatedObject(self, @selector(CDTQManager)) == nil) {
        @synchronized(self)
        {
            if (objc_getAssociatedObject(self, @selector(CDTQManager)) == nil) {
                CDTQIndexManager *m = [CDTQIndexManager managerUsingDatastore:self error:nil];
                objc_setAssociatedObject(self, @selector(CDTQManager), m,
                                         OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
    }

    return objc_getAssociatedObject(self, @selector(CDTQManager));
}

- (BOOL)isTextSearchEnabled
{
    return [self.CDTQManager isTextSearchEnabled];
}

- (NSDictionary *)listIndexes
{
    return [self.CDTQManager listIndexes];
}

- (NSString *)ensureIndexed:(NSArray *)fieldNames withName:(NSString *)indexName
{
    return [self.CDTQManager ensureIndexed:fieldNames withName:indexName];
}

- (NSString *)ensureIndexed:(NSArray *)fieldNames
                   withName:(NSString *)indexName
                       type:(NSString *)type
{
    return [self.CDTQManager ensureIndexed:fieldNames withName:indexName type:type];
}

- (NSString *)ensureIndexed:(NSArray *)fieldNames
                   withName:(NSString *)indexName
                       type:(NSString *)type
                   settings:(NSDictionary *)indexSettings
{
    return [self.CDTQManager ensureIndexed:fieldNames
                                  withName:indexName
                                      type:type
                                  settings:indexSettings];
}

- (CDTQResultSet *)find:(NSDictionary *)query
{
    return [self.CDTQManager find:query];
}

- (CDTQResultSet *)find:(NSDictionary *)query
                   skip:(NSUInteger)skip
                  limit:(NSUInteger)limit
                 fields:(NSArray *)fields
                   sort:(NSArray *)sortDocument
{
    return [self.CDTQManager find:query skip:skip limit:limit fields:fields sort:sortDocument];
}

- (BOOL)deleteIndexNamed:(NSString *)indexName
{
    return [self.CDTQManager deleteIndexNamed:indexName];
}

- (BOOL)updateAllIndexes
{
    return [self.CDTQManager updateAllIndexes];
}

@end
