//
//  CDTEncryptionKeyNilProvider.h
//
//
//  Created by Enrique de la Torre Fernandez on 20/02/2015.
//
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.
//

#import <Foundation/Foundation.h>

#import "CDTEncryptionKeyProvider.h"

/**
 * It is mandatory to supply an object that conforms to prototol CDTEncryptionKeyProvider to create
 * a datastore, even if you do not want to cipher the data. To not encrypt the datababase, the
 * object has to return nil when the key is requested. This class implements exactly this behaviour.
 *
 * @see CDTEncryptionKeyProvider
 */
@interface CDTEncryptionKeyNilProvider : NSObject <CDTEncryptionKeyProvider>

/**
 * Return an instance of this class or a subclass that inherits from this one.
 *
 * @return A key provider
 */
+ (instancetype)provider;

@end
