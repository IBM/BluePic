//
//  CDTBlobEncryptedData.m
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

#import "CDTBlobEncryptedData.h"
#import "CDTBlobEncryptedDataConstants.h"

#import "CDTBlobData.h"

#import "CDTEncryptionKeychainUtils.h"

#import "CDTLogging.h"

#define CDTBLOBENCRYPTEDDATA_IV_SIZE kCCBlockSizeAES128

NSString *const CDTBlobEncryptedDataErrorDomain = @"CDTBlobEncryptedDataErrorDomain";

@interface CDTBlobEncryptedData ()

@property (strong, nonatomic, readonly) NSData *key;
@property (strong, nonatomic, readonly) CDTBlobData *blob;

@property (strong, nonatomic) NSData *currentIV;
@property (strong, nonatomic) NSMutableData *currentData;

@end

@implementation CDTBlobEncryptedData

#pragma mark - Init object
- (instancetype)init { return [self initWithPath:nil encryptionKey:nil]; }

- (instancetype)initWithPath:(NSString *)path encryptionKey:(CDTEncryptionKey *)encryptionKey
{
    self = [super init];
    if (self) {
        CDTBlobData *thisBlob = [CDTBlobData blobWithPath:path];

        if (!thisBlob) {
            CDTLogError(CDTDATASTORE_LOG_CONTEXT, @"Cannot create blob data with path %@", path);

            self = nil;
        } else if (!encryptionKey) {
            CDTLogError(CDTDATASTORE_LOG_CONTEXT, @"Supply an encryption key");

            self = nil;
        } else {
            _key = encryptionKey.data;
            _blob = thisBlob;

            _currentIV = nil;
            _currentData = nil;
        }
    }

    return self;
}

#pragma mark - Memory management
- (void)dealloc { [self close]; }

#pragma mark - CDTBlobReader methods
- (NSData *)dataWithError:(NSError **)error
{
    // Read file
    NSError *thisError = nil;
    NSData *fileData = [self.blob dataWithError:&thisError];
    BOOL success = (fileData != nil);

    // Check data size
    if (success) {
        NSUInteger fileMinimunSize = CDTBLOBENCRYPTEDDATA_ENCRYPTEDDATA_LOCATION;

        success = (fileData.length >= fileMinimunSize);
        if (!success) {
            thisError = [CDTBlobEncryptedData errorFileTooSmall];
        }
    }

    // Check version
    if (success) {
        CDTBLOBENCRYPTEDDATA_VERSION_TYPE version;
        [fileData getBytes:&version
                     range:NSMakeRange(CDTBLOBENCRYPTEDDATA_VERSION_LOCATION, sizeof(version))];

        success = (version == CDTBLOBENCRYPTEDDATA_VERSION_VALUE);
        if (!success) {
            CDTLogDebug(CDTDATASTORE_LOG_CONTEXT,
                        @"Wrong version: %ui. File is not encrypted or it is corrupted", version);

            thisError = [CDTBlobEncryptedData errorWrongVersion];
        }
    }

    // Decrypt data
    NSData *data = nil;
    if (success) {
        NSUInteger lengthEncryptedData =
            (fileData.length - CDTBLOBENCRYPTEDDATA_ENCRYPTEDDATA_LOCATION);
        if (lengthEncryptedData == 0) {
            data = [NSData data];
        } else {
            // Get IV
            NSData *iv = [fileData subdataWithRange:NSMakeRange(CDTBLOBENCRYPTEDDATA_IV_LOCATION,
                                                                CDTBLOBENCRYPTEDDATA_IV_SIZE)];

            // Get encrypted data
            NSData *encryptedData =
                [fileData subdataWithRange:NSMakeRange(CDTBLOBENCRYPTEDDATA_ENCRYPTEDDATA_LOCATION,
                                                       lengthEncryptedData)];

            // Use AES
            data = [CDTEncryptionKeychainUtils dataForAESEncryptedData:encryptedData
                                                                   key:self.key
                                                                    iv:iv];
        }
    }

    // Return
    if (!success && error) {
        *error = thisError;
    }

    return data;
}

- (NSInputStream *)inputStreamWithOutputLength:(UInt64 *)outputLength
{
    NSData *data = [self dataWithError:nil];
    if (!data) {
        return nil;
    }

    if (outputLength) {
        *outputLength = data.length;
    }

    return [NSInputStream inputStreamWithData:data];
}

