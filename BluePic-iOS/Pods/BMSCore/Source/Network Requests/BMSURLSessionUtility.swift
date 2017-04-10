/*
*     Copyright 2017 IBM Corp.
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


import BMSAnalyticsAPI

// MARK: - Swift 3

#if swift(>=3.0)
    
    
    
// Contains helper methods for BMSURLSession and BMSURLSessionDelegate
// This is where the "Bluemix Mobile Services" magic happens
internal struct BMSURLSessionUtility {
    
    
    // Inject BMSSecurity and BMSAnalytics into the request object by adding headers
    internal static func addBMSHeaders(to request: URLRequest, onlyIf precondition: Bool) -> URLRequest {
        
        var bmsRequest = request
        
        // If the request is in the process of authentication with the MCA authorization server, do not attempt to add headers, since this is an intermediary request.
        if precondition {
            
            // Security
            let authManager = BMSClient.sharedInstance.authorizationManager
            if let authHeader: String = authManager.cachedAuthorizationHeader {
                bmsRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
            }
            
            // Analytics
            bmsRequest.setValue(UUID().uuidString, forHTTPHeaderField: "x-wl-analytics-tracking-id")
            if let requestMetadata = BaseRequest.requestAnalyticsData {
                bmsRequest.setValue(requestMetadata, forHTTPHeaderField: "x-mfp-analytics-metadata")
            }
        }
        
        return bmsRequest
    }
    
    
    // Required to hook in challenge handling via AuthorizationManager, as well as handling auto-retries
    internal static func generateBmsCompletionHandler(from completionHandler: @escaping BMSDataTaskCompletionHandler, bmsUrlSession: BMSURLSession, urlSession: URLSession, request: URLRequest, originalTask: BMSURLSessionTaskType, requestBody: Data?, numberOfRetries: Int) -> BMSDataTaskCompletionHandler {
        
        let trackingId = UUID().uuidString
        let startTime = Int64(Date.timeIntervalSinceReferenceDate * 1000) // milliseconds
        var requestMetadata = RequestMetadata(url: request.url, startTime: startTime, trackingId: trackingId)
        
        return { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            
            if shouldRetryRequest(response: response, error: error, numberOfRetries: numberOfRetries) {
                
                retryRequest(originalRequest: request, originalTask: originalTask, bmsUrlSession: bmsUrlSession)
            }
            else if isAuthorizationManagerRequired(for: response) {
                
                // If authentication is successful, resend the original request with the "Authorization" header added
                handleAuthorizationChallenge(session: urlSession, request: request, requestMetadata: requestMetadata, originalTask: originalTask, handleFailure: {
                    completionHandler(data, response, error)
                })
            }
                // Don't log the request metadata if the response is a redirect
            else if let response = response as? HTTPURLResponse, response.statusCode >= 300 && response.statusCode < 400 {
                
                completionHandler(data, response, error)
            }
                // Only log the request metadata if a response was received so that we have all of the required data for logging
            else if response != nil {
                
                if BMSURLSession.shouldRecordNetworkMetadata {
                    
                    requestMetadata.response = response
                    requestMetadata.bytesReceived = Int64(data?.count ?? 0)
                    requestMetadata.bytesSent = Int64(requestBody?.count ?? 0)
                    requestMetadata.endTime = Int64(Date.timeIntervalSinceReferenceDate * 1000) // milliseconds
                    
                    requestMetadata.recordMetadata()
                }
                
                completionHandler(data, response, error)
            }
            else {
                
                completionHandler(data, response, error)
            }
        }
    }
    
    
    // Determines whether auto-retry is appropriate given the conditions of the request failure.
    internal static func shouldRetryRequest(response: URLResponse?, error: Error?, numberOfRetries: Int) -> Bool {
        
        // Make sure auto-retries are even allowed
        guard numberOfRetries > 0 else {
            return false
        }
        
        // Client-side issues eligible for retries
        let errorCodesForRetries: [Int] = [NSURLErrorTimedOut, NSURLErrorCannotConnectToHost, NSURLErrorNetworkConnectionLost]
        if let error = error as? NSError,
            errorCodesForRetries.contains(error.code) {
            
            // If the device is running iOS, we should make sure that it has a network connection before resending the request
            #if os(iOS)
                let networkDetector = NetworkMonitor()
                if networkDetector?.currentNetworkConnection != NetworkConnection.noConnection {
                    return true
                }
                else {
                    BMSURLSession.logger.error(message: "Cannot retry the last BMSURLSession request because the device has no internet connection.")
                }
            #else
                return true
            #endif
        }
        
        // Server-side issues eligible for retries
        if let response = response as? HTTPURLResponse,
            response.statusCode == 504 {
            
            return true
        }
        
        return false
    }
    
    
    // Send the request again
    // For auto-retries
    internal static func retryRequest(originalRequest: URLRequest, originalTask: BMSURLSessionTaskType, bmsUrlSession: BMSURLSession) {
        
        // Duplicate the original BMSURLSession, but with 1 fewer retry available
        let newBmsUrlSession = BMSURLSession(configuration: bmsUrlSession.configuration, delegate: bmsUrlSession.delegate, delegateQueue: bmsUrlSession.delegateQueue, autoRetries: bmsUrlSession.numberOfRetries - 1)
        originalTask.prepareForResending(urlSession: newBmsUrlSession, request: originalRequest).resume()
    }
    
    
    // Determines if the response is an authentication challenge from an MCA-protected server
    // If true, we must use BMSSecurity to authenticate
    internal static func isAuthorizationManagerRequired(for response: URLResponse?) -> Bool {
        
        let authManager = BMSClient.sharedInstance.authorizationManager
        
        if let response = response as? HTTPURLResponse,
            let wwwAuthHeader = response.allHeaderFields["Www-Authenticate"] as? String,
            authManager.isAuthorizationRequired(for: response.statusCode, httpResponseAuthorizationHeader: wwwAuthHeader) {
            
            return true
        }
        return false
    }
    
    
    // First, obtain authorization with AuthorizationManager from BMSSecurity.
    // If authentication is successful, a new URLSessionTask is generated.
    // This new task is the same as the original task, but now with the "Authorization" header needed to complete the request successfully.
    internal static func handleAuthorizationChallenge(session urlSession: URLSession, request: URLRequest, requestMetadata: RequestMetadata, originalTask: BMSURLSessionTaskType, handleFailure: @escaping () -> Void) {
        
        let authManager = BMSClient.sharedInstance.authorizationManager
        let authCallback: BMSCompletionHandler = {(response: Response?, error:Error?) in
            
            if error == nil && response?.statusCode != nil && (response?.statusCode)! >= 200 && (response?.statusCode)! < 300 {
                
                var request = request
                
                let authManager = BMSClient.sharedInstance.authorizationManager
                if let authHeader: String = authManager.cachedAuthorizationHeader {
                    request.setValue(authHeader, forHTTPHeaderField: "Authorization")
                }
                
                originalTask.prepareForResending(urlSession: urlSession, request: request, requestMetadata: requestMetadata).resume()
            }
            else {
                BMSURLSession.logger.error(message: "Authorization process failed. \nError: \(error). \nResponse: \(response).")
                handleFailure()
            }
        }
        authManager.obtainAuthorization(completionHandler: authCallback)
    }
    
    
    internal static func recordMetadataCompletionHandler(request: URLRequest, requestMetadata: RequestMetadata, originalCompletionHandler: @escaping BMSDataTaskCompletionHandler) -> BMSDataTaskCompletionHandler {
        
        var requestMetadata = requestMetadata
        
        let newCompletionHandler = {(data: Data?, response: URLResponse?, error: Error?) -> Void in
            
            if BMSURLSession.shouldRecordNetworkMetadata {
                
                requestMetadata.bytesReceived = Int64(data?.count ?? 0)
                requestMetadata.bytesSent = Int64(request.httpBody?.count ?? 0)
                requestMetadata.endTime = Int64(Date.timeIntervalSinceReferenceDate * 1000) // milliseconds
                
                requestMetadata.recordMetadata()
            }
            
            originalCompletionHandler(data, response, error)
        }
        
        return newCompletionHandler
    }
    
}



// List of the supported types of URLSessionTask
// Stored in BMSURLSession to determine what type of task to use if the request needs to be resent
// Used for:
// AuthorizationManager - After successfully authenticating with MCA, the original request must be resent with the newly-obtained authorization header.
// Auto-retries - If the original request failed due to network issues, the request can be sent again for a number of attempts specified by the user
internal enum BMSURLSessionTaskType {
    
    case dataTask
    case dataTaskWithCompletionHandler(BMSDataTaskCompletionHandler)
    
    case uploadTaskWithFile(URL)
    case uploadTaskWithData(Data)
    case uploadTaskWithFileAndCompletionHandler(URL, BMSDataTaskCompletionHandler)
    case uploadTaskWithDataAndCompletionHandler(Data?, BMSDataTaskCompletionHandler)
    
    
    // Recreate the URLSessionTask from the original request to later resend it
    func prepareForResending(urlSession: NetworkSession, request: URLRequest, requestMetadata: RequestMetadata? = nil) -> URLSessionTask {
        
        // If this request is considered a continuation of the original request, then we record metadata from the original request instead of creating a new set of metadata (i.e. for MCA authorization requests). Otherwise, return the original completion handler (i.e. for auto-retries).
        // This is not required for delegates since this is already taken care of in BMSURLSessionDelegate
        func createNewCompletionHandler(originalCompletionHandler: @escaping BMSDataTaskCompletionHandler) -> BMSDataTaskCompletionHandler {
            
            var completionHandler = originalCompletionHandler
            if let requestMetadata = requestMetadata {
                completionHandler = BMSURLSessionUtility.recordMetadataCompletionHandler(request: request, requestMetadata: requestMetadata, originalCompletionHandler: completionHandler)
            }
            return completionHandler
        }
        
        switch self {
            
        case .dataTask:
            return urlSession.dataTask(with: request)
            
        case .dataTaskWithCompletionHandler(let completionHandler):
            let newCompletionHandler = createNewCompletionHandler(originalCompletionHandler: completionHandler)
            return urlSession.dataTask(with: request, completionHandler: newCompletionHandler)
            
        case .uploadTaskWithFile(let file):
            return urlSession.uploadTask(with: request, fromFile: file)
            
        case .uploadTaskWithData(let data):
            return urlSession.uploadTask(with: request, from: data)
            
        case .uploadTaskWithFileAndCompletionHandler(let file, let completionHandler):
            let newCompletionHandler = createNewCompletionHandler(originalCompletionHandler: completionHandler)
            return urlSession.uploadTask(with: request, fromFile: file, completionHandler: newCompletionHandler)
            
        case .uploadTaskWithDataAndCompletionHandler(let data, let completionHandler):
            let newCompletionHandler = createNewCompletionHandler(originalCompletionHandler: completionHandler)
            return urlSession.uploadTask(with: request, from: data, completionHandler: newCompletionHandler)
        }
    }
    
}





/**************************************************************************************************/





