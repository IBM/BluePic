/*
 * Licensed Materials - Property of IBM
 * (C) Copyright IBM Corp. 2006, 2013. All Rights Reserved.
 * US Government Users Restricted Rights - Use, duplication or
 * disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 */


#import <Foundation/Foundation.h>
#import "IMFResponse.h"

/**
 * Manages entire OAuth flow, from client registration to token generation.
 */
 
typedef NS_ENUM(NSInteger, IMFAuthorizationPerisistencePolicy) {
    IMFAuthorizationPerisistencePolicyAlways = 0,
    IMFAuthorizationPerisistencePolicyWithTouchBiometrics = 1,
    IMFAuthorizationPerisistencePolicyNever = 2
};

@interface IMFAuthorizationManager : NSObject

/**
 *  Gets cached authorization header from keychain
 */
@property (nonatomic, readonly) NSString *cachedAuthorizationHeader;

@property (nonatomic, readonly) NSDictionary *userIdentity;

@property (nonatomic, readonly) NSDictionary *deviceIdentity;

@property (nonatomic, readonly) NSDictionary *appIdentity;

/**
 *  Gets IMFAuthorizationManager shared instance
 *
 *  @return IMFAuthorizationManager shared instance
 */
+ (IMFAuthorizationManager *) sharedInstance;
 
/**
 *  Obtains access token
 *
 *  @param completionHandler Completion handler with response containing authorization header value
 */
- (void) obtainAuthorizationHeaderWithCompletionHandler:(void(^) (IMFResponse* response, NSError* error))completionHandler;

/**
 *  Adds authorization header value to any NSURLRequest request
 *
 *  @param request Request to add authorization header
 */
- (void) addCachedAuthorizationHeaderToRequest:(NSMutableURLRequest*)request;

/**
 *  Sets policy for the application to handle storage of authorization access tokens
 *
 *  @param policy Persistence policy
 *  The policy can be one of the following:
 *	<ul>
 *  <li>__IMFAuthorizationPerisistencePolicyAlways__:
 *  Always store access token on the device (the least secure option). 
 *  The access tokens are persisted, regardless of whether Touch ID is present, supported, or enabled. 
 *  Touch ID and device passcode authentication are never required.</li>
 *  
 *  <li>__IMFAuthorizationPerisistencePolicyWithTouchBiometrics__
 *  Use the Touch ID interface to fetch the access token from the keychain (the option that balances security and ease of use). 
 *  The access tokens are persisted, only if Touch ID is present, supported, and enabled. 
 *  Touch ID and/or device passcode authentication are required to access the token once per client session.</li>
 *  
 *  <li>__IMFAuthorizationPerisistencePolicyNever__
 *  Never store access token on the device (the most secure option). 
 *  The access tokens are never persisted, meaning that an access token is 
 *  valid for the duration of the application session only.</ul>
 *  <p>
 *  The default policy is __IMFAuthorizationPerisistencePolicyAlways__.
 *  <p>
 *  When this policy has been set, but there is no access to Touch ID, for example, 
 *  because the necessary hardware is not present or has been disabled, 
 *  the fallback is IMFAuthorizationPersistancePolicyNever
 *
 *  Examples of use:
 *
 *  Set __IMFAuthorizationPerisistencePolicyAlways__ policy:<br />
 *          <pre><code>IMFAuthorizationManager* manager = [IMFAuthorizationManager sharedInstance];
 *          [manager setAuthorizationPersistencePolicy: IMFAuthorizationPerisistencePolicyAlways];</code></pre>
 *
 *  Set __IMFAuthorizationPerisistencePolicyWithTouchBiometrics__ policy:<br />
 *          <pre><code>IMFAuthorizationManager* manager = [IMFAuthorizationManager sharedInstance];
 *          [manager setAuthorizationPersistencePolicy: IMFAuthorizationPerisistencePolicyWithTouchBiometrics];</code></pre>
 *  
 *  Set __IMFAuthorizationPerisistencePolicyNever__ policy:<br />
 *          <pre><code>IMFAuthorizationManager* manager = [IMFAuthorizationManager sharedInstance];
 *          [manager setAuthorizationPersistencePolicy: IMFAuthorizationPerisistencePolicyNever];</code></pre>
 */
- (void) setAuthorizationPersistencePolicy: (IMFAuthorizationPerisistencePolicy) policy;

/**
 * A response is an OAuth error response only if,
 * 1. it's status is 401 or 403
 * 2. The value of the "WWW-Authenticate" header contains 'Bearer'
 *
 * @param response to check the conditions for.
 * @return true if the response satisfies both conditions
 */
- (BOOL) isAuthorizationRequired: (IMFResponse *)response;

/**
 * Check if the params came from response that requires authorization
 * @param statusCode of the response
 * @param authorizationHeaderValue value of 'WWW-Authenticate' header
 * @return true if status is 401 or 403 and The value of the header contains 'Bearer'
 */
- (BOOL) isAuthorizationRequired: (int)statusCode authorizationHeaderValue: (NSString*)authorizationHeaderValue;

@end
