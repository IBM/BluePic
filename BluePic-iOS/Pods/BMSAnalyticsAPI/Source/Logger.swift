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



// MARK: LogLevel

/**
    The severity of the log message.

     When setting `Logger.logLevelFilter`, the LogLevels, ordered from most restrictive to least, are: `none`, `analytics`, `fatal`, `error`, `warn`, `info`, and `debug`.
     
     - Note: Set `Logger.logLevelFilter` to `.none` to prohibit logs from being recorded.
*/
public enum LogLevel: Int {
    
    /// Used to turn off all logging, including analytics data.
    case none
    
    /// Only logs analytics data. `Logger` will record nothing.
    case analytics
    
    /// Indicates that the application crashed or entered a corrupt state.
    case fatal
    
    /// An unintended failure.
    case error
    
    /// A warning that may or may not be an actual issue.
    case warn
    
    /// Any useful information that is not considered problematic.
    case info
    
    /// Fine-level detail used for debugging purposes.
    case debug
    
    
    /// The string representation of the log level.
    public var asString: String {
        get {
            switch self {
            case .none:
                return "NONE"
            case .analytics:
                return "ANALYTICS"
            case .fatal:
                return "FATAL"
            case .error:
                return "ERROR"
            case .warn:
                return "WARN"
            case .info:
                return "INFO"
            case .debug:
                return "DEBUG"
            }
        }
    }
}



// MARK: - LoggerDelegate

// Contains functionality to store logs locally on the device and send them to the Mobile Analytics service.
// This protocol is implemented in the BMSAnalytics framework.
public protocol LoggerDelegate {
    
    var isUncaughtExceptionDetected: Bool { get set }
    
    func logToFile(message logMessage: String, level: LogLevel, loggerName: String, calledFile: String, calledFunction: String, calledLineNumber: Int, additionalMetadata: [String: Any]?)
}



// MARK: - Logger

/**
    A logging framework that can print messages to the console, store them locally on the device, and send them to the [Mobile Analytics service](https://console.ng.bluemix.net/docs/services/mobileanalytics/mobileanalytics_overview.html). With each log message, additional information is gathered such as the file, function, and line where the log was created, as well as the severity of the message.

    Multiple `Logger` instances can be created with different names using `logger(name:)`.

    When logging, choose the log method that matches the severity of the message. For example, use `debug(message:)` for fine-detail information and `error(message:)` for unintended failures. To limit which logs get printed to the console and stored on the device, set the `logLevelFilter` property.

    To enable logs to be stored locally on the device, set `isLogStorageEnabled` to `true`. Logs are added to the log file until the file size is greater than the `maxLogStoreSize`. At this point, the first half of the stored logs will be deleted to make room for new log data.

    To send logs to the Mobile Analytics service, use `send(completionHandler:)`. When the log data is successfully uploaded, the logs will be deleted from local storage.

    - Note: The `Logger` class sets an uncaught exception handler to log application crashes. If you wish to set your own exception handler, do so **before** calling `logger(name:)`, or the `Logger` exception handler will be overwritten.
*/
public class Logger {
    
    
    // MARK: Properties
    
    /// The name that identifies this `Logger` instance.
    public let name: String
    
    /// Logs below this severity level will be ignored, so they will not be recorded or printed to the console.
    /// For example, setting the value to `.warn` will record fatal, error, and warn logs, but not info or debug logs.
    ///
    /// The default value is `LogLevel.debug`.
    ///
    /// Set the value to `LogLevel.none` to turn off all logging.
    public static var logLevelFilter: LogLevel = LogLevel.debug
    
    /// If set to `true`, debug logs from Bluemix Mobile Services frameworks will be displayed on the console.
    /// This is useful if you need to debug an issue that you believe is related to Bluemix Mobile Services.
    public static var isInternalDebugLoggingEnabled: Bool = false
    
