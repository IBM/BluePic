//
//  MYURLUtils.h
//  TouchDB
//
//  Created by Jens Alfke on 5/15/12.
//  Copyright (c) 2012 Couchbase, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


/** Shorthand for creating an NSURL. */
static inline NSURL* $url(NSString* str) {
    return [NSURL URLWithString: str];
}


@interface NSURL (MYUtilities)

/** The port number explicitly or implicitly specified by this URL. */
@property (readonly) UInt16 my_effectivePort;

/** YES if the scheme is 'https:'. */
@property (readonly) BOOL my_isHTTPS;

/** The path and everything after it. This is what appears on the first line of an HTTP request. */
@property (readonly) NSString* my_pathAndQuery;

/** Returns an NSURLProtectionSpace initialized based on the attributes of this URL
    (host, effective port, scheme) and the given realm and authentication method. */
- (NSURLProtectionSpace*) my_protectionSpaceWithRealm: (NSString*)realm
                                 authenticationMethod: (NSString*)authenticationMethod;

/** Looks up a credential for this URL.
    It will be looked up from the shared NSURLCredentialStorage (ie. the Keychain),
    unless using a username and password hardcoded in the URL itself. */
- (NSURLCredential*) my_credentialForRealm: (NSString*)realm
                      authenticationMethod: (NSString*)authenticationMethod;

@end
