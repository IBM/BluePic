/*
 * Licensed Materials - Property of IBM
 * (C) Copyright IBM Corp. 2006, 2013. All Rights Reserved.
 * US Government Users Restricted Rights - Use, duplication or
 * disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 */


#import <Foundation/Foundation.h>
#import <IMFCore/IMFCore.h>
#import "IMFFacebookAuthenticationDelegate.h"

/**
 * Interface for handling Facebook authentication challenges from Advanced Mobile Access.
 */
@interface IMFFacebookAuthenticationHandler : NSObject <IMFAuthenticationDelegate>

/**
 * Singleton for IMFFacebookAuthenticationHandler.
 *
 * @return The shared instance of IMFFacebookAuthenticationHandler.
 */
+ (IMFFacebookAuthenticationHandler*) sharedInstance;

/**
 * Registers this handler to respond to Facebook authentication challenges using the default delegate.
 */
- (void) registerWithDefaultDelegate;

/**
 * Registers this handler to respond to Facebook authentication challenges using a custom delegate.
 *
 * @param facebookAuthenticationDelegate Custom authentication delegate.
 */
- (void) registerWithDelegate:(id<IMFFacebookAuthenticationDelegate>)facebookAuthenticationDelegate;

/**
 * Passes the Facebook access token back to Advanced Mobile Access.
 *
 * @param facebookAccessToken Facebook access token.
 */
- (void) didFinishFacebookAuthenticationWithAccessToken:(NSString*) facebookAccessToken;

/**
 * Called whenever there was a problem receiving the Facebook id token
 *
 * @param userInfo Error user information
 */
- (void) didFailFacebookAuthenticationWithUserInfo:(NSDictionary*) userInfo;

@end

@interface IMFFacebookAuthentication : NSObject

/**
 * Returns the current IMFFacebookAuthentication version
 */
+(NSString*) version;
@end