    /// Determines whether logs get stored locally on the device.
    /// Must be set to `true` to be able to later send logs to the Mobile Analytics service.
    public static var isLogStorageEnabled: Bool = false
    
    /// The maximum file size (in bytes) for log storage.
    /// Logs from `Logger` and logs from `Analytics` are stored in separate files, both of which are limited by `maxLogStoreSize`.
    public static var maxLogStoreSize: UInt64 = 100000
    
    /// `True` if the app crashed recently due to an uncaught exception.
    /// `BMSAnalytics` automatically records uncaught exceptions, so there is no need to change the value of this property manually.
    /// It will be set back to `false` after analytics logs are sent to the server with `Analytics.send(completionHandler:)`.
    public static var isUncaughtExceptionDetected: Bool {
        get {
            return Logger.delegate?.isUncaughtExceptionDetected ?? false
        }
        set {
            Logger.delegate?.isUncaughtExceptionDetected = newValue
        }
    }
    
    
    
    // MARK: Properties (internal)
    
    // Used to persist all logs to the device's file system and send logs to the Mobile Analytics service.
    // Public access required by BMSAnalytics framework, which is required to initialize this property.
    public static var delegate: LoggerDelegate?
    
    // Each logger instance is distinguished only by its "name" property.
    internal static var loggerInstances: [String: Logger] = [:]
    
    // Prefix for all internal logger names.
    public static let bmsLoggerPrefix = "bmssdk."
    
    
    
    // MARK: Methods
    
    /**
        Creates a Logger instance that will be identified by the supplied name.
        If a Logger instance with that name was already created, the existing instance will be returned.

        - parameter name: The name that identifies this Logger instance.

        - returns: A Logger instance.
    */
	public static func logger(name identifier: String) -> Logger {
        
        if let existingLogger = Logger.loggerInstances[identifier] {
            return existingLogger
        }
        else {
            let newLogger = Logger(name: identifier)
            Logger.loggerInstances[identifier] = newLogger
            
            return newLogger
        }
    }
    
    private init(name: String) {
        self.name = name
    }
    
    
    /**
        Log at the debug `LogLevel`.
     
        - parameter message: The message to log.
        
        - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.
    */
    public func debug(message: String, file: String = #file, function: String = #function, line: Int = #line) {
        
        log(message: message, level: LogLevel.debug, calledFile: file, calledFunction: function, calledLineNumber: line)
    }
    
    /**
         Log at the info `LogLevel`.
         
         - parameter message: The message to log.
         
         - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.
     */
    public func info(message: String, file: String = #file, function: String = #function, line: Int = #line) {
        
        log(message: message, level: LogLevel.info, calledFile: file, calledFunction: function, calledLineNumber: line)
    }
    
    /**
         Log at the warn `LogLevel`.
         
         - parameter message: The message to log.
         
         - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.
     */
    public func warn(message: String, file: String = #file, function: String = #function, line: Int = #line) {
        
        log(message: message, level: LogLevel.warn, calledFile: file, calledFunction: function, calledLineNumber: line)
    }
    
    /**
         Log at the error `LogLevel`.
     
         - parameter message: The message to log.
         
         - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.
     */
    public func error(message: String, file: String = #file, function: String = #function, line: Int = #line) {
        
        log(message: message, level: LogLevel.error, calledFile: file, calledFunction: function, calledLineNumber: line)
    }
    
    /**
         Log at the fatal `LogLevel`.
         
         - parameter message: The message to log.
         
         - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.
     */
    public func fatal(message: String, file: String = #file, function: String = #function, line: Int = #line) {
        
        log(message: message, level: LogLevel.fatal, calledFile: file, calledFunction: function, calledLineNumber: line)
    }
    
    // Equivalent to the other log methods, but this method accepts data as JSON rather than a string.
    internal func analytics(metadata: [String: Any], file: String = #file, function: String = #function, line: Int = #line) {
        
        log(message: "", level: LogLevel.analytics, calledFile: file, calledFunction: function, calledLineNumber: line, additionalMetadata: metadata)
    }
    
    
    
