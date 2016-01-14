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

#import <FacebookSDK/FacebookSDK.h>
#import "IMFDefaultFacebookAuthenticationDelegate.h"
#import "IMFFacebookAuthenticationHandler.h"

@implementation IMFDefaultFacebookAuthenticationDelegate

- (void) authenticationHandler:(IMFFacebookAuthenticationHandler *)authenticationHandler didReceiveAuthenticationRequestForAppId:(NSString *)appId {
    // Verify that the app Id defined in the .plist file is identical to the one requested by the IMF server.
    if (![appId isEqualToString:[FBSettings defaultAppID]]){
        [authenticationHandler didFailFacebookAuthenticationWithUserInfo:
         [NSDictionary dictionaryWithObject:@"App Id from IMF server doesn't match the one defined in the .plist file" forKey:NSLocalizedDescriptionKey]];
        return;
    }
    
    // Use the Facebook SDK to login.
    [FBSession openActiveSessionWithReadPermissions:@[@"public_profile"]
                                       allowLoginUI:YES
                                  completionHandler:
     ^(FBSession *session, FBSessionState state, NSError *error) {
         if (!error && state == FBSessionStateOpen){
             // If login is successful, pass the access token to the authentication delegate.
             NSString *accessToken = [[session accessTokenData] accessToken];
             [authenticationHandler didFinishFacebookAuthenticationWithAccessToken: accessToken];
             return;
         }
         
         // Login was not successful. Fail the authentication.
         [FBSession.activeSession closeAndClearTokenInformation];
         NSLog(@"Could not get an access token from facebook: %@", [error userInfo]);
         
         [authenticationHandler didFailFacebookAuthenticationWithUserInfo: [error userInfo]];
     }];
}

@end
