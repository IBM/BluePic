//
//  CDTBlobEncryptedDataConstants.h
//  CloudantSync
//
//  Created by Enrique de la Torre Fernandez on 21/05/2015.
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

#ifndef _CDTBlobEncryptedDataConstants_h
#define _CDTBlobEncryptedDataConstants_h

#import <CommonCrypto/CommonCryptor.h>

// Version: where this value starts
#define CDTBLOBENCRYPTEDDATA_VERSION_LOCATION 0

// Version: data type (use it to get its size on disk)
#define CDTBLOBENCRYPTEDDATA_VERSION_TYPE UInt8

// Version: current value
#define CDTBLOBENCRYPTEDDATA_VERSION_VALUE (CDTBLOBENCRYPTEDDATA_VERSION_TYPE)1

// IV: where this value starts
#define CDTBLOBENCRYPTEDDATA_IV_LOCATION \
    (CDTBLOBENCRYPTEDDATA_VERSION_LOCATION + sizeof(CDTBLOBENCRYPTEDDATA_VERSION_TYPE))

// Data: where this value starts
#define CDTBLOBENCRYPTEDDATA_ENCRYPTEDDATA_LOCATION \
    (CDTBLOBENCRYPTEDDATA_IV_LOCATION + kCCBlockSizeAES128)

#endif
