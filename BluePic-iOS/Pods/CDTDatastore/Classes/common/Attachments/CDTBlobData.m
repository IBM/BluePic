//
//  CDTBlobData.m
//  CloudantSync
//
//  Created by Enrique de la Torre Fernandez on 05/05/2015.
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

#import "CDTBlobData.h"

#import "CDTLogging.h"

NSString *const CDTBlobDataErrorDomain = @"CDTBlobDataErrorDomain";

@interface CDTBlobData ()

@property (strong, nonatomic, readonly) NSString *path;

@property (strong, nonatomic) NSFileHandle *outFileHandle;

@end

@implementation CDTBlobData

#pragma mark - Init object
- (instancetype)init { return [self initWithPath:nil]; }

- (instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        if (path && ([path length] > 0)) {
            _path = path;
            _outFileHandle = nil;
        } else {
            CDTLogError(CDTDATASTORE_LOG_CONTEXT, @"A non-empty path is mandatory");

            self = nil;
        }
    }

    return self;
}

#pragma mark - Memory management
- (void)dealloc { [self close]; }

#pragma mark - CDTBlobReader methods
- (NSData *)dataWithError:(NSError **)error
{
    NSData *data = nil;
    NSError *thisError = nil;

    if ([self isBlobOpenForWriting]) {
        CDTLogDebug(CDTDATASTORE_LOG_CONTEXT,
                    @"Blob at %@ is open. Close it before reading its content", self.path);

        thisError = [CDTBlobData errorOperationNotPossibleIfBlobIsOpen];
    } else {
        data = [NSData dataWithContentsOfFile:self.path
                                      options:NSDataReadingMappedIfSafe
                                        error:&thisError];
        if (!data) {
            CDTLogDebug(CDTDATASTORE_LOG_CONTEXT,
                        @"Data object could not be created with file %@: %@", self.path, thisError);
        }
    }

    if (!data && error) {
        *error = thisError;
    }

    return data;
}

- (NSInputStream *)inputStreamWithOutputLength:(UInt64 *)outputLength
{
    if ([self isBlobOpenForWriting]) {
        CDTLogDebug(CDTDATASTORE_LOG_CONTEXT, @"Close blob in order to create an input stream");

        return nil;
    }

    NSFileManager *defaultManager = [NSFileManager defaultManager];

    BOOL isDir = YES;
    if (![defaultManager fileExistsAtPath:self.path isDirectory:&isDir] || isDir) {
        CDTLogDebug(CDTDATASTORE_LOG_CONTEXT, @"No file found in %@", self.path);
        
        return nil;
    }
    
    NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:self.path];

    if (inputStream && outputLength) {
        NSError *error = nil;
        NSDictionary *info = [defaultManager attributesOfItemAtPath:self.path error:&error];
        if (info) {
            *outputLength = [info fileSize];
        } else {
            CDTLogDebug(CDTDATASTORE_LOG_CONTEXT,
                        @"Attributes for file %@ could not be obtained: %@", self.path, error);

            inputStream = nil;
        }
    }

    return inputStream;
}

#pragma mark - CDTBlobWriter methods
- (BOOL)writeEntireBlobWithData:(NSData *)data error:(NSError **)error
{
    BOOL success = NO;
    NSError *thisError = nil;

    if (!data) {
        CDTLogDebug(CDTDATASTORE_LOG_CONTEXT, @"No data to add to %@", self.path);

        thisError = [CDTBlobData errorNoDataProvided];
    } else if ([self isBlobOpenForWriting]) {
        CDTLogDebug(CDTDATASTORE_LOG_CONTEXT,
                    @"Blob at %@ is open. Close it before saving the data", self.path);

        thisError = [CDTBlobData errorOperationNotPossibleIfBlobIsOpen];
    } else {
        NSDataWritingOptions options = NSDataWritingAtomic;
#if TARGET_OS_IPHONE
        options |= NSDataWritingFileProtectionCompleteUnlessOpen;
#endif

        success = [data writeToFile:self.path options:options error:&thisError];
        if (!success) {
            CDTLogDebug(CDTDATASTORE_LOG_CONTEXT, @"Could not write data to file %@: %@", self.path,
                        thisError);
        }
    }

    if (!success && error) {
        *error = thisError;
    }

    return success;
}

- (BOOL)isBlobOpenForWriting { return (self.outFileHandle != nil); }

- (BOOL)openForWriting
{
    if ([self isBlobOpenForWriting]) {
        CDTLogDebug(CDTDATASTORE_LOG_CONTEXT, @"Blob at %@ already open", self.path);

        return YES;
    }

    NSDictionary *attributes = nil;
#if TARGET_OS_IPHONE
    attributes = @{NSFileProtectionKey : NSFileProtectionCompleteUnlessOpen};
#endif

    if (![[NSFileManager defaultManager] createFileAtPath:self.path
                                                 contents:nil
                                               attributes:attributes]) {
        CDTLogDebug(CDTDATASTORE_LOG_CONTEXT, @"File not created at %@", self.path);

        return NO;
    }

    self.outFileHandle = [NSFileHandle fileHandleForWritingAtPath:self.path];

    return YES;
}

- (BOOL)appendData:(NSData *)data
{
    if (!data) {
        CDTLogDebug(CDTDATASTORE_LOG_CONTEXT, @"Data is nil. No data added to %@", self.path);

        return NO;
    }

    if (![self isBlobOpenForWriting]) {
        CDTLogDebug(CDTDATASTORE_LOG_CONTEXT, @"Blob at %@ is not open. No data can be added",
                    self.path);

        return NO;
    }

    [self.outFileHandle writeData:data];

    return YES;
}

- (void)close
{
    if (![self isBlobOpenForWriting]) {
        CDTLogDebug(CDTDATASTORE_LOG_CONTEXT, @"Blob at %@ already closed", self.path);

        return;
    }

    [self.outFileHandle closeFile];
    self.outFileHandle = nil;
}

#pragma mark - Public class methods
+ (instancetype)blobWithPath:(NSString *)path { return [[[self class] alloc] initWithPath:path]; }

#pragma mark - Private class methods
+ (NSError *)errorOperationNotPossibleIfBlobIsOpen
{
    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey :
            NSLocalizedString(@"Close blob in order to perform this operation",
                              @"Close blob in order to perform this operation")
    };

    return [NSError errorWithDomain:CDTBlobDataErrorDomain
                               code:CDTBlobDataErrorOperationNotPossibleIfBlobIsOpen
                           userInfo:userInfo];
}

+ (NSError *)errorNoDataProvided
{
    NSDictionary *userInfo =
        @{ NSLocalizedDescriptionKey : NSLocalizedString(@"Supply data", @"Supply data") };

    return [NSError errorWithDomain:CDTBlobDataErrorDomain
                               code:CDTBlobDataErrorNoDataProvided
                           userInfo:userInfo];
}

@end
