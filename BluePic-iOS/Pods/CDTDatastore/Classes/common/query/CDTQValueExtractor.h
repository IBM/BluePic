//
//  CDTQValueExtractor.h
//
//  Created by Michael Rhodes on 01/10/2014.
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

@class CDTDocumentRevision;

/**
 Extracts values from dictionaries using a field name.
 */
@interface CDTQValueExtractor : NSObject

+ (NSObject *)extractValueForFieldName:(NSString *)possiblyDottedField
                          fromRevision:(CDTDocumentRevision *)rev;

+ (NSObject *)extractValueForFieldName:(NSString *)fieldName fromDictionary:(NSDictionary *)body;

@end
