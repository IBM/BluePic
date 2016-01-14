//
//  MYErrorUtils.m
//  MYUtilities
//
//  Created by Jens Alfke on 2/25/09.
//  Copyright 2009 Jens Alfke. All rights reserved.
//

#import "MYErrorUtils.h"
#import "Test.h"
#import "CollectionUtils.h"
#import <Foundation/Foundation.h>

#if MYERRORUTILS_USE_SECURITY_API
#import <Security/SecBase.h>
#endif


NSString* const MYErrorDomain = @"MYErrorDomain";


static NSError *MYMakeErrorV( int errorCode, NSString *domain, NSString *message, va_list args )
{
    message = [[NSString alloc] initWithFormat: message arguments: args];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                                      message, NSLocalizedDescriptionKey,
                                                      nil];
    [message release];
    return [NSError errorWithDomain: domain
                               code: errorCode
                           userInfo: userInfo];
}


NSError *MYError( int errorCode, NSString *domain, NSString *message, ... )
{
    va_list args;
    va_start(args,message);
    NSError *error = MYMakeErrorV(errorCode,domain,message,args);
    va_end(args);
    return error;
}


BOOL MYReturnError( NSError **outError,
                    int errorCode, NSString *domain, NSString *messageFormat, ... ) 
{
    if (errorCode) {
        if (outError) {
            va_list args;
            va_start(args,messageFormat);
            *outError = MYMakeErrorV(errorCode, domain, messageFormat, args);
            va_end(args);
            Log(@"MYReturnError: %@",*outError);
        } else
            Log(@"MYReturnError: %@/%i",domain,errorCode);
        return NO;
    } else
        return YES;
}


BOOL MYMiscError( NSError **error, NSString *message, ... )
{
    if (error) {
        va_list args;
        va_start(args,message);
        *error = MYMakeErrorV(kMYErrorMisc,MYErrorDomain, message,args);
        va_end(args);
    }
    return NO;
}


NSError *MYErrorFromErrno(void)
{
    int err = errno;
    if (!err)
        return nil;
    return MYError(err, NSPOSIXErrorDomain, @"%s", strerror(err));
}


static NSString* printableOSType( OSType t ) {
    if (t < 0x20202020 || t > 0x7e7e7e7e)
        return nil;
    union {
        OSType ostype;
        unsigned char ch[4];
    } buf;
    buf.ostype = CFSwapInt32HostToBig(t);
    for (int i=0; i<4; i++)
        if (buf.ch[i] < 0x20 || buf.ch[i] > 0x7E)
            return nil;
    return [[[NSString alloc] initWithBytes: &buf.ch length: 4 encoding: NSMacOSRomanStringEncoding]
            autorelease];
}


static NSString* printableErrorCode( NSInteger code ) {
    if ((OSStatus)code < -99999)
        return $sprintf(@"%u", (unsigned)code);       // CSSM errors are huge unsigned values > 0x80000000
    NSString *result = printableOSType((OSType)code);
    if (result)
        return result;                      // CoreAudio errors are OSTypes (4-char strings)
    return $sprintf(@"%ld", (long)code);    // Default: OSStatus and errno values are signed
}

static NSString* MYShortErrorDomainName( NSString *domain ) {
    if ([domain hasPrefix: @"kCFErrorDomain"])
        domain = [domain substringFromIndex: 14];
    else {
        if ([domain hasSuffix: @"ErrorDomain"])
            domain = [domain substringToIndex: domain.length - 11];
        if ([domain hasPrefix: @"NS"])
            domain = [domain substringFromIndex: 2];
    }
    return domain;
}

NSString* MYErrorName( NSString *domain, NSInteger code ) {
    if (code == 0)
        return nil;
    NSString *codeStr = printableErrorCode(code);
    if (!domain)
        return codeStr;
    NSString *result = nil;
    
    if ($equal(domain,NSPOSIXErrorDomain)) {
        // Interpret POSIX errors via strerror
        // (which unfortunately returns a description, not the name of the constant)
        const char *name = strerror((int)code);
        if (name) {
            result = [NSString stringWithCString: name encoding: NSASCIIStringEncoding];
            if ([result hasPrefix: @"Unknown error"])
                result = nil;
        }
    } 
#if !TARGET_OS_IPHONE || defined(__SEC_TYPES__)
    else if ($equal(domain,NSOSStatusErrorDomain)) {
        // If it's an OSStatus, check whether CarbonCore knows its name:
        NSError *osErr = [NSError errorWithDomain:NSOSStatusErrorDomain code:code userInfo:nil];
        result = [osErr localizedDescription];

#if MYERRORUTILS_USE_SECURITY_API
        if (!result) {
            result = (id) SecCopyErrorMessageString((OSStatus)code,NULL);
            if (result) {
                [NSMakeCollectable(result) autorelease];
                if ([result hasPrefix: @"OSStatus "])
                    result = nil; // just a generic message
            }
        }
#endif
    }
#endif
    
    if (!result) {
        // Look up errors in string files keyed by the domain name:
        NSString *table = [@"MYError_" stringByAppendingString: domain];
        result = [[NSBundle mainBundle] localizedStringForKey: codeStr value: @"?" table: table];
        if ([result isEqualToString: @"?"])
            result = nil;
    }
    
    codeStr = $sprintf(@"%@ %@", MYShortErrorDomainName(domain), codeStr);;
    return result ? $sprintf(@"%@ (%@)", result, codeStr) : codeStr;
}




