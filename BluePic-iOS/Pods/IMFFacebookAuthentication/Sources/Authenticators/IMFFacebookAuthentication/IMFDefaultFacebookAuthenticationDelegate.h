/*
 * Licensed Materials - Property of IBM
 * (C) Copyright IBM Corp. 2006, 2013. All Rights Reserved.
 * US Government Users Restricted Rights - Use, duplication or
 * disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 */



#import <Foundation/Foundation.h>
#import "IMFFacebookAuthenticationDelegate.h"

/**
 *  Interface for the default Facebook authentication delegate.
 *
 *  To use the default Facebook delegate, call <p>
 *  <code>[[IMFFacebookAuthenticationHandler sharedInstance] registerWithDefaultDelegate]</code>
 *  <p>
 *  before any call to a protected resource.
 */
@interface IMFDefaultFacebookAuthenticationDelegate : NSObject <IMFFacebookAuthenticationDelegate>

@end