#pragma mark - CDTBlobWriter methods
- (BOOL)writeEntireBlobWithData:(NSData *)data error:(NSError **)error
{
    // Validate data
    if (!data) {
        CDTLogDebug(CDTDATASTORE_LOG_CONTEXT, @"Data is nil");

        if (error) {
            *error = [CDTBlobEncryptedData errorNoDataProvided];
        }

        return NO;
    }

    // Generate file content
    // Header
    NSData *iv = [self generateAESIv];
    NSMutableData *fileData = [CDTBlobEncryptedData generateHeaderWithIV:iv];

    // Encrypted data
    if (data.length > 0) {
        NSData *encryptedData =
            [CDTEncryptionKeychainUtils aesEncryptedDataForData:data key:self.key iv:iv];

        [fileData appendData:encryptedData];
    }

    // Save data
    return [self.blob writeEntireBlobWithData:fileData error:error];
}

- (BOOL)isBlobOpenForWriting { return [self.blob isBlobOpenForWriting]; }

- (BOOL)openForWriting
{
    if ([self.blob isBlobOpenForWriting]) {
        CDTLogDebug(CDTDATASTORE_LOG_CONTEXT, @"Blob already open");

        return YES;
    }

    if (![self.blob openForWriting]) {
        return NO;
    }

    self.currentIV = [self generateAESIv];
    self.currentData = [NSMutableData data];

    NSMutableData *headerData = [CDTBlobEncryptedData generateHeaderWithIV:self.currentIV];
    [self.blob appendData:headerData];

    return YES;
}

- (BOOL)appendData:(NSData *)data
{
    if (![self.blob isBlobOpenForWriting]) {
        CDTLogDebug(CDTDATASTORE_LOG_CONTEXT, @"Blob is not open. No data can be added");

        return NO;
    }

    if (!data) {
        CDTLogDebug(CDTDATASTORE_LOG_CONTEXT, @"Data is nil");

        return NO;
    }

    [self.currentData appendData:data];

    return YES;
}

- (void)close
{
    if (![self.blob isBlobOpenForWriting]) {
        CDTLogDebug(CDTDATASTORE_LOG_CONTEXT, @"Blob already closed");

        return;
    }

    if (self.currentData.length > 0) {
        NSData *encryptedData = [CDTEncryptionKeychainUtils aesEncryptedDataForData:self.currentData
                                                                                key:self.key
                                                                                 iv:self.currentIV];
        [self.blob appendData:encryptedData];
    }

    [self.blob close];

    self.currentIV = nil;
    self.currentData = nil;
}

#pragma mark - CDTBlobEncryptedData+Internal methods
- (NSData *)generateAESIv
{
    NSData *iv = [CDTEncryptionKeychainUtils
        generateSecureRandomBytesWithLength:CDTBLOBENCRYPTEDDATA_IV_SIZE];

    return iv;
}

#pragma mark - Public class methods
+ (instancetype)blobWithPath:(NSString *)path encryptionKey:(CDTEncryptionKey *)encryptionKey
{
    return [[[self class] alloc] initWithPath:path encryptionKey:encryptionKey];
}

#pragma mark - Private class methods
+ (NSMutableData *)generateHeaderWithIV:(NSData *)iv
{
    // Version
    CDTBLOBENCRYPTEDDATA_VERSION_TYPE version = CDTBLOBENCRYPTEDDATA_VERSION_VALUE;
    NSMutableData *headerData = [NSMutableData dataWithBytes:&version length:sizeof(version)];

    // IV
    [headerData appendData:iv];

    return headerData;
}

+ (NSError *)errorFileTooSmall
{
    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey : NSLocalizedString(
            @"File does not reach the minimun size. It is not encrypted or it is corrupted",
            @"File does not reach the minimun size. It is not encrypted or it is corrupted")
    };

    return [NSError errorWithDomain:CDTBlobEncryptedDataErrorDomain
                               code:CDTBlobEncryptedDataErrorFileTooSmall
                           userInfo:userInfo];
}

+ (NSError *)errorWrongVersion
{
    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey :
            NSLocalizedString(@"Wrong version or file is not encrypted or it is corrupted",
                              @"Wrong version or file is not encrypted or it is corrupted")
    };

    return [NSError errorWithDomain:CDTBlobEncryptedDataErrorDomain
                               code:CDTBlobEncryptedDataErrorWrongVersion
                           userInfo:userInfo];
}

+ (NSError *)errorNoDataProvided
{
    NSDictionary *userInfo =
        @{ NSLocalizedDescriptionKey : NSLocalizedString(@"Supply data", @"Supply data") };

    return [NSError errorWithDomain:CDTBlobEncryptedDataErrorDomain
                               code:CDTBlobEncryptedDataErrorNoDataProvided
                           userInfo:userInfo];
}

@end