@implementation NSError (MYUtils)

- (NSError*) my_errorByPrependingMessage: (NSString*)message
{
    if( message.length ) {
        NSDictionary *oldUserInfo = self.userInfo;
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        if( oldUserInfo )
            [userInfo addEntriesFromDictionary: oldUserInfo];
        NSString *desc = [oldUserInfo objectForKey: NSLocalizedDescriptionKey];
        if( desc )
            message = $sprintf(@"%@: %@", message, desc);
        [userInfo setObject: message forKey: NSLocalizedDescriptionKey];
        return [NSError errorWithDomain: self.domain
                                   code: self.code
                               userInfo: userInfo];
    } else
        return self;
}

- (NSString*) my_nameOfCode {
    return MYErrorName(self.domain, self.code);
}

@end


TestCase(MYErrorUtils) {
    CAssertEqual(printableOSType('abcd'), @"abcd");
    CAssertEqual(printableOSType('    '), @"    ");
    CAssertEqual(printableOSType(0x7e7e7e7e), @"~~~~");
    CAssertEqual(printableOSType(0x7e7F7e7e), nil);
    CAssertEqual(printableOSType(0x7e0D7e7e), nil);
    CAssertEqual(printableOSType(0), nil);
    CAssertEqual(printableOSType((OSType)-123456), nil);

    CAssertEqual(MYErrorName(nil,0),      nil);
    CAssertEqual(MYErrorName(nil,12345),  @"12345");
    CAssertEqual(MYErrorName(nil,1),      @"1");
    CAssertEqual(MYErrorName(nil,-1),     @"-1");
    CAssertEqual(MYErrorName(nil,12345),  @"12345");
    CAssertEqual(MYErrorName(nil,-12345), @"-12345");
    CAssertEqual(MYErrorName(nil,2147549184u), @"2147549184");  // that's 0x80010000
    
    CAssertEqual(MYErrorName(@"foobar",0), nil);
    CAssertEqual(MYErrorName(@"foobar",'fmt?'), @"foobar fmt?");
    CAssertEqual(MYErrorName(@"foobar",1), @"foobar 1");
    CAssertEqual(MYErrorName(@"FoobarErrorDomain",-1), @"Foobar -1");
    CAssertEqual(MYErrorName(@"NSFoobarErrorDomain",12345), @"Foobar 12345");

    NSError *err;
    err = [NSError errorWithDomain: NSPOSIXErrorDomain code: EPERM userInfo: nil];
    CAssertEqual(err.my_nameOfCode, @"Operation not permitted (POSIX 1)");
    err = [NSError errorWithDomain: NSPOSIXErrorDomain code: 12345 userInfo: nil];
    CAssertEqual(err.my_nameOfCode, @"POSIX 12345");
    
#if !TARGET_OS_IPHONE
    err = [NSError errorWithDomain: NSOSStatusErrorDomain code: paramErr userInfo: nil];
    CAssertEqual(err.my_nameOfCode, @"paramErr (OSStatus -50)");
    err = [NSError errorWithDomain: NSOSStatusErrorDomain code: fnfErr userInfo: nil];
    CAssertEqual(err.my_nameOfCode, @"fnfErr (OSStatus -43)");
    err = [NSError errorWithDomain: NSOSStatusErrorDomain code: -25291 userInfo: nil];
    CAssertEqual(err.my_nameOfCode, @"errKCNotAvailable / errSecNotAvailable (OSStatus -25291)");
#if MYERRORUTILS_USE_SECURITY_API
    err = [NSError errorWithDomain: NSOSStatusErrorDomain code: -25260 userInfo: nil];
    CAssertEqual(err.my_nameOfCode, @"Passphrase is required for import/export. (OSStatus -25260)");
#endif
#endif
    err = [NSError errorWithDomain: NSOSStatusErrorDomain code: 12345 userInfo: nil];
    CAssertEqual(err.my_nameOfCode, @"OSStatus 12345");

    err = [NSError errorWithDomain: @"CSSMErrorDomain" code: 2147549184u userInfo: nil];
#if MYERRORUTILS_USE_SECURITY_API
    CAssertEqual(err.my_nameOfCode, @"CSSM_CSSM_BASE_ERROR (CSSM 2147549184)");
    // If that assertion fails, you probably need to add MYError_CSSMErrorDomain.strings to your target.
#else
    CAssertEqual(err.my_nameOfCode, @"CSSM 2147549184");
#endif
    err = [NSError errorWithDomain: (id)kCFErrorDomainCocoa code: 100 userInfo: nil];
    CAssertEqual(err.my_nameOfCode, @"Cocoa 100");
}