// MARK: - Swift 2
    
#else
    
    
    
internal struct BMSURLSessionUtility {


    // Inject BMSSecurity and BMSAnalytics into the request object by adding headers
    internal static func addBMSHeaders(to request: NSURLRequest, onlyIf precondition: Bool) -> NSURLRequest {
        
        let bmsRequest = request.mutableCopy() as! NSMutableURLRequest
        
        // If the request is in the process of authentication with the MCA authorization server, do not attempt to add headers, since this is an intermediary request.
        if precondition {
            
            // Security
            let authManager = BMSClient.sharedInstance.authorizationManager
            if let authHeader: String = authManager.cachedAuthorizationHeader {
                bmsRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
            }
            
            // Analytics
            bmsRequest.setValue(NSUUID().UUIDString, forHTTPHeaderField: "x-wl-analytics-tracking-id")
            if let requestMetadata = BaseRequest.requestAnalyticsData {
                bmsRequest.setValue(requestMetadata, forHTTPHeaderField: "x-mfp-analytics-metadata")
            }
        }
        
        return bmsRequest
    }
    
    
    // Needed to hook in challenge handling via AuthorizationManager, as well as handling auto-retries
    internal static func generateBmsCompletionHandler(from completionHandler: BMSDataTaskCompletionHandler, bmsUrlSession: BMSURLSession, urlSession: NSURLSession, request: NSURLRequest, originalTask: BMSURLSessionTaskType, requestBody: NSData?, numberOfRetries: Int) -> BMSDataTaskCompletionHandler {
        
        let trackingId = NSUUID().UUIDString
        let startTime = Int64(NSDate.timeIntervalSinceReferenceDate() * 1000) // milliseconds
        var requestMetadata = RequestMetadata(url: request.URL, startTime: startTime, trackingId: trackingId)
        
        return { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            if shouldRetryRequest(response: response, error: error, numberOfRetries: numberOfRetries) {
                
                retryRequest(originalRequest: request, originalTask: originalTask, bmsUrlSession: bmsUrlSession)
            }
            else if isAuthorizationManagerRequired(response) {
                
                // If authentication is successful, resend the original request with the "Authorization" header added
                let originalRequest = request.mutableCopy() as! NSMutableURLRequest
                handleAuthorizationChallenge(session: urlSession, request: originalRequest, requestMetadata: requestMetadata, originalTask: originalTask, handleFailure: {
                    completionHandler(data, response, error)
                })
            }
                // Don't log the request metadata if the response is a redirect
            else if let response = response as? NSHTTPURLResponse where response.statusCode >= 300 && response.statusCode < 400 {
                
                completionHandler(data, response, error)
            }
                // Only log the request metadata if a response was received so that we have all of the required data for logging
            else if response != nil {
                
                if BMSURLSession.shouldRecordNetworkMetadata {
                    
                    requestMetadata.response = response
                    requestMetadata.bytesReceived = Int64(data?.length ?? 0)
                    requestMetadata.bytesSent = Int64(requestBody?.length ?? 0)
                    requestMetadata.endTime = Int64(NSDate.timeIntervalSinceReferenceDate() * 1000) // milliseconds
                    
                    requestMetadata.recordMetadata()
                }
                
                completionHandler(data, response, error)
            }
            else {
                
                completionHandler(data, response, error)
            }
        }
    }
    
    
    // Determines whether auto-retry is appropriate given the conditions of the request failure.
    internal static func shouldRetryRequest(response response: NSURLResponse?, error: NSError?, numberOfRetries: Int) -> Bool {
        
        // Make sure auto-retries are even allowed
        guard numberOfRetries > 0 else {
            return false
        }
        
        // Client-side issues eligible for retries
        let errorCodesForRetries: [Int] = [NSURLErrorTimedOut, NSURLErrorCannotConnectToHost, NSURLErrorNetworkConnectionLost]
        if let error = error where
            errorCodesForRetries.contains(error.code) {
            
            // If the device is running iOS, we should make sure that it has a network connection before resending the request
            #if os(iOS)
                let networkDetector = NetworkMonitor()
                if networkDetector?.currentNetworkConnection != NetworkConnection.noConnection {
                    return true
                }
                else {
                    BMSURLSession.logger.error(message: "Cannot retry the last BMSURLSession request because the device has no internet connection.")
                }
            #else
                return true
            #endif
        }
        
        // Server-side issues eligible for retries
        if let response = response as? NSHTTPURLResponse where
            response.statusCode == 504 {
            
            return true
        }
        
        return false
    }
    
    
    // Send the request again
    // For auto-retries
    internal static func retryRequest(originalRequest originalRequest: NSURLRequest, originalTask: BMSURLSessionTaskType, bmsUrlSession: BMSURLSession) {
        
        // Duplicate the original BMSURLSession, but with 1 fewer retry available
        let newBmsUrlSession = BMSURLSession(configuration: bmsUrlSession.configuration, delegate: bmsUrlSession.delegate, delegateQueue: bmsUrlSession.delegateQueue, autoRetries: bmsUrlSession.numberOfRetries - 1)
        originalTask.prepareForResending(urlSession: newBmsUrlSession, request: originalRequest).resume()
    }
    
    
    internal static func isAuthorizationManagerRequired(response: NSURLResponse?) -> Bool {
        
        let authManager = BMSClient.sharedInstance.authorizationManager
        
        if let response = response as? NSHTTPURLResponse,
            let wwwAuthHeader = response.allHeaderFields["WWW-Authenticate"] as? String
            where authManager.isAuthorizationRequired(for: response.statusCode, httpResponseAuthorizationHeader: wwwAuthHeader) {
            
            return true
        }
        return false
    }
    
    
    // First, obtain authorization with AuthorizationManager from BMSSecurity.
    // If authentication is successful, a new URLSessionTask is generated.
    // This new task is the same as the original task, but now with the "Authorization" header needed to complete the request successfully.
    internal static func handleAuthorizationChallenge(session urlSession: NSURLSession, request: NSMutableURLRequest, requestMetadata: RequestMetadata, originalTask: BMSURLSessionTaskType, handleFailure: () -> Void) {
        
        let authManager = BMSClient.sharedInstance.authorizationManager
        let authCallback: BMSCompletionHandler = {(response: Response?, error:NSError?) in
            
            if error == nil && response?.statusCode != nil && (response?.statusCode)! >= 200 && (response?.statusCode)! < 300 {
                
                let authManager = BMSClient.sharedInstance.authorizationManager
                if let authHeader: String = authManager.cachedAuthorizationHeader {
                    request.setValue(authHeader, forHTTPHeaderField: "Authorization")
                }
                
                originalTask.prepareForResending(urlSession: urlSession, request: request, requestMetadata: requestMetadata).resume()
            }
            else {
                BMSURLSession.logger.error(message: "Authorization process failed. \nError: \(error). \nResponse: \(response).")
                handleFailure()
            }
        }
        authManager.obtainAuthorization(completionHandler: authCallback)
    }
    
    
    internal static func recordMetadataCompletionHandler(request request: NSURLRequest, requestMetadata: RequestMetadata, originalCompletionHandler: BMSDataTaskCompletionHandler) -> BMSDataTaskCompletionHandler {
        
        var requestMetadata = requestMetadata
        
        let newCompletionHandler = {(data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            if BMSURLSession.shouldRecordNetworkMetadata {
                
                requestMetadata.bytesReceived = Int64(data?.length ?? 0)
                requestMetadata.bytesSent = Int64(request.HTTPBody?.length ?? 0)
                requestMetadata.endTime = Int64(NSDate.timeIntervalSinceReferenceDate() * 1000) // milliseconds
                
                requestMetadata.recordMetadata()
            }
            
            originalCompletionHandler(data, response, error)
        }
        
        return newCompletionHandler
    }
    
}



// List of the supported types of NSURLSessionTask
// Stored in BMSURLSession to determine what type of task to use when resending the request after authenticating with MCA
internal enum BMSURLSessionTaskType {
    
