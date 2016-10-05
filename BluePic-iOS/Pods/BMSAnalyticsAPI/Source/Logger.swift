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


// MARK: LogLevel

/**
    The severity of the log message.
 
    Used to set the `logLevelFilter` property.
 
    - Note: Set `Logger.logLevelFilter` to `LogLevel.none` to prohibit any logs from being recorded. Do not use `LogLevel.analytics`; it is only meant to be used internally by the `BMSAnalytics` framework.
 */
public enum LogLevel: Int {
    
    
    case none, analytics, fatal, error, warn, info, debug
    
    
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

// Contains functionality to store logs locally on the device and send them to an analytics server.
// This protocol is implemented in the BMSAnalytics framework.
public protocol LoggerDelegate {
    
    var isUncaughtExceptionDetected: Bool { get set }
    
#if swift(>=3.0)
    
    func logToFile(message logMessage: String, level: LogLevel, loggerName: String, calledFile: String, calledFunction: String, calledLineNumber: Int, additionalMetadata: [String: Any]?)

#else
    
    func logToFile(message logMessage: String, level: LogLevel, loggerName: String, calledFile: String, calledFunction: String, calledLineNumber: Int, additionalMetadata: [String: AnyObject]?)

#endif
}



// MARK: - Logger

/**
    A logging framework that can print messages to the console, store them locally on the device, and send them to a remote Analytics server. With each log message, additional information is gathered such as the file, function, and line where the log was called, as well as the severity of the message.
 
    Multiple `Logger` instances can be created with different names using the `logger(name:)` method.
 
    When logging, choose the log method that matches the severity of the message. For example, use `debug(message:)` for fine-grained information and `fatal(message:)` for severe errors that may lead to application crashes. To limit which logs get printed to the console and stored on the device, set the `logLevelFilter` property.

    To enable logs to be stored locally on the device, set the `logStoreEnabled` property to `true`. Logs are added to the log file until the file size is greater than the `maxLogStoreSize` property. At this point, the first half of the stored logs will be deleted to make room for new log data.

    To send logs to the Analytics server, call the `send()` method. When the log data is successfully uploaded, the logs will be deleted from local storage.
 
    - Note: The `Logger` class sets an uncaught exception handler to log application crashes. If you wish to set your own exception handler, do so **before** calling `Logger.logger(name:)`, or the `Logger` exception handler will be overwritten.
 
    - Important: The `BMSAnalytics` framework is required for log messages to be stored and sent to an Analytics server. If this framework is not available, the `Logger` class can only print messages to the console.
 */
public class Logger {
    
    
    // MARK: Properties (API)
    
    /// The name that identifies this Logger instance.
    public let name: String
    
    /// Logs below this severity level will be ignored completely.
    ///
    /// The default value is `LogLevel.Debug`.
    ///
    /// Set the value to `LogLevel.None` to turn off all logging.
    public static var logLevelFilter: LogLevel = LogLevel.debug
    
    /// If set to `true`, the internal BMSCore debug logs will be displayed on the console.
    public static var isInternalDebugLoggingEnabled: Bool = false
    
    /// Determines whether logs get stored locally on the device.
    /// Must be set to `true` to be able to send logs to the Analytics server.
    public static var isLogStorageEnabled: Bool = false
    
    /// The maximum file size (in bytes) for log storage.
    /// Both the Analytics and Logger log files are limited by `maxLogStoreSize`.
    public static var maxLogStoreSize: UInt64 = 100000
    
    /// True if the app crashed recently due to an uncaught exception.
    /// This property will be set back to `false` if the logs are sent to the server.
    public static var isUncaughtExceptionDetected: Bool {
        get {
            return Logger.delegate?.isUncaughtExceptionDetected ?? false
        }
        set {
            Logger.delegate?.isUncaughtExceptionDetected = newValue
        }
    }
    
    
    
    // MARK: Properties (internal)
    
    // Used to persist all logs to the device's file system and send logs to the analytics server.
    // Public access required by BMSAnalytics framework, which is required to initialize this property.
    public static var delegate: LoggerDelegate?
    
    // Each logger instance is distinguished only by its "name" property.
    internal static var loggerInstances: [String: Logger] = [:]
    
    // Prefix for all internal logger names.
    public static let bmsLoggerPrefix = "bmssdk."
    
    
    
    // MARK: Initializers
    
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
    
    
    
#if swift(>=3.0)
    
    
    // MARK: Methods (API)
    
    /**
        Log at the Debug LogLevel.
     
        - parameter message: The message to log.
        
        - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.
    */
    public func debug(message: String, file: String = #file, function: String = #function, line: Int = #line) {
        
        log(message: message, level: LogLevel.debug, calledFile: file, calledFunction: function, calledLineNumber: line)
    }
    
    /**
         Log at the Info LogLevel.
         
         - parameter message: The message to log.
         
         - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.
     */
    public func info(message: String, file: String = #file, function: String = #function, line: Int = #line) {
        
        log(message: message, level: LogLevel.info, calledFile: file, calledFunction: function, calledLineNumber: line)
    }
    
    /**
         Log at the Warn LogLevel.
         
         - parameter message: The message to log.
         
         - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.
     */
    public func warn(message: String, file: String = #file, function: String = #function, line: Int = #line) {
        
        log(message: message, level: LogLevel.warn, calledFile: file, calledFunction: function, calledLineNumber: line)
    }
    
    /**
         Log at the Error LogLevel.
     
         - parameter message: The message to log.
         
         - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.
     */
    public func error(message: String, file: String = #file, function: String = #function, line: Int = #line) {
        
        log(message: message, level: LogLevel.error, calledFile: file, calledFunction: function, calledLineNumber: line)
    }
    
    /**
         Log at the Fatal LogLevel.
         
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
        
        // The level must exceed the Logger.logLevelFilter, or we do nothing
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
    
    
#else
    
    
    // MARK: Methods (API)
    
    /**
        Log at the Debug LogLevel.

        - parameter message: The message to log.

        - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.
    */
    public func debug(message message: String, file: String = #file, function: String = #function, line: Int = #line) {
        
        log(message: message, level: LogLevel.debug, calledFile: file, calledFunction: function, calledLineNumber: line)
    }
    
    /**
        Log at the Info LogLevel.

        - parameter message: The message to log.

        - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.
    */
    public func info(message message: String, file: String = #file, function: String = #function, line: Int = #line) {
        
        log(message: message, level: LogLevel.info, calledFile: file, calledFunction: function, calledLineNumber: line)
    }
    
    /**
        Log at the Warn LogLevel.

        - parameter message: The message to log.

        - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.
    */
    public func warn(message message: String, file: String = #file, function: String = #function, line: Int = #line) {
        
        log(message: message, level: LogLevel.warn, calledFile: file, calledFunction: function, calledLineNumber: line)
    }
    
    /**
        Log at the Error LogLevel.

        - parameter message: The message to log.

        - Note: Do not supply values for the `file`, `function`, or `line` parameters. These parameters take default values to automatically record the file, function, and line in which this method was called.
    */
    public func error(message message: String, file: String = #file, function: String = #function, line: Int = #line) {
        
        log(message: message, level: LogLevel.error, calledFile: file, calledFunction: function, calledLineNumber: line)
    }
    
    /**
        Log at the Fatal LogLevel.

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
    
        // The level must exceed the Logger.logLevelFilter, or we do nothing
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
    
    
#endif
    
    
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
