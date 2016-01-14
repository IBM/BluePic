//
//  TDBlobStore.m
//  TouchDB
//
//  Created by Jens Alfke on 12/10/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//
//  Modifications for this distribution by Cloudant, Inc., Copyright (c) 2014 Cloudant, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "TDBlobStore.h"
#import "TDBase64.h"
#import "TDMisc.h"
#import "CDTLogging.h"
#import <ctype.h>

#import "TDStatus.h"

#import "TD_Database+BlobFilenames.h"

#import "CDTBlobHandleFactory.h"

#ifdef GNUSTEP
#define NSDataReadingMappedIfSafe NSMappedRead
#define NSDataWritingAtomic NSAtomicWrite
#endif

NSString *const CDTBlobStoreErrorDomain = @"CDTBlobStoreErrorDomain";

@interface TDBlobStore ()

@property (strong, nonatomic, readonly) NSString *path;
@property (strong, nonatomic, readonly) CDTBlobHandleFactory *blobHandleFactory;

@end

@implementation TDBlobStore

- (id)initWithPath:(NSString *)dir
    encryptionKeyProvider:(id<CDTEncryptionKeyProvider>)provider
                    error:(NSError **)outError;
{
    Assert(dir);
    Assert(provider, @"Key provider is mandatory. Supply a CDTNilEncryptionKeyProvider instead.");

    self = [super init];
    if (self) {
        BOOL success = YES;
        
        BOOL isDir;
        if (![[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDir] || !isDir) {
            if (![[NSFileManager defaultManager] createDirectoryAtPath:dir
                                           withIntermediateDirectories:NO
                                                            attributes:nil
                                                                 error:outError]) {
                success = NO;
            }
        }
        
        if (success) {
            _path = [dir copy];
            _blobHandleFactory = [CDTBlobHandleFactory factoryWithEncryptionKeyProvider:provider];
        } else {
            self = nil;
        }
    }

    return self;
}

+ (TDBlobKey)keyForBlob:(NSData *)blob
{
    NSCParameterAssert(blob);

    TDBlobKey key;
    SHA_CTX ctx;
    SHA1_Init(&ctx);
    SHA1_Update(&ctx, blob.bytes, blob.length);
    SHA1_Final(key.bytes, &ctx);

    return key;
}

+ (NSString *)blobPathWithStorePath:(NSString *)storePath blobFilename:(NSString *)blobFilename
{
    NSString *blobPath = nil;
    
    if (storePath && (storePath.length > 0) && blobFilename && (blobFilename.length > 0)) {
        blobPath = [storePath stringByAppendingPathComponent:blobFilename];
    }
    
    return blobPath;
}

- (id<CDTBlobReader>)blobForKey:(TDBlobKey)key withDatabase:(FMDatabase *)db
{
    NSString *filename = [TD_Database filenameForKey:key inBlobFilenamesTableInDatabase:db];
    NSString *blobPath = [TDBlobStore blobPathWithStorePath:_path blobFilename:filename];

    id<CDTBlobReader> reader = [_blobHandleFactory readerWithPath:blobPath];

    return reader;
}

- (BOOL)storeBlob:(NSData *)blob
      creatingKey:(TDBlobKey *)outKey
     withDatabase:(FMDatabase *)db
            error:(NSError *__autoreleasing *)outError
{
    // Search filename
    TDBlobKey thisKey = [TDBlobStore keyForBlob:blob];

    NSString *filename = [TD_Database filenameForKey:thisKey inBlobFilenamesTableInDatabase:db];
    if (filename) {
        CDTLogDebug(CDTDATASTORE_LOG_CONTEXT, @"Key already exists with filename %@", filename);

        if (outKey) {
            *outKey = thisKey;
        }

        return YES;
    }

    // Create new if not exists
    filename = [TD_Database generateAndInsertRandomFilenameBasedOnKey:thisKey
                                     intoBlobFilenamesTableInDatabase:db];
    if (!filename) {
        CDTLogError(CDTDATASTORE_LOG_CONTEXT, @"No filename generated");

        if (outError) {
            *outError = [TDBlobStore errorNoFilenameGenerated];
        }

        return NO;
    }

    // Get a writer
    NSString *blobPath = [TDBlobStore blobPathWithStorePath:_path blobFilename:filename];
    id<CDTBlobWriter> writer = [_blobHandleFactory writerWithPath:blobPath];

    // Save to disk
    NSError *thisError = nil;
    if (![writer writeEntireBlobWithData:blob error:&thisError]) {
        CDTLogError(CDTDATASTORE_LOG_CONTEXT, @"Data not stored in %@: %@", blobPath, thisError);

        [TD_Database deleteRowForKey:thisKey inBlobFilenamesTableInDatabase:db];

        if (outError) {
            *outError = thisError;
        }

        return NO;
    }

    // Return
    if (outKey) {
        *outKey = thisKey;
    }

    return YES;
}

- (NSUInteger)countWithDatabase:(FMDatabase *)db
{
    NSUInteger n = [TD_Database countRowsInBlobFilenamesTableInDatabase:db];

    return n;
}

- (BOOL)deleteBlobsExceptWithKeys:(NSSet *)keysToKeep withDatabase:(FMDatabase *)db
{
    BOOL success = YES;

    NSMutableSet *filesToKeep = [NSMutableSet setWithCapacity:keysToKeep.count];

    // Delete attachments from database
    NSArray *allRows = [TD_Database rowsInBlobFilenamesTableInDatabase:db];

    for (TD_DatabaseBlobFilenameRow *oneRow in allRows) {
        // Check if key is an exception
        NSData *curKeyData =
            [NSData dataWithBytes:oneRow.key.bytes length:sizeof(oneRow.key.bytes)];
        if ([keysToKeep containsObject:curKeyData]) {
            // Do not delete blob. It is an exception.
            [filesToKeep addObject:oneRow.blobFilename];

            continue;
        }

        // Remove from db
        if (![TD_Database deleteRowForKey:oneRow.key inBlobFilenamesTableInDatabase:db]) {
            CDTLogError(CDTDATASTORE_LOG_CONTEXT, @"%@: Failed to delete '%@' from db", self,
                        oneRow.blobFilename);

            success = NO;

            // Do not try to delete it later, it will not be deleted from db
            [filesToKeep addObject:oneRow.blobFilename];
        }
    }

    // Delete attachments from disk. In fact, this method will delete all the files in the folder
    // but the exception
    // NOTICE: If for some reason one of the files is not deleted and later we generate the same
    // filename for another attachment, the content of this file will be overwritten with the new
    // data
    [TDBlobStore deleteFilesNotInSet:filesToKeep fromPath:_path];

    // Return
    return success;
}

+ (void)deleteFilesNotInSet:(NSSet*)filesToKeep fromPath:(NSString *)path
{
    NSFileManager* defaultManager = [NSFileManager defaultManager];

    // Read directory
    NSError* thisError = nil;
    NSArray* currentFiles = [defaultManager contentsOfDirectoryAtPath:path error:&thisError];
    if (!currentFiles) {
        CDTLogError(CDTDATASTORE_LOG_CONTEXT, @"Can not read dir %@: %@", path, thisError);
        return;
    }

    // Delete all files but exceptions
    for (NSString* filename in currentFiles) {
        if ([filesToKeep containsObject:filename]) {
            // Do not delete file. It is an exception.
            continue;
        }

        NSString* filePath = [TDBlobStore blobPathWithStorePath:path blobFilename:filename];

        if (![defaultManager removeItemAtPath:filePath error:&thisError]) {
            CDTLogError(CDTDATASTORE_LOG_CONTEXT,
                        @"%@: Failed to delete '%@' not related to an attachment: %@", self,
                        filename, thisError);
        }
    }
}

- (NSString*)tempDir
{
    if (!_tempDir) {
// Find a temporary directory suitable for files that will be moved into the store:
#ifdef GNUSTEP
        _tempDir = [NSTemporaryDirectory() copy];
#else
        NSError* error;
        NSURL* parentURL = [NSURL fileURLWithPath:_path isDirectory:YES];
        NSURL* tempDirURL =
            [[NSFileManager defaultManager] URLForDirectory:NSItemReplacementDirectory
                                                   inDomain:NSUserDomainMask
                                          appropriateForURL:parentURL
                                                     create:YES
                                                      error:&error];
        _tempDir = [tempDirURL.path copy];
        CDTLogInfo(CDTDATASTORE_LOG_CONTEXT, @"TDBlobStore %@ created tempDir %@", _path, _tempDir);
        if (!_tempDir)
            CDTLogDebug(CDTDATASTORE_LOG_CONTEXT, @"TDBlobStore: Unable to create temp dir: %@", error);
#endif
    }
    return _tempDir;
}

+ (NSError *)errorNoFilenameGenerated
{
    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey :
            NSLocalizedString(@"No filename generated", @"No filename generated")
    };

    return [NSError errorWithDomain:CDTBlobStoreErrorDomain
                               code:CDTBlobStoreErrorNoFilenameGenerated
                           userInfo:userInfo];
}