    case dataTask
    case dataTaskWithCompletionHandler(BMSDataTaskCompletionHandler)
    
    case uploadTaskWithFile(NSURL)
    case uploadTaskWithData(NSData)
    case uploadTaskWithFileAndCompletionHandler(NSURL, BMSDataTaskCompletionHandler)
    case uploadTaskWithDataAndCompletionHandler(NSData?, BMSDataTaskCompletionHandler)
    
    
    // Recreate the URLSessionTask from the original request to later resend it
    func prepareForResending(urlSession urlSession: NetworkSession, request: NSURLRequest, requestMetadata: RequestMetadata? = nil) -> NSURLSessionTask {
        
        // If this request is considered a continuation of the original request, then we record metadata from the original request instead of creating a new set of metadata (i.e. for MCA authorization requests). Otherwise, return the original completion handler (i.e. for auto-retries).
        // This is not required for delegates since this is already taken care of in BMSURLSessionDelegate
        func createNewCompletionHandler(originalCompletionHandler originalCompletionHandler: BMSDataTaskCompletionHandler) -> BMSDataTaskCompletionHandler {
            
            var completionHandler = originalCompletionHandler
            if let requestMetadata = requestMetadata {
                completionHandler = BMSURLSessionUtility.recordMetadataCompletionHandler(request: request, requestMetadata: requestMetadata, originalCompletionHandler: completionHandler)
            }
            return completionHandler
        }
        
        switch self {
            
        case .dataTask:
            return urlSession.dataTaskWithRequest(request)
            
        case .dataTaskWithCompletionHandler(let completionHandler):
            let newCompletionHandler = createNewCompletionHandler(originalCompletionHandler: completionHandler)
            return urlSession.dataTaskWithRequest(request, completionHandler: newCompletionHandler)
            
        case .uploadTaskWithFile(let file):
            return urlSession.uploadTaskWithRequest(request, fromFile: file)
            
        case .uploadTaskWithData(let data):
            return urlSession.uploadTaskWithRequest(request, fromData: data)
            
        case .uploadTaskWithFileAndCompletionHandler(let file, let completionHandler):
            let newCompletionHandler = createNewCompletionHandler(originalCompletionHandler: completionHandler)
            return urlSession.uploadTaskWithRequest(request, fromFile: file, completionHandler: newCompletionHandler)
            
        case .uploadTaskWithDataAndCompletionHandler(let data, let completionHandler):
            let newCompletionHandler = createNewCompletionHandler(originalCompletionHandler: completionHandler)
            return urlSession.uploadTaskWithRequest(request, fromData: data, completionHandler: newCompletionHandler)
        }
    }
    
}


    
#endif
