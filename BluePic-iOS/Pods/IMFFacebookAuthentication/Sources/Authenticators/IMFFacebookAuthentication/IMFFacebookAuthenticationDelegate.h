/*
 * Licensed Materials - Property of IBM
 * (C) Copyright IBM Corp. 2006, 2013. All Rights Reserved.
 * US Government Users Restricted Rights - Use, duplication or
 * disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 */

@class IMFFacebookAuthenticationHandler;

/**
 * Protocol for performing Facebook authentication.
 */
@protocol IMFFacebookAuthenticationDelegate

/**
 * Signs-in to Facebook and sends the Facebook access token back to the authentication handler.
 *
 * @param authenticationHandler Facebook authentication handler.  This handler receives the access token when sign-in is complete.
 * @param appId                 The Facebook app id.
 */
- (void)authenticationHandler:(IMFFacebookAuthenticationHandler*)authenticationHandler didReceiveAuthenticationRequestForAppId:(NSString*)appId;

@end

