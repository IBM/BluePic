/*
 * Licensed Materials - Property of IBM
 * (C) Copyright IBM Corp. 2006, 2013. All Rights Reserved.
 * US Government Users Restricted Rights - Use, duplication or
 * disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 */
//
//  IMFClientResponse.h
//  NewIMFAPIApp
//
//  Created by Anton Aleksandrov on 30/07/14.
//
//

#import <Foundation/Foundation.h>
/**
 *  Response from the server
 */
@interface IMFResponse : NSObject

/**
*  Retrieves the HTTP status from the response
*/
@property (nonatomic) int httpStatus;
/**
 *  Retrieves the headers from the response
 */
@property (nonatomic, strong) NSDictionary* responseHeaders;
/**
 * Original response text from the server
 */
@property (nonatomic, strong) NSString* responseText;
/**
 * Returns the value <em>NSDictionary</em> in case the response is a JSON response, 
 * otherwise it returns the value nil. 
 * <p>
 * <em>NSDictionary</em> represents the root of the JSON object.
 *
 **/
@property (nonatomic, strong) NSDictionary* responseJson;

/**
 *  Return the authorization header if it exists, else returns nil
 */
@property (nonatomic, readonly) NSString* authorizationHeader;

@end
