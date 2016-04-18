//
//  CDTEncryptionKeychainStorage.m
//  CloudantSync
//
//  Created by Enrique de la Torre Fernandez on 12/04/2015.
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

#import "CDTEncryptionKeychainStorage.h"

#import "CDTLogging.h"

#define CDTENCRYPTION_KEYCHAINSTORAGE_SERVICE_VALUE \
    @"com.cloudant.sync.CDTEncryptionKeychainStorage.keychain.service"

#define CDTENCRYPTION_KEYCHAINSTORAGE_ARCHIVE_KEY \
    @"com.cloudant.sync.CDTEncryptionKeychainStorage.archive.key"

@interface CDTEncryptionKeychainStorage ()

@property (strong, nonatomic, readonly) NSString *service;
@property (strong, nonatomic, readonly) NSString *account;

@end

@implementation CDTEncryptionKeychainStorage

#pragma mark - Init object
- (instancetype)init
{
    return [self initWithIdentifier:nil];
}

- (instancetype)initWithIdentifier:(NSString *)identifier
{
    self = [super init];
    if (self) {
        if (identifier) {
            _service = CDTENCRYPTION_KEYCHAINSTORAGE_SERVICE_VALUE;
            _account = identifier;
        } else {
            self = nil;
            
            CDTLogError(CDTDATASTORE_LOG_CONTEXT, @"identifier is mandatory");
        }
    }
    
    return self;
}

#pragma mark - Public methods
- (CDTEncryptionKeychainData *)encryptionKeyData
{
    CDTEncryptionKeychainData *encryptionData = nil;

    NSData *data =
        [CDTEncryptionKeychainStorage genericPwWithService:self.service account:self.account];
    if (data) {
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        [unarchiver setRequiresSecureCoding:YES];

        encryptionData = [unarchiver decodeObjectOfClass:[CDTEncryptionKeychainData class]
                                                  forKey:CDTENCRYPTION_KEYCHAINSTORAGE_ARCHIVE_KEY];

        [unarchiver finishDecoding];
    }

    return encryptionData;
}

- (BOOL)saveEncryptionKeyData:(CDTEncryptionKeychainData *)data
{
    NSMutableData *archivedData = [NSMutableData data];
    NSKeyedArchiver *archiver =
        [[NSKeyedArchiver alloc] initForWritingWithMutableData:archivedData];
    [archiver setRequiresSecureCoding:YES];
    [archiver encodeObject:data forKey:CDTENCRYPTION_KEYCHAINSTORAGE_ARCHIVE_KEY];
    [archiver finishEncoding];

    BOOL success = [CDTEncryptionKeychainStorage storeGenericPwWithService:self.service
                                                                   account:self.account
                                                                      data:archivedData];

    return success;
}

- (BOOL)clearEncryptionKeyData
{
    BOOL success =
        [CDTEncryptionKeychainStorage deleteGenericPwWithService:self.service account:self.account];

    return success;
}

- (BOOL)encryptionKeyDataExists
{
    NSData *data =
        [CDTEncryptionKeychainStorage genericPwWithService:self.service account:self.account];

    return (data != nil);
}

#pragma mark - Private class methods

+ (NSData *)genericPwWithService:(NSString *)service account:(NSString *)account
{
    OSStatus err = errSecSuccess;
    NSData *data = [CDTEncryptionKeychainStorage targetSpecificGenericPwWithService:service
                                                                            account:account
                                                                             status:&err];
    if (err != errSecSuccess) {
        if (err == errSecItemNotFound) {
            CDTLogWarn(CDTDATASTORE_LOG_CONTEXT, @"DPK doc not found in keychain");
        } else {
            CDTLogWarn(CDTDATASTORE_LOG_CONTEXT,
                       @"Error getting DPK doc from keychain, value returned: %d", err);
        }

        data = nil;
    }

    return data;
}

