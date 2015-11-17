/*
 * Licensed Materials - Property of IBM
 * (C) Copyright IBM Corp. 2006, 2013. All Rights Reserved.
 * US Government Users Restricted Rights - Use, duplication or
 * disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 */

#import <Foundation/Foundation.h>

/** 
 Used to specify the desired log level.
 */
typedef NS_ENUM(NSInteger, IMFLogLevel) {
    
    /** Trace level */
    IMFLogLevelTrace = 600,
    
    /** Debug level */
    IMFLogLevelDebug = 500,
    
    /** Log level */
    IMFLogLevelLog = 400,
    
    /** Info level */
    IMFLogLevelInfo = 300,
    
    /** Warn level */
    IMFLogLevelWarn = 200,
    
    /** Error level */
    IMFLogLevelError = 100,
    
    /** Fatal level */
    IMFLogLevelFatal = 50,
    
    /** Analytics level */
    IMFLogLevelAnalytics = 25
};

/**
 <em>IMFLogger</em> is a drop-in replacement for nslog.  It is a feature-rich
 log class, with standard logger capabilities like levels, filters,
 and well-structured output formatting.  <em>IMFLogger</em> also has the ability
 to attach additional metadata (by passing an <em>NSDictionary</em> object) to
 log output.
 
 <em>IMFLogger</em> can also capture log output to local application storage
 within a storage size threshold with log rollover so that the captured
 logs can be sent to a server for debugging production-time problems
 occurring in the field.
 
 <em>IMFLogger</em> has the capability to capture uncaught exceptions, which
 appear to the end-user as a crashed application. Call the method
 <em>captureUncaughtExceptions</em> to enable this capture.
 
 Some parts of IMF framework code have already been instrumented with
 <em>IMFLogger</em> API calls.
 
 As a convenience, developers may use <em>IMFLogger</em> macros.  These macros
 automatically record the class name, file name, method, and line number
 of the IMFLogger function call in the metadata of the log record.
 
 The macros are as follows, where all parameters are of type NSString:
 
 - IMFLogTrace(message, ...)
 - IMFLogDebug(message, ...)
 - IMFLogInfo(message, ...)
 - IMFLogWarn(message, ...)
 - IMFLogError(message, ...)
 - IMFLogFatal(message, ...)
 - IMFLogAnalytics(message, ...)
 
 - IMFLogTraceWithName(name, message, ...)
 - IMFLogDebugWithName(name, message, ...)
 - IMFLogInfoWithName(name, message, ...)
 - IMFLogWarnWithName(name, message, ...)
 - IMFLogErrorWithName(name, message, ...)
 - IMFLogFatalWithName(name, message, ...)
 */
@interface IMFLogger : NSObject

#pragma mark Instance Methods

/** 
 Logs a message at the trace level
 @param message Message to be logged
 @param ... Values to be replaced in the message parameter
 */
-(void) logTraceWithMessages: (NSString*) message, ...;

/** 
 Logs a message at the debug level
 @param message Message to be logged
 @param ... Values to be replaced in the message parameter
 */
-(void) logDebugWithMessages: (NSString*) message, ...;

/** 
 Logs a message at the info level
 @param message Message to be logged
 @param ... Values to be replaced in the message parameter
 */
-(void) logInfoWithMessages: (NSString*) message, ...;

/** 
 Logs a message at the warning level
 @param message Message to be logged
 @param ... Values to be replaced in the message parameter
 */
-(void) logWarnWithMessages: (NSString*) message, ...;

/** 
 Logs a message at the error level
 @param message Message to be logged
 @param ... Values to be replaced in the message parameter
 */
-(void) logErrorWithMessages: (NSString*) message, ...;

/** 
 Logs a message at the fatal level
 @param message Message to be logged
 @param ... Values to be replaced in the message parameter
 */
-(void) logFatalWithMessages: (NSString*) message, ...;

/** 
 Logs a message at the trace level
 @param userInfo <em>NSDictionary</em> containing user information to append to the log output
 @param message Message to be logged
 @param ... Values to be replaced in the message parameter
 */
-(void) logTraceWithUserInfo:(NSDictionary*) userInfo andMessages: (NSString*) message, ...;

/** 
 Logs a message at the debug level
 @param userInfo <em>NSDictionary</em> containing user information to append to the log output
 @param message Message to be logged
 @param ... Values to be replaced in the message parameter
 */
-(void) logDebugWithUserInfo:(NSDictionary*) userInfo andMessages: (NSString*) message, ...;

/** 
 Logs a message at the info level
 @param userInfo <em>NSDictionary</em> containing user info to append to the log output
 @param message Message to be logged
 @param ... Values to be replaced in the message parameter
 */
-(void) logInfoWithUserInfo:(NSDictionary*) userInfo andMessages: (NSString*) message, ...;

/** 
 This method logs a message at the warn level
 @param userInfo <em>NSDictionary</em> containing user information to append to the log output
 @param message Message to be logged
 @param ... Values to be replaced in the message parameter
 */
-(void) logWarnWithUserInfo:(NSDictionary*) userInfo andMessages: (NSString*) message, ...;

