/*
 * Licensed Materials - Property of IBM
 * (C) Copyright IBM Corp. 2006, 2013. All Rights Reserved.
 * US Government Users Restricted Rights - Use, duplication or
 * disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 */

#import <Foundation/Foundation.h>

@interface WLTouchIdSecurityUtils : NSObject

/**
 Reads a keychain secret
 @param service Service of the keychain secret
 @param account Account of the keychain secret
 @param description Message prompted to user if unlock is necessary
 @return Secret value
 */
+(NSString*) _readSecretForService:(NSString*) service
                        andAccount:(NSString*) account
                   withDescription:(NSString*) description;

/**
 Deletes keychain secret for service and account
 @param service Service of the keychain secret
 @param account Account of the keychain secret. If nil, all accounts will be deleted.
 */
+(BOOL) _deleteSecretForService:(NSString*) service andAccount: (NSString *)account;

/**
 Deletes all keychain secrets for a service
 @return True if the supports MIGHT support Touch ID authentication, False if the device definitely does not support Touch ID
 */
+(BOOL) _deviceMightSupportsTouchId;

/**
 Protects a keychain secret using Touch ID
 @param secret The value of the keychain secret to be protected
 @param service Service of the keychain secret
 @param account Account of the keychain secret
 @return True if the secret was stored in the keychain. False otherwise
 */
+(BOOL) _protectUsingTouchIdWithSecret:(NSString*) secret
                            forService:(NSString*) service
                            andAccount:(NSString*) account;


+(BOOL) _updateUsingTouchIdWithSecret:(NSString*) secret
                           forService:(NSString*) service
                           andAccount:(NSString*) account
                           withDescription:(NSString*) description;
@end
