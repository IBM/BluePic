/* *     Copyright 2016, 2017 IBM Corp.
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 */

#import <UIKit/UIKit.h>

//! Project version number for BMSSecurity.
FOUNDATION_EXPORT double BMSSecurityVersionNumber;

//! Project version string for BMSSecurity.
FOUNDATION_EXPORT const unsigned char BMSSecurityVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <BMSSecurity/PublicHeader.h>

#if defined(__cplusplus)
extern "C" {
#endif
    typedef uint32_t CC_LONG;       /* 32 bit unsigned integer */
    
#define CC_SHA256_DIGEST_LENGTH     32          /* digest length in bytes */
#define CC_SHA256_BLOCK_BYTES       64          /* block size in bytes */
    extern unsigned char *CC_SHA256(const void *data, CC_LONG len, unsigned char *md)
    __OSX_AVAILABLE_STARTING(__MAC_10_4, __IPHONE_2_0);
    
#if defined(__cplusplus)
}
#endif
