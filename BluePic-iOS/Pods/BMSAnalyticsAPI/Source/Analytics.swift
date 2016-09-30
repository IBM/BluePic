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



// MARK: DeviceEvent

/**
    Set of device events that the `Analytics` class will listen for. Whenever an event of the specified type occurs, analytics data for that event will be recorded.

    - Note: Register DeviceEvents in the `Analytics.initialize()` method.
*/
public enum DeviceEvent {
    
    /// Records the duration of the app's lifecycle from when it enters the foreground to when it goes to the background.
    ///
    /// - Note: Only available for iOS apps. For watchOS apps, call the `recordApplicationDidBecomeActive()` and `recordApplicationWillResignActive()` methods in the appropriate `ExtensionDelegate` methods.
    case lifecycle
}



// MARK: - AnalyticsDelegate

// Connects the `Analytics` interface defined in BMSAnalyticsAPI with the implementation in BMSAnalytics.
public protocol AnalyticsDelegate {
    
    var userIdentity: String? { get set }
}



// MARK: - Analytics

/**
    Records analytics data and sends it to the Analytics server.
*/
public class Analytics {
    
    
    // MARK: Properties (API)
    
    /// Determines whether analytics logs will be persisted to file.
    public static var isEnabled: Bool = true
    
    /// Identifies the current application user.
    /// To reset the userId, set the value to nil.
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
    
    
    
#if swift(>=3.0)
    
    
    // MARK: Methods (API)
    
    /**
         Record analytics data.
         
         Analytics logs are added to the log file until the file size is greater than the `maxLogStoreSize` property. At this point, the first half of the stored logs will be deleted to make room for new log data.
         
         When ready, use the `send()` method to send the recorded data to the Analytics server.
         
         - parameter metadata:  The analytics data
     */
    public static func log(metadata: [String: Any], file: String = #file, function: String = #function, line: Int = #line) {
    
        Analytics.logger.analytics(metadata: metadata, file: file, function: function, line: line)
    }
    
    
#else
    
    
    // MARK: Methods (API)
    
    /**
        Record analytics data.

        Analytics logs are added to the log file until the file size is greater than the `maxLogStoreSize` property. At this point, the first half of the stored logs will be deleted to make room for new log data.

        When ready, use the `send()` method to send the recorded data to the Analytics server.

        - parameter metadata:  The analytics data
    */
    public static func log(metadata metadata: [String: AnyObject], file: String = #file, function: String = #function, line: Int = #line) {
        
        Analytics.logger.analytics(metadata: metadata, file: file, function: function, line: line)
    }
    
    
#endif

}