+ (BOOL)deleteGenericPwWithService:(NSString *)service account:(NSString *)account
{
    OSStatus status =
        [CDTEncryptionKeychainStorage targetSpecificDeleteGenericPwWithService:service
                                                                       account:account];
    BOOL success = ((status == errSecSuccess) || (status == errSecItemNotFound));
    if (!success) {
        CDTLogWarn(CDTDATASTORE_LOG_CONTEXT,
                   @"Error getting DPK doc from keychain, value returned: %d", status);
    }

    return success;
}

+ (BOOL)storeGenericPwWithService:(NSString *)service
                          account:(NSString *)account
                             data:(NSData *)data
{
    OSStatus err = [CDTEncryptionKeychainStorage targetSpecificStoreGenericPwWithService:service
                                                                                 account:account
                                                                                    data:data];
    BOOL success = (err == errSecSuccess);
    if (!success) {
        if (err == errSecDuplicateItem) {
            CDTLogWarn(CDTDATASTORE_LOG_CONTEXT, @"Doc already exists in keychain");
        } else {
            CDTLogWarn(CDTDATASTORE_LOG_CONTEXT,
                       @"Unable to store Doc in keychain, value returned: %d", err);
        }
    }
    
    return success;
}

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

+ (NSData *)targetSpecificGenericPwWithService:(NSString *)service
                                       account:(NSString *)account
                                        status:(OSStatus *)status
{
    NSData *data = nil;

    NSMutableDictionary *query =
        [CDTEncryptionKeychainStorage genericPwLookupDictWithService:service account:account];

    OSStatus thisStatus = SecItemCopyMatching((__bridge CFDictionaryRef)query, (void *)&data);
    if (status) {
        *status = thisStatus;
    }

    return data;
}

+ (OSStatus)targetSpecificDeleteGenericPwWithService:(NSString *)service account:(NSString *)account
{
    NSMutableDictionary *dict =
        [CDTEncryptionKeychainStorage genericPwLookupDictWithService:service account:account];
    [dict removeObjectForKey:(__bridge id)(kSecMatchLimit)];
    [dict removeObjectForKey:(__bridge id)(kSecReturnAttributes)];
    [dict removeObjectForKey:(__bridge id)(kSecReturnData)];

    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)dict);

    return status;
}

+ (OSStatus)targetSpecificStoreGenericPwWithService:(NSString *)service
                                            account:(NSString *)account
                                               data:(NSData *)data
{
    NSMutableDictionary *dataStoreDict =
        [CDTEncryptionKeychainStorage genericPwStoreDictWithService:service
                                                            account:account
                                                               data:data];

    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)dataStoreDict, nil);

    return status;
}

+ (NSMutableDictionary *)genericPwLookupDictWithService:(NSString *)service
                                                account:(NSString *)account
{
    NSMutableDictionary *genericPasswordQuery = [[NSMutableDictionary alloc] init];

    [genericPasswordQuery setObject:(__bridge id)kSecClassGenericPassword
                             forKey:(__bridge id)kSecClass];
    [genericPasswordQuery setObject:service forKey:(__bridge id<NSCopying>)(kSecAttrService)];
    [genericPasswordQuery setObject:account forKey:(__bridge id<NSCopying>)(kSecAttrAccount)];

    // Use the proper search constants, return only the attributes of the first match.
    [genericPasswordQuery setObject:(__bridge id)kSecMatchLimitOne
                             forKey:(__bridge id<NSCopying>)(kSecMatchLimit)];
    [genericPasswordQuery setObject:(__bridge id)kCFBooleanFalse
                             forKey:(__bridge id<NSCopying>)(kSecReturnAttributes)];
    [genericPasswordQuery setObject:(__bridge id)kCFBooleanTrue
                             forKey:(__bridge id<NSCopying>)(kSecReturnData)];

    return genericPasswordQuery;
}

