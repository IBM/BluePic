/*
 * Licensed Materials - Property of IBM
 * (C) Copyright IBM Corp. 2006, 2013. All Rights Reserved.
 * US Government Users Restricted Rights - Use, duplication or
 * disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 */
 
#import <Foundation/Foundation.h>

/**
 An extension to IMFLogger. Has the ability to persistently store Analytics log data.
 
 Use this class to store Analytics data that can later be visualized in the Analytics console.
 */
@interface IMFAnalytics : NSObject

/**
 Provides an instance of the Analytics object
 @return Self
 */
+ (IMFAnalytics *) sharedInstance;

/**
 Starts automatic recording of application lifecycle events (meaning app startup time and session events) 
 
 This method is typically called in the didFinishLaunchingWithOptions method.
 */
- (void) startRecordingApplicationLifecycleEvents;

/**
 Stops automatic recording of application lifecycle events 
 */
- (void) stopRecordingApplicationLifecycleEvents;

/**
 Logs a message at the analytics level
 @param eventName Name of the event being logged
 */
- (void) logEvent:(NSString*)eventName;

/**
 Logs a message at the analytics level
 @param eventName Name of the event being logged
 @param metadata Dictionary containing metadata to append to the log output
 */
- (void) logEvent:(NSString*)eventName withMetadata:(NSDictionary*)metadata;

/**
 Sends the analytics log file when the log store exists and is not empty 
 
 If the send fails, the local store is preserved. If the send succeeds, the local store is deleted.
 */
- (void) sendPersistedLogs;

/**
 Sends the analytics log to a specified interval, in seconds. 
 
 By default, the logs will not be sent at an interval.
 @param intervalInSeconds Intervals, in seconds, at which analytics logs will be automatically sent
 */
- (void)startSendingPersistedLogsWithInterval: (NSTimeInterval) intervalInSeconds;

/**
 Stops the automatic sending of analytics data at an interval.
 */
- (void)stopSendingPersistedLogsOnInterval;

/**
 Turns the global setting for persisting of the analytics data.
 @param enabled Boolean that indicates whether the log data must be saved persistently.
 */
- (void) setEnabled: (BOOL) enabled;

/**
 Gets the current setting for determining if log data should be saved persistently.
 @return Boolean indicating whether the log data must be saved persistently.
 */
- (BOOL) isEnabled;

@end