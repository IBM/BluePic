//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//
#import "CloudantSync.h"
#import <FacebookSDK/FacebookSDK.h>
#import <IMFCore/IMFCore.h>
#import <IMFFacebookAuthentication/IMFFacebookAuthenticationHandler.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIImage+GIF.h>

/*
+ (void)getAuthToken:(void (^)(enum NetworkRequest))callback {
    IMFAuthorizationManager *authManager = [IMFAuthorizationManager sharedInstance];
    [authManager obtainAuthorizationHeaderWithCompletionHandler:^(IMFResponse *response, NSError *error) {
        NSMutableString *errorMsg = [[NSMutableString alloc] init];
        if (error != nil) {
            callback(Failure);
            [errorMsg appendString:@"Error obtaining Authentication Header.\nCheck Bundle Identifier and Bundle version string, short in Info.plist match exactly to the ones in AMA, or check the applicationId in bluelist.plist\n\n"];
            if (response != nil) {
                if (response.responseText != nil) {
                    [errorMsg appendString:response.responseText];
                }
            }
            if (error != nil && error.userInfo != nil) {
                [errorMsg appendString:error.userInfo.description];
            }
            
        } else {
            if (authManager.userIdentity != nil) {
                NSString *userId = [authManager.userIdentity valueForKey:@"id"];
                if (userId != nil) {
                    NSLog(@"Authenticated user with id %@", userId);
                    callback(Success);
                } else {
                    NSLog(@"Valid Authentication Header and userIdentity, but id not found");
                    callback(Failure);
                }
            } else {
                NSLog(@"Valid Authentication Header, but userIdentity not found. You have to configure one of the methods available in Advanced Mobile Service on Bluemix, such as Facebook, Google, or Custom ");
                callback(Failure);
            }
        }
    }];
}
*/