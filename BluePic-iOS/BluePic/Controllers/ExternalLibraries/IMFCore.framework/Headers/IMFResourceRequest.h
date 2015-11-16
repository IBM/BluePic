/*
 * Licensed Materials - Property of IBM
 * (C) Copyright IBM Corp. 2006, 2013. All Rights Reserved.
 * US Government Users Restricted Rights - Use, duplication or
 * disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 */
//
//  IMFResourceRequest.h
//  IMFCore
//
//  Created by Vitaly Meytin on 9/2/14.
//  Copyright (c) 2014 IBM. All rights reserved.
//
#import <Foundation/Foundation.h>

enum {
    /**
     Internal request error
     */
    IMFResourseRequestErrorInternalError = 1,
    /**
     Resource request is not initialized. Call one of requestWithPath initializers first.
     */
    IMFResourseRequestErrorNotInitialized = 2,
    /**
     Request method is nil.
     */
    IMFResourseRequestErrorInvalidMethod = 3
};

@class IMFResponse;

@interface IMFResourceRequest : NSObject

/**
 * Returns an <em>IMFResourceRequest</em> object initialized with path. The path should not be nil, otherwise other methods will fail.
 * @param path Path to resource
 * @return <em>IMFResourceRequest</em> initialized with path to resource
 */
+(IMFResourceRequest*)requestWithPath:(NSString*)path;

/**
 * Returns an <em>IMFResourceRequest</em> object initialized with path and request method. The path should not be nil, otherwise other methods will fail.
 * @param path Path to resource
 * @param method Request method. It can be any of the permitted HTTP methods, for example "GET", "POST", "PUT", "DELETE", "HEAD".
 * @return <em>IMFResourceRequest</em> initialized with path to resource and request method
 
 * @exception NSInvalidArgumentException If the URL doesn't start with a protocol (scheme) an NSInvalidArgumentException is thrown
 */
+(IMFResourceRequest*)requestWithPath:(NSString*)path method:(NSString*)method;

/**
 * Returns an <em>IMFResourceRequest</em> object initialized with path, request method and request parameters. The path should not be nil, otherwise other methods will fail.
 * @param path Full path to resource
 * @param method Request method. It can be any of the permitted HTTP methods, for example "GET", "POST", "PUT", "DELETE", "HEAD".
 * @param parameters Request parameters
 * @return <em>IMFResourceRequest</em> initialized with path to resource, request method and request parameters
 * @exception NSInvalidArgumentException If the URL doesn't start with a protocol (scheme) an NSInvalidArgumentException is thrown
 */
+(IMFResourceRequest*)requestWithPath:(NSString*)path method:(NSString*)method parameters:(NSDictionary*)parameters;

/**
 * Returns an <em>IMFResourceRequest</em> object initialized with path, request method and request parameters. The path should not be nil, otherwise other methods will fail.
 * @param path Full path to resource
 * @param method Request method. It can be any of the permitted HTTP methods, for example "GET", "POST", "PUT", "DELETE", "HEAD".
 * @param parameters Request parameters
 * @param timeout Request timeout
 * @return <em>IMFResourceRequest</em> initialized with path to resource, request method, request parameters and timeout
 * @exception NSInvalidArgumentException If the URL doesn't start with a protocol (scheme) an NSInvalidArgumentException is thrown
 */
+(IMFResourceRequest*)requestWithPath:(NSString*)path method:(NSString*)method parameters:(NSDictionary*)parameters timeout:(NSTimeInterval)timeoutInterval;

/**
 * Sets request timeout
 * @param timeoutInterval Request timeout interval in seconds
 */
-(void)setTimeoutInterval:(NSTimeInterval)timeoutInterval;

/**
 * Sets header value
 * @param value Value to set
 * @param forHTTPHeaderField Header field
 */
-(void)setValue:(NSString*)value forHTTPHeaderField:(NSString*)field;

/**
 * Sets request parameters
 * @param parameters Request parameters
 */
-(void)setParameters:(NSDictionary*)parameters;

/**
 * Sets HTTP body 
 * <p>
 * This method should be used for POST requests.
 * @param data The data to be set
 */
-(void)setHTTPBody:(NSData*)data;

/**
 * Sets request method
 * @param method Request method. It can be any of the permitted HTTP methods, for example "GET", "POST", "PUT", "DELETE", "HEAD".
 */
-(void)setHTTPMethod:(NSString*)method;

/**
 * Sends request to resource. The request must have been initialized with a valid path.
 * @discussion If the request is completed successfully, the <em>error</em> parameter of the completion block is nil and the <em>response</em> parameter 
 * contains the server response. If the request fails, the <em>error</em> parameter is not nil and contains an error description. The <em>response</em> parameter may contain
 * a response from the server, or may be nil.
 * @param completionHandler Block to be called when the request is completed
 */
-(void)sendWithCompletionHandler:(void(^) (IMFResponse* response, NSError* error))completionHandler;

@end
