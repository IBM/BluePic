//
//  CDTMacros.h
//  CloudantSync
//
//  Created by Enrique de la Torre Fernandez on 03/06/2015.
//  Copyright (c) 2015 IBM Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.
//

#ifndef _CDTMacros_h
#define _CDTMacros_h

#ifndef NS_DESIGNATED_INITIALIZER
#if __has_attribute(objc_designated_initializer)

#define NS_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))

#else

#define NS_DESIGNATED_INITIALIZER

#endif
#endif

#ifndef UNAVAILABLE_ATTRIBUTE
#define UNAVAILABLE_ATTRIBUTE
#endif

#endif