    // MARK: Methods (internal)
    
    // This is the master function that handles all of the logging, including level checking, printing to console, and writing to file.
    // All other log functions below this one are helpers for this function.
    internal func log(message logMessage: String, level: LogLevel, calledFile: String, calledFunction: String, calledLineNumber: Int, additionalMetadata: [String: Any]? = nil) {
        
        // The level must exceed the Logger.logLevelFilter, or we do nothing. Lower integer values for the level correspond to higher severity.
        guard level.rawValue <= Logger.logLevelFilter.rawValue else {
            return
        }
        
        if self.name.hasPrefix(Logger.bmsLoggerPrefix) && !Logger.isInternalDebugLoggingEnabled && level == LogLevel.debug {
            // Don't show our internal logs in the console.
        }
        else {
            // Print to console
            Logger.printLog(message: logMessage, loggerName: self.name, level: level, calledFunction: calledFunction, calledFile: calledFile, calledLineNumber: calledLineNumber)
        }
        
        Logger.delegate?.logToFile(message: logMessage, level: level, loggerName: self.name, calledFile: calledFile, calledFunction: calledFunction, calledLineNumber: calledLineNumber, additionalMetadata: additionalMetadata)
    }
    
    
    // Format: [DEBUG] [bmssdk.logger] logMessage in Logger.swift:234 :: "Some random message".
    // Public access required by BMSAnalytics framework.
    public static func printLog(message logMessage: String, loggerName: String, level: LogLevel, calledFunction: String, calledFile: String, calledLineNumber: Int) {
        
        // Suppress console log output for apps that are being released to the App Store
        #if !RELEASE_BUILD
            if level != LogLevel.analytics {
                print("[\(level.asString)] [\(loggerName)] \(calledFunction) in \(calledFile):\(calledLineNumber) :: \(logMessage)")
            }
        #endif
    }
}
    
    
    
    
    
/**************************************************************************************************/





// MARK: - Swift 2
    
#else



// MARK: LogLevel

/**
    The severity of the log message.

    When setting `Logger.logLevelFilter`, the LogLevels, ordered from most restrictive to least, are: `none`, `analytics`, `fatal`, `error`, `warn`, `info`, and `debug`.

    - Note: Set `Logger.logLevelFilter` to `.none` to prohibit logs from being recorded.
*/
public enum LogLevel: Int {
    
    
    /// Used to turn off all logging, including analytics data.
    case none
    
    /// Only logs analytics data. `Logger` will record nothing.
    case analytics
    
    /// Indicates that the application crashed or entered a corrupt state.
    case fatal
    
    /// An unintended failure.
    case error
    
    /// A warning that may or may not be an actual issue.
    case warn
    
    /// Any useful information that is not considered problematic.
    case info
    
    /// Fine-level detail used for debugging purposes.
    case debug
    
    
    /// The string representation of the log level.
    public var asString: String {
        get {
            switch self {
            case .none:
                return "NONE"
            case .analytics:
                return "ANALYTICS"
            case .fatal:
                return "FATAL"
            case .error:
                return "ERROR"
            case .warn:
                return "WARN"
            case .info:
                return "INFO"
            case .debug:
                return "DEBUG"
            }
        }
    }
}



// MARK: - LoggerDelegate

// Contains functionality to store logs locally on the device and send them to the Mobile Analytics service.
// This protocol is implemented in the BMSAnalytics framework.
public protocol LoggerDelegate {
    
    var isUncaughtExceptionDetected: Bool { get set }
    
    func logToFile(message logMessage: String, level: LogLevel, loggerName: String, calledFile: String, calledFunction: String, calledLineNumber: Int, additionalMetadata: [String: AnyObject]?)
}



// MARK: - Logger

