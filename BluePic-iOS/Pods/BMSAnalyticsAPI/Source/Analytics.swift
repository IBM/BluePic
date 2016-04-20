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
    Set of device events that the `Analytics` class will listen for. Whenever an event of the specified type occurs, analytics data for that event get recorded.

    - Note: Register DeviceEvents in the `Analytics.initializeWithAppName()` method
*/
public enum DeviceEvent {
    
    /// Records the duration of the app's lifecycle from when it enters the foreground to when it goes to the background.
    /// - Note: Only available for iOS apps. For watchOS apps, manually call the `recordApplicationDidBecomeActive()` and `recordApplicationWillResignActive()` methods in the appropriate `ExtensionDelegate` methods.
    case LIFECYCLE
}



// MARK: - AnalyticsDelegate

// This protocol is implemented in the BMSAnalytics framework
public protocol AnalyticsDelegate {
    
    var userIdentity: String? { get set }
}



// MARK: - Analytics

/**
    `Analytics` provides a means of capturing analytics data and sending the data to the mobile analytics service.
*/
public class Analytics {
    
    
    // MARK: Properties (API)
    
    /// Determines whether analytics logs will be persisted to file.
    public static var enabled: Bool = true
    
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
    
	public static let logger = Logger.logger(forName: Logger.bmsLoggerPrefix + "analytics")
    
    
    
    // MARK: Methods (API)
    
    /**
         Write analytics data to file.
         
         Similar to the `Logger` class logging methods, old logs will be removed if the file size exceeds the `Logger.maxLogStoreSize` property.
         
         When ready, use the `Analytics.send()` method to send the logs to the Bluemix server.
         
         - parameter metadata:  The analytics data
     */
    public static func log(metadata: [String: AnyObject], file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
    
        Analytics.logger.analytics(metadata, file: file, function: function, line: line)
    }
    
}
