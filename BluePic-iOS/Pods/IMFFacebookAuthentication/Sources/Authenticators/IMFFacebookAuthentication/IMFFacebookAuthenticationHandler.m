/*
 * IBM Confidential OCO Source Materials
 * 
 * Copyright IBM Corp. 2006, 2013
 * 
 * The source code for this program is not published or otherwise
 * divested of its trade secrets, irrespective of what has
 * been deposited with the U.S. Copyright Office.
 * 
 */

#import <IMFCore/IMFCore.h>
#import "IMFFacebookAuthenticationHandler.h"
#import "IMFDefaultFacebookAuthenticationDelegate.h"

@interface IMFFacebookAuthenticationHandler ()
@property id<IMFFacebookAuthenticationDelegate> facebookAuthenticationDelegate;
@property id<IMFAuthenticationContext> currentContext;
@end

@implementation IMFFacebookAuthenticationHandler

@synthesize facebookAuthenticationDelegate, currentContext;

NSString *const FACEBOOK_REALM = @"wl_facebookRealm";
NSString *const ACCESS_TOKEN_KEY = @"accessToken";
NSString *const FACEBOOK_APP_ID_KEY = @"facebookAppId";

+ (IMFFacebookAuthenticationHandler*) sharedInstance {
    static IMFFacebookAuthenticationHandler *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void) registerWithDefaultDelegate {
    [self registerWithDelegate: [[IMFDefaultFacebookAuthenticationDelegate alloc] init]];
}

- (void) registerWithDelegate:(id<IMFFacebookAuthenticationDelegate>)facebookAuthenticationHandlerDelegate {
    facebookAuthenticationDelegate = facebookAuthenticationHandlerDelegate;
    [[IMFClient sharedInstance] registerAuthenticationDelegate:self forRealm:FACEBOOK_REALM];
}

- (void) didFinishFacebookAuthenticationWithAccessToken:(NSString*) facebookAccessToken {
    [currentContext submitAuthenticationChallengeAnswer:[NSDictionary dictionaryWithObject:facebookAccessToken forKey:ACCESS_TOKEN_KEY]];
}

- (void) didFailFacebookAuthenticationWithUserInfo:(NSDictionary*) userInfo{
    [currentContext submitAuthenticationFailure:userInfo];
    currentContext = nil;
}

- (void) authenticationContext:(id<IMFAuthenticationContext>)context didReceiveAuthenticationChallenge:(NSDictionary *)challenge {
    NSString *appId = [challenge valueForKey:FACEBOOK_APP_ID_KEY];
   
    [self setCurrentContext:context];
    [[self facebookAuthenticationDelegate] authenticationHandler:self didReceiveAuthenticationRequestForAppId:appId];
}

-(void) authenticationContext:(id<IMFAuthenticationContext>)context didReceiveAuthenticationFailure:(NSDictionary *)userInfo {
    currentContext = nil;
}

- (void) authenticationContext:(id<IMFAuthenticationContext>)context didReceiveAuthenticationSuccess:(NSDictionary *)userInfo {
    currentContext = nil;
}

@end

#define IMF_FACEBOOK_AUTHENTICATION_VERSION     @"1.0"

@implementation IMFFacebookAuthentication
/**
 * Returns the current IMFFacebookAuthentication version
 */
+(NSString*) version {
    return IMF_FACEBOOK_AUTHENTICATION_VERSION;
}
@end
