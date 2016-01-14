//
//  CDTChangedDictionary.h
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

#import <Foundation/Foundation.h>

#import "CDTChangedObserver.h"

/**
 A wrapper around NSMutableDictionary which has a changed flag that's
 set when the content is changed.

 Changes are tracked very simply, isChanged is set to true when either of
 removeObjectForKey: or setObject:forKey: is called.

 The changed flag will only be set for modifications through this class, not
 when the underlying dictionary changes itself, therefore it's important
 not to let the contained dictionary "escape" from this class if all changes
 need to be tracked.

 This class implements `CDTChangedObserver` so that it can bubble changes up
 through to its parent containers within a deep structure that has been
 wrapped with `dictionaryWrappingContents:`. That
 method copies the contents of all containers within the passed dictionary
 into new CDTChanged* containers, assigning each wrapped container its parent
 container as delegate.
 */
@interface CDTChangedDictionary : NSMutableDictionary <CDTChangedObserver>

/**
 Create an empty dictionary.
 */
+ (CDTChangedDictionary *)emptyDictionary;

/**
 Will be notified if this object is changed.
 */
@property (nonatomic, weak) NSObject<CDTChangedObserver> *delegate;

/**
 Set to YES if this dictionary has been modified.
 */
@property (nonatomic, getter=isChanged) bool changed;

/**
 Init with dictionary. This constructor must be used.
 */
- (instancetype)initWithDictionary:(NSMutableDictionary *)dictionary;

/**
 Wrap a nested JSON-compatible structure with Changed dictionary and array objects.
 */
+ (CDTChangedDictionary *)dictionaryCopyingContents:(NSDictionary *)dictionary;

@end
