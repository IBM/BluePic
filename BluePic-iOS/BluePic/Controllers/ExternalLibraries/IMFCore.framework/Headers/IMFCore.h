/*
 * Licensed Materials - Property of IBM
 * (C) Copyright IBM Corp. 2006, 2013. All Rights Reserved.
 * US Government Users Restricted Rights - Use, duplication or
 * disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 */
//
//  IMFCore.h
//  IMFCore
//
//  Created by Asaf Manassen on 8/18/14.
//  Copyright (c) 2014 IBM. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for IMFCore.
FOUNDATION_EXPORT double IMFCoreVersionNumber;

//! Project version string for IMFCore.
FOUNDATION_EXPORT const unsigned char IMFCoreVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <IMFCore/PublicHeader.h>


#import <IMFCore/IMFClient.h>
#import <IMFCore/IMFResponse.h>
#import <IMFCore/IMFAuthenticationDelegate.h>
#import <IMFCore/IMFAuthenticationContext.h>
#import <IMFCore/IMFResourceRequest.h>
#import <IMFCore/IMFAuthorizationManager.h>
#import <IMFCore/IMFAnalytics.h>
#import <IMFCore/IMFLogger.h>
#import <IMFCore/IMFLoggerMacros.h>
#import <IMFCore/WLTouchIdSecurityUtils.h>

FOUNDATION_EXPORT NSString* IMFCoreVersion();