/**
    A logging framework that can print messages to the console, store them locally on the device, and send them to the [Mobile Analytics service](https://console.ng.bluemix.net/docs/services/mobileanalytics/mobileanalytics_overview.html). With each log message, additional information is gathered such as the file, function, and line where the log was created, as well as the severity of the message.

    Multiple `Logger` instances can be created with different names using `logger(name:)`.

    When logging, choose the log method that matches the severity of the message. For example, use `debug(message:)` for fine-detail information and `error(message:)` for unintended failures. To limit which logs get printed to the console and stored on the device, set the `logLevelFilter` property.

    To enable logs to be stored locally on the device, set `isLogStorageEnabled` to `true`. Logs are added to the log file until the file size is greater than the `maxLogStoreSize`. At this point, the first half of the stored logs will be deleted to make room for new log data.

    To send logs to the Mobile Analytics service, use `send(completionHandler:)`. When the log data is successfully uploaded, the logs will be deleted from local storage.

    - Note: The `Logger` class sets an uncaught exception handler to log application crashes. If you wish to set your own exception handler, do so **before** calling `logger(name:)`, or the `Logger` exception handler will be overwritten.
*/
public class Logger {
    
    
    // MARK: Properties
    
    /// The name that identifies this `Logger` instance.
    public let name: String
    
    /// Logs below this severity level will be ignored, so they will not be recorded or printed to the console.
    /// For example, setting the value to `.warn` will record fatal, error, and warn logs, but not info or debug logs.
    ///
    /// The default value is `LogLevel.debug`.
    ///
    /// Set the value to `LogLevel.none` to turn off all logging.
    public static var logLevelFilter: LogLevel = LogLevel.debug
    
    /// If set to `true`, debug logs from Bluemix Mobile Services frameworks will be displayed on the console.
    /// This is useful if you need to debug an issue that you believe is related to Bluemix Mobile Services.
    public static var isInternalDebugLoggingEnabled: Bool = false
    
    /// Determines whether logs get stored locally on the device.
    /// Must be set to `true` to be able to later send logs to the Mobile Analytics service.
    public static var isLogStorageEnabled: Bool = false
    
    /// The maximum file size (in bytes) for log storage.
    /// Logs from `Logger` and logs from `Analytics` are stored in separate files, both of which are limited by `maxLogStoreSize`.
    public static var maxLogStoreSize: UInt64 = 100000
    
    /// `True` if the app crashed recently due to an uncaught exception.
    /// `BMSAnalytics` automatically records uncaught exceptions, so there is no need to change the value of this property manually.
    /// It will be set back to `false` after analytics logs are sent to the server with `Analytics.send(completionHandler:)`.
    public static var isUncaughtExceptionDetected: Bool {
        get {
            return Logger.delegate?.isUncaughtExceptionDetected ?? false
        }
        set {
            Logger.delegate?.isUncaughtExceptionDetected = newValue
        }
    }
    
    
    
    // MARK: Properties (internal)
    
    // Used to persist all logs to the device's file system and send logs to the Mobile Analytics service.
    // Public access required by BMSAnalytics framework, which is required to initialize this property.
    public static var delegate: LoggerDelegate?
    
    // Each logger instance is distinguished only by its "name" property.
    internal static var loggerInstances: [String: Logger] = [:]
    
    // Prefix for all internal logger names.
    public static let bmsLoggerPrefix = "bmssdk."
    
    
    
    // MARK: Methods
    
    /**
        Creates a Logger instance that will be identified by the supplied name.
        If a Logger instance with that name was already created, the existing instance will be returned.

        - parameter name: The name that identifies this Logger instance.

        - returns: A Logger instance.
    */
    public static func logger(name identifier: String) -> Logger {
        
        if let existingLogger = Logger.loggerInstances[identifier] {
            return existingLogger
        }
        else {
            let newLogger = Logger(name: identifier)
            Logger.loggerInstances[identifier] = newLogger
            
            return newLogger
        }
    }
    