/** 
 Logs a message at the error level.
 @param userInfo <em>NSDictionary</em> containing user information to append to the log output
 @param message Message to be logged.
 @param ... Values to be replaced in the message parameter.
 */
-(void) logErrorWithUserInfo:(NSDictionary*) userInfo andMessages: (NSString*) message, ...;

/** 
 Logs a message at the fatal level.
 @param userInfo <em>NSDictionary</em> containing user information to append to the log output.
 @param message Message to be logged
 @param ... Values to be replaced in the message parameter
 */
-(void) logFatalWithUserInfo:(NSDictionary*) userInfo andMessages: (NSString*) message, ...;

/** 
 Logs a message at the analytics level.
 @param userInfo <em>NSDictionary</em> containing user information to append to the log output
 @param message Message to be logged
 @param ... Values to be replaced in the message parameter
 */
-(void) logAnalyticsWithUserInfo:(NSDictionary*) userInfo andMessages: (NSString*) message, ...;

#pragma mark Getters and Setters

/** 
 Sets the name for the <em>IMFLogger</em> instance
 @param name <em>IMFLogger</em> instance
 */
-(void) setName:(NSString*) name;

/** 
 Gets for the name of the <em>IMFLogger</em> instance
 @return Name of the <em>IMFLogger</em> instance
 */
-(NSString*) name;

#pragma mark Static methods

/** 
 Gets or creates an instance of this logger. 
 <p>
 If an instance exists for the name parameter, that instance is returned.
 @param name String denoting name that must be printed with log messages. The value is passed through to <em>NSLog</em> and recorded when log capture is enabled.
 @return <em>IMFLogger</em> instance used to invoke log calls
 */
+(IMFLogger*) loggerForName: (NSString*) name;

/** 
 Sends the log file when the log store exists and is not empty.  
 <p>
 If the send fails, the local store is preserved.  If the send succeeds, the local store is deleted.
 */
+(void) send;

/** 
 Gets the current setting for determining if log data should be saved persistently
 @return Boolean flag indicating whether the log data must be saved persistently
 */
+(BOOL) getCapture;

/** 
 Global setting: turn on or off the persisting of the log data that is passed to the log methods of this class
 @param flag Boolean used to indicate whether the log data must be saved persistently
 */
+(void) setCapture: (BOOL) flag;

/** 
 Retrieves the filters that are used to determine which log messages are persisted
 @return Dictionary defining the logging filters
 */
+(NSDictionary*) getFilters;

/** 
 Sets the filters that are used to determine which log messages are persisted. 
 <p>
 Each key defines a name and each value defines a logging level.
 @param filters Dictionary containing the name and logging level key value pairs that are used to filter persisted logs
*/
+(void) setFilters: (NSDictionary*) filters;

/** 
 Gets the current setting for the maximum storage size threshold
 @return Integer indicating the maximum storage size threshold
 */
+(int) getMaxStoreSize;

/** 
 Sets the maximum size of the local persistent storage for queuing log data. 
 <p>
 When the maximum storage size is reached, no more data is queued. This content of the storage is sent to a server.
 @param bytes Integer defining the maximum size of the store in bytes. The minimum is 10,000 bytes.
 */
+(void) setMaxStoreSize: (int) bytes;

/** 
 Gets the currently configured <em>IMFLogLevel</em> and returns <em>IMFLogLevel</em>
 @return <em>IMFLogLevel</em> for the current log level
 */
+(IMFLogLevel) getLogLevel;

/** 
 Sets the level from which log messages must be saved and printed. 
 <p>
 For example, passing <em>IMFLogLevel.IMFLogger_INFO</em> logs <em>INFO</em>, <em>WARN</em>, and <em>ERROR</em>.
 @param level IMFLogLevel The valid values of this input parameter are <em>IMFLogger_TRACE, IMFLogger_DEBUG, IMFLogger_LOG, IMFLogger_INFO, IMFLogger_WARN, and IMFLogger_ERROR</em>.
 */
+(void) setLogLevel: (IMFLogLevel) level;

/** 
 Indicates that an uncaught exception was detected. 
 <p>
 The indicator is cleared on successful send.
 @return Boolean that indicates an uncaught exception was detected (true) or not (false)
 */
+(BOOL) uncaughtExceptionDetected;

/**
 Enables <em>IMFLogger</em> to capture all uncaught exceptions.
 This method does not override, but works in conjunction with,
 previous implementations of <em>NSSetUncaughtExceptionHandler()</em>.
 */
+(void) captureUncaughtExceptions;

/**
 Logs a message at a specific <em>IMFLogLevel</em> with string replacement using arguments passed. 
 <p>
 This method also attaches a dictionary of user information to the log message that is available when logs are persisted and sent to the server.
  @param level <em>IMFLogLevel</em> Log level used
  @param message String Message logged
  @param arguments va_list Arguments used for string replacements in the message parameter
  @param userInfo NSDictionary Additional data appended to the log message
 */
-(void) logWithLevel:(IMFLogLevel)level message:(NSString*) message args:(va_list) arguments userInfo:(NSDictionary*) userInfo;

@end