@end

@implementation TDBlobStoreWriter

@synthesize length = _length, blobKey = _blobKey;

- (id)initWithStore:(TDBlobStore*)store
{
    self = [super init];
    if (self) {
        _store = store;
        SHA1_Init(&_shaCtx);
        MD5_Init(&_md5Ctx);

        // Open a temporary file in the store's temporary directory:
        NSString* filename = [TDCreateUUID() stringByAppendingPathExtension:@"blobtmp"];
        _tempPath = [[_store.tempDir stringByAppendingPathComponent:filename] copy];
        if (!_tempPath) {
            return nil;
        }
        
        _blobWriter = [store.blobHandleFactory writerWithPath:_tempPath];
        if (![_blobWriter openForWriting]) {
            return nil;
        }
    }
    return self;
}

- (void)appendData:(NSData*)data
{
    [_blobWriter appendData:data];
    NSUInteger dataLen = data.length;
    _length += dataLen;
    SHA1_Update(&_shaCtx, data.bytes, dataLen);
    MD5_Update(&_md5Ctx, data.bytes, dataLen);
}

- (void)closeFile
{
    [_blobWriter close];
    _blobWriter = nil;
}

- (void)finish
{
    Assert(_blobWriter, @"Already finished");
    [self closeFile];
    SHA1_Final(_blobKey.bytes, &_shaCtx);
    MD5_Final(_MD5Digest.bytes, &_md5Ctx);
}

