/*
 * Licensed Materials - Property of IBM
 * (C) Copyright IBM Corp. 2006, 2013. All Rights Reserved.
 * US Government Users Restricted Rights - Use, duplication or
 * disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 */

#import "IMFLogger.h"
#import "OCLogger+Constants.h"

#define IMFLogTrace(message, ...) [[IMFLogger loggerForName:IMF_NAME] logTraceWithUserInfo:@{KEY_METADATA_METHOD : [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__], KEY_METADATA_LINE : @__LINE__, KEY_METADATA_FILE : [[NSString stringWithUTF8String:__FILE__] lastPathComponent], KEY_METADATA_SOURCE : SOURCE_OBJECTIVE_C } andMessages:message, ##__VA_ARGS__];

#define IMFLogDebug(message, ...) [[IMFLogger loggerForName:IMF_NAME] logDebugWithUserInfo:@{KEY_METADATA_METHOD : [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__], KEY_METADATA_LINE : @__LINE__, KEY_METADATA_FILE : [[NSString stringWithUTF8String:__FILE__] lastPathComponent], KEY_METADATA_SOURCE : SOURCE_OBJECTIVE_C } andMessages:message, ##__VA_ARGS__];

#define IMFLogInfo(message, ...) [[IMFLogger loggerForName:IMF_NAME] logInfoWithUserInfo:@{KEY_METADATA_METHOD : [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__], KEY_METADATA_LINE : @__LINE__, KEY_METADATA_FILE : [[NSString stringWithUTF8String:__FILE__] lastPathComponent], KEY_METADATA_SOURCE : SOURCE_OBJECTIVE_C } andMessages:message, ##__VA_ARGS__];

#define IMFLogWarn(message, ...) [[IMFLogger loggerForName:IMF_NAME] logWarnWithUserInfo:@{KEY_METADATA_METHOD : [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__], KEY_METADATA_LINE : @__LINE__, KEY_METADATA_FILE : [[NSString stringWithUTF8String:__FILE__] lastPathComponent], KEY_METADATA_SOURCE : SOURCE_OBJECTIVE_C } andMessages:message, ##__VA_ARGS__];

#define IMFLogError(message, ...) [[IMFLogger loggerForName:IMF_NAME] logErrorWithUserInfo:@{KEY_METADATA_METHOD : [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__], KEY_METADATA_LINE : @__LINE__, KEY_METADATA_FILE : [[NSString stringWithUTF8String:__FILE__] lastPathComponent], KEY_METADATA_SOURCE : SOURCE_OBJECTIVE_C, KEY_METADATA_STACKTRACE : [NSThread callStackSymbols] } andMessages:message, ##__VA_ARGS__];

#define IMFLogFatal(message, ...) [[IMFLogger loggerForName:IMF_NAME] logFatalWithUserInfo:@{KEY_METADATA_METHOD : [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__], KEY_METADATA_LINE : @__LINE__, KEY_METADATA_FILE : [[NSString stringWithUTF8String:__FILE__] lastPathComponent], KEY_METADATA_SOURCE : SOURCE_OBJECTIVE_C } andMessages:message, ##__VA_ARGS__];

#define IMFLogAnalytics(message, ...) [[IMFLogger loggerForName:IMF_NAME] logAnalyticsWithUserInfo:@{KEY_METADATA_METHOD : [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__], KEY_METADATA_LINE : @__LINE__, KEY_METADATA_FILE : [[NSString stringWithUTF8String:__FILE__] lastPathComponent], KEY_METADATA_SOURCE : SOURCE_OBJECTIVE_C } andMessages:message, ##__VA_ARGS__];


// Log with name

#define IMFLogTraceWithName(name, message, ...) [[IMFLogger loggerForName:name] logTraceWithUserInfo:@{KEY_METADATA_METHOD : [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__], KEY_METADATA_LINE : @__LINE__, KEY_METADATA_FILE : [[NSString stringWithUTF8String:__FILE__] lastPathComponent], KEY_METADATA_SOURCE : SOURCE_OBJECTIVE_C } andMessages:message, ##__VA_ARGS__];

#define IMFLogDebugWithName(name, message, ...) [[IMFLogger loggerForName:name] logDebugWithUserInfo:@{KEY_METADATA_METHOD : [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__], KEY_METADATA_LINE : @__LINE__, KEY_METADATA_FILE : [[NSString stringWithUTF8String:__FILE__] lastPathComponent], KEY_METADATA_SOURCE : SOURCE_OBJECTIVE_C } andMessages:message, ##__VA_ARGS__];

#define IMFLogInfoWithName(name, message, ...) [[IMFLogger loggerForName:name] logInfoWithUserInfo:@{KEY_METADATA_METHOD : [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__], KEY_METADATA_LINE : @__LINE__, KEY_METADATA_FILE : [[NSString stringWithUTF8String:__FILE__] lastPathComponent], KEY_METADATA_SOURCE : SOURCE_OBJECTIVE_C } andMessages:message, ##__VA_ARGS__];

#define IMFLogWarnWithName(name, message, ...) [[IMFLogger loggerForName:name] logWarnWithUserInfo:@{KEY_METADATA_METHOD : [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__], KEY_METADATA_LINE : @__LINE__, KEY_METADATA_FILE : [[NSString stringWithUTF8String:__FILE__] lastPathComponent], KEY_METADATA_SOURCE : SOURCE_OBJECTIVE_C } andMessages:message, ##__VA_ARGS__];

#define IMFLogErrorWithName(name, message, ...) [[IMFLogger loggerForName:name] logErrorWithUserInfo:@{KEY_METADATA_METHOD : [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__], KEY_METADATA_LINE : @__LINE__, KEY_METADATA_FILE : [[NSString stringWithUTF8String:__FILE__] lastPathComponent], KEY_METADATA_SOURCE : SOURCE_OBJECTIVE_C } andMessages:message, ##__VA_ARGS__];

#define IMFLogFatalWithName(name, message, ...) [[IMFLogger loggerForName:name] logFatalWithUserInfo:@{KEY_METADATA_METHOD : [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__], KEY_METADATA_LINE : @__LINE__, KEY_METADATA_FILE : [[NSString stringWithUTF8String:__FILE__] lastPathComponent], KEY_METADATA_SOURCE : SOURCE_OBJECTIVE_C } andMessages:message, ##__VA_ARGS__];
