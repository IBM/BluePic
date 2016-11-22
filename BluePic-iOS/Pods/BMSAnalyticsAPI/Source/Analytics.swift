/*
*     Copyright 2016 IBM Corp.
*     Licensed under the Apache License, Version 2.0 (the "License");
*     you may not use this file except in compliance with the License.
*     You may obtain a copy of the License at
*     http://www.apache.org/licenses/LICENSE-2.0
*     Unless required by applicable law or agreed to in writing, software
*     distributed under the License is distributed on an "AS IS" BASIS,
*     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*     See the License for the specific language governing permissions and
*     limitations under the License.
*/



// MARK: - Swift 3

#if swift(>=3.0)



// MARK: DeviceEvent

/**
    The set of device events that the `Analytics` class will listen for. Whenever an event of the specified type occurs, analytics data for that event will be recorded.

    - Note: Register DeviceEvents in `Analytics.initialize(appName:apiKey:hasUserContext:deviceEvents:)`.
*/
public enum DeviceEvent {
    
    /// Records the duration of the app's lifecycle from when it enters the foreground to when it goes to the background.
    ///
    /// - Note: Only available for iOS apps. For watchOS apps, call the `Analytics.recordApplicationDidBecomeActive()` and `Analytics.recordApplicationWillResignActive()` methods in the app's `ExtensionDelegate` methods of the same name.
    case lifecycle
    
    /// Records metadata for network requests sent by the Bluemix Mobile Services SDKs (BMSCore, BMSAnalytics, BMSPush, BMSSecurity, etc.).
    /// To have metadata recorded for your own custom network requests and sent to the Mobile Analytics service, create your requests with `BMSURLSession` from the `BMSCore` framework.
    case network
}



// MARK: - AnalyticsDelegate

// Connects the `Analytics` interface defined in BMSAnalyticsAPI with the implementation in BMSAnalytics.
public protocol AnalyticsDelegate {
    
    var userIdentity: String? { get set }
}



// MARK: - Analytics

/**
    Records analytics data and sends it to the [Mobile Analytics service](https://console.ng.bluemix.net/docs/services/mobileanalytics/mobileanalytics_overview.html).

    To subscribe to automated analytics recording, pass the `DeviceEvent` options that you want recorded in `initialize(appName:apiKey:hasUserContext:deviceEvents:)`.

    Custom events can be recorded with `log(metadata:)`. You can also define the current application user with `userIdentity` using, for example, the user's login information.

    When you are ready to send all of the recorded data to the Mobile Analytics service, use `send(completionHandler:)`.
*/
public class Analytics {
    
    
    // MARK: Properties
    
    /// Determines whether analytics data will be recorded.
    public static var isEnabled: Bool = true
    
    /// Identifies the current application user.
    /// To reset the `userIdentity`, set the value to nil.
    public static var userIdentity: String? {
        didSet {
            Analytics.delegate?.userIdentity = userIdentity
        }
    }
    
    
    
    // MARK: Properties (internal)
    
    // Handles all internal implementation of the Analytics class
    // Public access required by BMSAnalytics framework, which is required to initialize this property
    public static var delegate: AnalyticsDelegate?
    
	public static let logger = Logger.logger(name: Logger.bmsLoggerPrefix + "analytics")
    
    
    
    // MARK: Methods
    
    /**
        Record analytics data.

        Analytics logs are added to the log file until the file size is greater than `Logger.maxLogStoreSize`. At this point, the first half of the stored logs will be deleted to make room for new log data.

        When ready, use `send(completionHandler:)` to send the recorded data to the Mobile Analytics service.

        - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.

        - parameter metadata:  The analytics data
    */
    public static func log(metadata: [String: Any], file: String = #file, function: String = #function, line: Int = #line) {
        
        Analytics.logger.analytics(metadata: metadata, file: file, function: function, line: line)
    }

}
    
    
    
    
    
/**************************************************************************************************/





// MARK: - Swift 2
    
#else
    
    
    
// MARK: DeviceEvent

/**
    The set of device events that the `Analytics` class will listen for. Whenever an event of the specified type occurs, analytics data for that event will be recorded.

    - Note: Register DeviceEvents in `Analytics.initialize(appName:apiKey:hasUserContext:deviceEvents:)`.
*/
public enum DeviceEvent {
    
    /// Records the duration of the app's lifecycle from when it enters the foreground to when it goes to the background.
    ///
    /// - Note: Only available for iOS apps. For watchOS apps, call the `Analytics.recordApplicationDidBecomeActive()` and `Analytics.recordApplicationWillResignActive()` methods in the app's `ExtensionDelegate` methods of the same name.
    case lifecycle
    
    /// Records metadata for network requests sent by the Bluemix Mobile Services SDKs (BMSCore, BMSAnalytics, BMSPush, BMSSecurity, etc.).
    /// To have metadata recorded for your own custom network requests and sent to the Mobile Analytics service, create your requests with `BMSURLSession` from the `BMSCore` framework.
    case network
}



// MARK: - AnalyticsDelegate

// Connects the `Analytics` interface defined in BMSAnalyticsAPI with the implementation in BMSAnalytics.
public protocol AnalyticsDelegate {
    
    var userIdentity: String? { get set }
}



// MARK: - Analytics

/**
    Records analytics data and sends it to the [Mobile Analytics service](https://console.ng.bluemix.net/docs/services/mobileanalytics/mobileanalytics_overview.html).

    To subscribe to automated analytics recording, pass the `DeviceEvent` options that you want recorded in `initialize(appName:apiKey:hasUserContext:deviceEvents:)`.

    Custom events can be recorded with `log(metadata:)`. You can also define the current application user with `userIdentity` using, for example, the user's login information.

    When you are ready to send all of the recorded data to the Mobile Analytics service, use `send(completionHandler:)`.
*/
public class Analytics {
    
    
    // MARK: Properties
    
    /// Determines whether analytics data will be recorded.
    public static var isEnabled: Bool = true
    
    /// Identifies the current application user.
    /// To reset the `userIdentity`, set the value to nil.
    public static var userIdentity: String? {
        didSet {
            Analytics.delegate?.userIdentity = userIdentity
        }
    }
    
    
    
    // MARK: Properties (internal)
    
    // Handles all internal implementation of the Analytics class
    // Public access required by BMSAnalytics framework, which is required to initialize this property
    public static var delegate: AnalyticsDelegate?
    
    public static let logger = Logger.logger(name: Logger.bmsLoggerPrefix + "analytics")
    
    
    
    // MARK: Methods
    
    /**
        Record analytics data.

        Analytics logs are added to the log file until the file size is greater than `Logger.maxLogStoreSize`. At this point, the first half of the stored logs will be deleted to make room for new log data.

        When ready, use `send(completionHandler:)` to send the recorded data to the Mobile Analytics service.

        - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.

        - parameter metadata:  The analytics data
     */
    public static func log(metadata metadata: [String: AnyObject], file: String = #file, function: String = #function, line: Int = #line) {
    
        Analytics.logger.analytics(metadata: metadata, file: file, function: function, line: line)
    }
    
}



#endif