- (NSString*)MD5DigestString
{
    return
        [@"md5-" stringByAppendingString:[TDBase64 encode:&_MD5Digest length:sizeof(_MD5Digest)]];
}

- (NSString*)SHA1DigestString
{
    return [@"sha1-" stringByAppendingString:[TDBase64 encode:&_blobKey length:sizeof(_blobKey)]];
}

- (BOOL)installWithDatabase:(FMDatabase *)db
{
    if (!_tempPath) {
        return YES;  // already installed
    }

    Assert(!_blobWriter, @"Not finished");

    // Search filename
    NSString *filename = [self filenameInDatabase:db];
    if (filename) {
        CDTLogDebug(CDTDATASTORE_LOG_CONTEXT, @"Key already exists with filename %@", filename);

        [self cancel];

        return YES;
    }

    // Create if not exists
    filename = [self generateAndInsertRandomFilenameInDatabase:db];
    if (!filename) {
        CDTLogError(CDTDATASTORE_LOG_CONTEXT, @"No filename generated");

        [self cancel];

        return NO;
    }

    // Check there is not a file in the destination path with the same filename
    NSString *dstPath = [TDBlobStore blobPathWithStorePath:_store.path blobFilename:filename];

    NSFileManager *defaultManager = [NSFileManager defaultManager];

    NSError *error = nil;
    if ([defaultManager fileExistsAtPath:dstPath]) {
        CDTLogDebug(CDTDATASTORE_LOG_CONTEXT, @"File exists at path %@. Delete before moving",
                    dstPath);

        // If this ever happens, we can safely assume that on a previous moment
        // 'TDBlobStore:storeBlob:creatingKey:withDatabase:error:' (or
        // 'TDBlobStoreWriter:installWithDatabase:') was executed in a block that was finally
        // rollback. Therefore, the file in the destination path is not linked to any attachment
        // and we can remove it.
        if (![defaultManager removeItemAtPath:dstPath error:&error]) {
            CDTLogError(CDTDATASTORE_LOG_CONTEXT, @"Not deleted pre-existing file at path %@: %@",
                        dstPath, error);

            [self deleteFilenameInDatabase:db];

            [self cancel];

            return NO;
        }
    }

    // Move temp file to correct location in blob store:
    if (![defaultManager moveItemAtPath:_tempPath toPath:dstPath error:&error]) {
        CDTLogError(CDTDATASTORE_LOG_CONTEXT, @"File not moved to final destination %@: %@",
                    dstPath, error);

        [self deleteFilenameInDatabase:db];

        [self cancel];

        return NO;
    }

    // Return
    _tempPath = nil;

    return YES;
}

- (void)cancel
{
    [self closeFile];
    if (_tempPath) {
        [[NSFileManager defaultManager] removeItemAtPath:_tempPath error:NULL];
        _tempPath = nil;
    }
}

- (void)dealloc
{
    [self cancel];  // Close file, and delete it if it hasn't been installed yet
}

#pragma mark - TDBlobStore+Internal methods
- (NSString *)tempPath { return _tempPath; }

- (NSString *)filenameInDatabase:(FMDatabase *)db
{
    return [TD_Database filenameForKey:_blobKey inBlobFilenamesTableInDatabase:db];
}

- (NSString *)generateAndInsertRandomFilenameInDatabase:(FMDatabase *)db
{
    return [TD_Database generateAndInsertRandomFilenameBasedOnKey:_blobKey
                                 intoBlobFilenamesTableInDatabase:db];
}

- (BOOL)deleteFilenameInDatabase:(FMDatabase *)db
{
    return [TD_Database deleteRowForKey:_blobKey inBlobFilenamesTableInDatabase:db];
}

@end
