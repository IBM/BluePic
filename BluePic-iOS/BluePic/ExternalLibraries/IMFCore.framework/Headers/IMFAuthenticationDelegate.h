/*
 * Licensed Materials - Property of IBM
 * (C) Copyright IBM Corp. 2006, 2013. All Rights Reserved.
 * US Government Users Restricted Rights - Use, duplication or
 * disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 */

//
//  IMFAuthenticationDelegate.h
//  IMFCore
//
//  Created by Vitaly Meytin on 9/3/14.
//  Copyright (c) 2014 IBM. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol IMFAuthenticationContext;

@protocol IMFAuthenticationDelegate <NSObject>

/**
 * Called when authentication challenge was received
 @param context Authentication context
 @param challenge Dictionary with challenge data
 */
- (void)authenticationContext:(id<IMFAuthenticationContext>)context didReceiveAuthenticationChallenge:(NSDictionary*)challenge;

/**
 * Called when authentication succeeded
 @param context Authentication context
 @param userInfo Dictionary with extended data about authentication success
 */
- (void)authenticationContext:(id<IMFAuthenticationContext>)context didReceiveAuthenticationSuccess:(NSDictionary *)userInfo;

/**
 * Called when authentication failed.
 @param context Authentication context
 @param userInfo Dictionary with extended data about authentication failure
 */
- (void)authenticationContext:(id<IMFAuthenticationContext>)context didReceiveAuthenticationFailure:(NSDictionary*)userInfo;

@end