    private init(name: String) {
        self.name = name
    }

    
    /**
        Log at the debug `LogLevel`.

        - parameter message: The message to log.

        - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.
    */
    public func debug(message message: String, file: String = #file, function: String = #function, line: Int = #line) {
    
        log(message: message, level: LogLevel.debug, calledFile: file, calledFunction: function, calledLineNumber: line)
    }
    
    /**
        Log at the info `LogLevel`.

        - parameter message: The message to log.

        - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.
    */
    public func info(message message: String, file: String = #file, function: String = #function, line: Int = #line) {
    
        log(message: message, level: LogLevel.info, calledFile: file, calledFunction: function, calledLineNumber: line)
    }
    
    /**
        Log at the warn `LogLevel`.

        - parameter message: The message to log.

        - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.
    */
    public func warn(message message: String, file: String = #file, function: String = #function, line: Int = #line) {
    
        log(message: message, level: LogLevel.warn, calledFile: file, calledFunction: function, calledLineNumber: line)
    }
    
    /**
        Log at the error `LogLevel`.

        - parameter message: The message to log.

        - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.
    */
    public func error(message message: String, file: String = #file, function: String = #function, line: Int = #line) {
    
        log(message: message, level: LogLevel.error, calledFile: file, calledFunction: function, calledLineNumber: line)
    }
    
    /**
        Log at the fatal `LogLevel`.

        - parameter message: The message to log.

        - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.
    */
    public func fatal(message message: String, file: String = #file, function: String = #function, line: Int = #line) {
    
        log(message: message, level: LogLevel.fatal, calledFile: file, calledFunction: function, calledLineNumber: line)
    }
    
    // Equivalent to the other log methods, but this method accepts data as JSON rather than a string.
    internal func analytics(metadata metadata: [String: AnyObject], file: String = #file, function: String = #function, line: Int = #line) {
    
        log(message: "", level: LogLevel.analytics, calledFile: file, calledFunction: function, calledLineNumber: line, additionalMetadata: metadata)
    }
    
    
    
    // MARK: Methods (internal)
    
    // This is the master function that handles all of the logging, including level checking, printing to console, and writing to file.
    // All other log functions below this one are helpers for this function.
    internal func log(message logMessage: String, level: LogLevel, calledFile: String, calledFunction: String, calledLineNumber: Int, additionalMetadata: [String: AnyObject]? = nil) {
    
        // The level must exceed the Logger.logLevelFilter, or we do nothing. Lower integer values for the level correspond to higher severity.
        guard level.rawValue <= Logger.logLevelFilter.rawValue else {
            return
        }
        
        if self.name.hasPrefix(Logger.bmsLoggerPrefix) && !Logger.isInternalDebugLoggingEnabled && level == LogLevel.debug {
            // Don't show our internal logs in the console.
        }
        else {
            // Print to console
            Logger.printLog(message: logMessage, loggerName: self.name, level: level, calledFunction: calledFunction, calledFile: calledFile, calledLineNumber: calledLineNumber)
        }
        
        Logger.delegate?.logToFile(message: logMessage, level: level, loggerName: self.name, calledFile: calledFile, calledFunction: calledFunction, calledLineNumber: calledLineNumber, additionalMetadata: additionalMetadata)
    }
    
    
    // Format: [DEBUG] [bmssdk.logger] logMessage in Logger.swift:234 :: "Some random message".
    // Public access required by BMSAnalytics framework.
    public static func printLog(message logMessage: String, loggerName: String, level: LogLevel, calledFunction: String, calledFile: String, calledLineNumber: Int) {
        
        // Suppress console log output for apps that are being released to the App Store
        #if !RELEASE_BUILD
            if level != LogLevel.analytics {
                print("[\(level.asString)] [\(loggerName)] \(calledFunction) in \(calledFile):\(calledLineNumber) :: \(logMessage)")
            }
        #endif
    }
}



#endif