+ (NSMutableDictionary *)genericPwStoreDictWithService:(NSString *)service
                                               account:(NSString *)account
                                                  data:(NSData *)data
{
    NSMutableDictionary *genericPasswordQuery = [[NSMutableDictionary alloc] init];

    [genericPasswordQuery setObject:(__bridge id)kSecClassGenericPassword
                             forKey:(__bridge id)kSecClass];
    [genericPasswordQuery setObject:service forKey:(__bridge id<NSCopying>)(kSecAttrService)];
    [genericPasswordQuery setObject:account forKey:(__bridge id<NSCopying>)(kSecAttrAccount)];

    [genericPasswordQuery setObject:data forKey:(__bridge id<NSCopying>)(kSecValueData)];

    [genericPasswordQuery setObject:(__bridge id)(kSecAttrAccessibleAfterFirstUnlock)
                             forKey:(__bridge id<NSCopying>)(kSecAttrAccessible)];

    return genericPasswordQuery;
}

#else

+ (NSData *)targetSpecificGenericPwWithService:(NSString *)service
                                       account:(NSString *)account
                                        status:(OSStatus *)status
{
    NSData *data = nil;

    const char *serviceUTF8Str = service.UTF8String;
    UInt32 serviceUTF8StrLength = (UInt32)strlen(serviceUTF8Str);

    const char *accountUTF8Str = account.UTF8String;
    UInt32 accountUTF8StrLength = (UInt32)strlen(accountUTF8Str);

    void *passwordData = NULL;
    UInt32 passwordDataLength = 0;

    OSStatus thisStatus = SecKeychainFindGenericPassword(NULL, serviceUTF8StrLength, serviceUTF8Str,
                                                         accountUTF8StrLength, accountUTF8Str,
                                                         &passwordDataLength, &passwordData, NULL);
    if (passwordData) {
        if (thisStatus == errSecSuccess) {
            data = [NSData dataWithBytes:passwordData length:passwordDataLength];
        }

        SecKeychainItemFreeContent(NULL, passwordData);
    }

    if (status) {
        *status = thisStatus;
    }

    return data;
}

+ (OSStatus)targetSpecificDeleteGenericPwWithService:(NSString *)service account:(NSString *)account
{
    // Find the item
    const char *serviceUTF8Str = service.UTF8String;
    UInt32 serviceUTF8StrLength = (UInt32)strlen(serviceUTF8Str);

    const char *accountUTF8Str = account.UTF8String;
    UInt32 accountUTF8StrLength = (UInt32)strlen(accountUTF8Str);

    SecKeychainItemRef itemRef = NULL;

    OSStatus status =
        SecKeychainFindGenericPassword(NULL, serviceUTF8StrLength, serviceUTF8Str,
                                       accountUTF8StrLength, accountUTF8Str, NULL, NULL, &itemRef);
    if (status != errSecSuccess) {
        if (itemRef) {
            CFRelease(itemRef);
        }

        return status;
    }

    // Delete the item
    status = SecKeychainItemDelete(itemRef);
    CFRelease(itemRef);

    return status;
}

+ (OSStatus)targetSpecificStoreGenericPwWithService:(NSString *)service
                                            account:(NSString *)account
                                               data:(NSData *)data
{
    const char *serviceUTF8Str = service.UTF8String;
    UInt32 serviceUTF8StrLength = (UInt32)strlen(serviceUTF8Str);

    const char *accountUTF8Str = account.UTF8String;
    UInt32 accountUTF8StrLength = (UInt32)strlen(accountUTF8Str);

    const void *passwordData = data.bytes;
    UInt32 passwordDataLength = (UInt32)data.length;

    OSStatus status = SecKeychainAddGenericPassword(NULL, serviceUTF8StrLength, serviceUTF8Str,
                                                    accountUTF8StrLength, accountUTF8Str,
                                                    passwordDataLength, passwordData, NULL);

    return status;
}

#endif

@end
