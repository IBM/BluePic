//
//  Logging.h
//  MYUtilities
//
//  Created by Jens Alfke on 1/5/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
    This is a configurable console-logging facility that lets logging be turned on and off
    independently for various subsystems or areas of the code. It's used similarly to NSLog:
        Log(@"the value of foo is %@", foo);
    You can associate a log message with a particular subsystem or tag by calling LogTo:
        LogTo(FooVerbose, @"the value of foo is %@", foo);
 
    By default, logging is compiled in but disabled at runtime.

    To enable logging in general, set the user default 'Log' to 'YES'. You can do this persistently using the 'defaults write' command; but it's very convenient during development to use the Arguments tab in the Xcode Executable Info panel. Just add a new entry to the arguments list, of the form "-Log YES". Now you can check and uncheck that as desired; the change will take effect when relaunching.

    Once logging is enabled, you can turn on and off individual categories of logs. For any category "Something", to enable output from calls of the form LogTo(Something, @"..."), set the user default 'LogSomething' to 'YES', just as above.
 
    To disable logging code from being compiled at all, define the preprocessor symbol
    MY_DISABLE_LOGGING (in your prefix header or target build settings.)

    Warn() is a related function that _always_ logs, and prefixes the message with "WARNING***".
        Warn(@"Reactor coolant system has failed");
 
    Note: Logging is still present in release/nondebug builds. I've found this to be very useful in tracking down problems in the field, since I can tell a user how to turn on logging, and then get detailed logs back.
*/ 


NSString* LOC( NSString *key );     // Localized string lookup


#define Warn Warn


#ifndef MY_DISABLE_LOGGING


#define Log(FMT,ARGS...) do{if(__builtin_expect(_gShouldLog,0)) {\
                            _Log(FMT,##ARGS);\
                         } }while(0)
#define LogTo(DOMAIN,FMT,ARGS...) do{if(__builtin_expect(_gShouldLog,0)) {\
                                    if(_WillLogTo(@""#DOMAIN)) _LogTo(@""#DOMAIN,FMT,##ARGS);\
                                  } }while(0)


void AlwaysLog( NSString *msg, ... ) __attribute__((format(__NSString__, 1, 2)));
BOOL EnableLog( BOOL enable );
#define EnableLogTo( DOMAIN, VALUE )  _EnableLogTo(@""#DOMAIN, VALUE)
#define WillLog()  _WillLogTo(nil)
#define WillLogTo( DOMAIN )  _WillLogTo(@""#DOMAIN)

/** Setting this to YES causes Warn() to raise an exception. Useful in unit tests. */
extern BOOL gMYWarnRaisesException;

// internals; don't use directly
extern int _gShouldLog;
void _Log( NSString *msg, ... ) __attribute__((format(__NSString__, 1, 2)));
void _LogTo( NSString *domain, NSString *msg, ... ) __attribute__((format(__NSString__, 2, 3)));
BOOL _WillLogTo( NSString *domain );
BOOL _EnableLogTo( NSString *domain, BOOL enable );


#else // MY_DISABLE_LOGGING

#define Log(FMT,ARGS...) do{ }while(0)
#define LogTo(DOMAIN,FMT,ARGS...) do{ }while(0)
#define AlwaysLog NSLog
#define EnableLogTo( DOMAIN, VALUE ) do{ }while(0)
#define WillLog() NO
#define WillLogTo( DOMAIN ) NO

#endif // MY_DISABLE_LOGGING

void Warn( NSString *msg, ... ) __attribute__((format(__NSString__, 1, 2)));
