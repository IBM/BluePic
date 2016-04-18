/*
 * Licensed Materials - Property of IBM
 * (C) Copyright IBM Corp. 2006, 2013. All Rights Reserved.
 * US Government Users Restricted Rights - Use, duplication or
 * disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 */

#import <Foundation/Foundation.h>

@class      IMFChallengeHandler;
@protocol   IMFAuthenticationDelegate;

/**
 *  IMFClient error domain
 */
extern NSString * const IMFClientErrorDomain;

enum {
	IMFClientErrorInternalError = 1,
	IMFClientErrorUnresponsiveHost = 2,
	IMFClientErrorRequestTimeout = 3,
	IMFClientErrorServerError = 4,
    IMFClientErrorAuthenticationFailure = 5
};

/**
 *  The entry point to MobileFirst 
 */
@interface IMFClient : NSObject

/**
 * Specifies base back end URL
 */
@property (readonly) NSString* backendRoute;

/**
 * Specifies back end application id.
 */
@property (readonly) NSString* backendGUID;

/**
 * Specifies default request timeout.
 */
@property (readwrite) NSTimeInterval defaultRequestTimeoutInterval;

/**
 * Gets the instance of <em>IMFClient</em> (singleton)
 */
+ (IMFClient*)sharedInstance;

/**
 * Sets the base URL for the authorization server.
 * <p>
 * This method should be called before you send the first request that requires authorization.
 * @param url Specifies the base URL for the authorization server
 * @param backendGUID Specifies the GUID of the application
 */
-(void) initializeWithBackendRoute: (NSString*)backendRoute backendGUID:(NSString*)backendGUID;

/**
 *
 * Add a global header that is sent on each request
 * <p>
 * Each <em>IMFRequest</em> instance will use this header as an HTTP header.
 *
 * @param headerName Header name/key
 * @param value Header value
 * @deprecated Since version 1.1.0
 */
-(void) addGlobalHeader: (NSString *) headerName headerValue:(NSString *)value DEPRECATED_ATTRIBUTE;

/**
 * Removes a global header from the list of global headers to be added to all requests.
 * @param headerName Header to remove
 * @deprecated Since version 1.1.0
 */
- (void) removeGlobalHeader:(NSString*)headerName DEPRECATED_ATTRIBUTE;

/**
 * Registers a delegate that will handle authentication for the specified realm
 * @param authenticationDelegate Delegate that will handle authentication challenges
 * @param realm Realm name
 */
- (void) registerAuthenticationDelegate:(id<IMFAuthenticationDelegate>)authenticationDelegate forRealm:(NSString*)realm;

/**
 * Unregisters an authentication delegate for the specified realm
 * @param realm Realm name
 */
- (void) unregisterAuthenticationDelegateForRealm:(NSString*)realm;

@end

@interface IMFCore : NSObject

/**
 * Returns the current <em>IMFCore<em> version
 */
+(NSString*) version;

@end
