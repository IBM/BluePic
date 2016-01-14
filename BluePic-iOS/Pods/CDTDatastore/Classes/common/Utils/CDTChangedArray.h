//
//  CDTChangedArray.h
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
 A wrapper around NSMutableArray which has a changed flag that's
 set when the content is changed.

 Changes are tracked very simply, isChanged is set to true when any of the
 following are called:

  - insertObject:atIndex:
  - removeObjectAtIndex:
  - addObject:
  - removeLastObject
  - replaceObjectAtIndex:withObject:

 The changed flag will only be set for modifications through this class, not
 when the underlying array changes itself, therefore it's important
 not to let the contained array "escape" from this class if all changes
 need to be tracked.

 This class implements `CDTChangedObserver` so that it can bubble changes up
 through to its parent containers within a deep structure that has been
 wrapped with CDTChangedDictionary's `dictionaryWrappingContents:`. That
 method copies the contents of all containers within the passed dictionary
 into new CDTChanged* containers, assigning each wrapped container its parent
 container as delegate.
 */
@interface CDTChangedArray : NSMutableArray <CDTChangedObserver>

/**
 Create an empty array.
 */
+ (CDTChangedArray *)emptyArray;

/**
 Will be notified if this object is changed.
 */
@property (nonatomic, weak) NSObject<CDTChangedObserver> *delegate;

/**
 Init with array. This constructor must be used.
 */
- (instancetype)initWithMutableArray:(nonnull NSMutableArray *)array;

/**
 Set to YES if this dictionary has been modified.
 */
@property (nonatomic, getter=isChanged) bool changed;

@end
