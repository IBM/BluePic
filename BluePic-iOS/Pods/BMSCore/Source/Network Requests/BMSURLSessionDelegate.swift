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
    

    
// Custom wrapper for UrlSessionDelegate
// Uses AuthorizationManager from the BMSSecurity framework to handle network requests to MCA-protected backends
internal class BMSURLSessionDelegate: NSObject {
    
    
    // The user-supplied session delegate
    internal let parentDelegate: URLSessionDelegate?
    
    // Used to reconstruct the original task if using AuthorizationManager
    internal let originalTask: BMSURLSessionTaskType
    
    // Network request metadata that will be logged via Analytics
    internal let startTime: Int64
    internal let trackingId: String
    internal var url: URL?
    internal var response: URLResponse?
    internal var bytesSent: Int64 = 0
    internal var bytesReceived: Int64 = 0
    
    // When the request is complete, either the didBecomeInvalidWithError or willCacheResponse method will be called depending on the type of task. When this occurs, we log request metadata using the Analytics API. In case both of the prior methods are called, we want to make sure that the metadata does not get logged twice for the same request.
    internal var requestMetadataWasRecorded = false
    
    
    
    init(parentDelegate: URLSessionDelegate?, originalTask: BMSURLSessionTaskType) {
        
        self.parentDelegate = parentDelegate
        self.originalTask = originalTask
        
        // Allows Analytics to track each network request and its associated metadata.
        self.trackingId = UUID().uuidString
        
        // The time at which the request is considered to have started.
        // We start the request timer here so that it doesn't need to get passed around via method parameters.
        // The request is considered to have begun when the URLSessionTask is created.
        self.startTime = Int64(Date.timeIntervalSinceReferenceDate * 1000) // milliseconds
    }
}
    
    
    
// MARK: - Session delegate
    
extension BMSURLSessionDelegate: URLSessionDelegate {
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        
        parentDelegate?.urlSession!(session, didBecomeInvalidWithError: error)
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        completionHandler(.performDefaultHandling, nil)
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        
        parentDelegate?.urlSessionDidFinishEvents!(forBackgroundURLSession: session)
    }
}
    
    

// MARK: - Task delegate

extension BMSURLSessionDelegate: URLSessionTaskDelegate {
    
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        
        (parentDelegate as? URLSessionTaskDelegate)?.urlSession!(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        completionHandler(.performDefaultHandling, nil)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        
        (parentDelegate as? URLSessionTaskDelegate)?.urlSession!(session, task: task, needNewBodyStream: completionHandler)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        (parentDelegate as? URLSessionTaskDelegate)?.urlSession!(session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        // No other delegate methods should be called after this one, so we are ready to record the request metadata.
        logRequestMetadata()
        
        (parentDelegate as? URLSessionTaskDelegate)?.urlSession!(session, task: task, didCompleteWithError: error)
    }
    
    @available(watchOS 3.0, *)
    @available(iOS, introduced: 10)
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
    
        (parentDelegate as? URLSessionTaskDelegate)?.urlSession!(session, task: task, didFinishCollecting: metrics)
    }
}



// MARK: - Data delegate

extension BMSURLSessionDelegate: URLSessionDataDelegate {
    
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        if BMSURLSession.isAuthorizationManagerRequired(for: response) {
            
            // originalRequest should always have a value. It can only be nil for stream tasks, which is not supported by BMSURLSession.
            let originalRequest = dataTask.originalRequest!
            
            // Resend the original request with the "Authorization" header added
            BMSURLSession.handleAuthorizationChallenge(session: session, request: originalRequest, originalTask: self.originalTask, handleTask: { (urlSessionTask) in
                
                if let taskWithAuthorization = urlSessionTask {
                    taskWithAuthorization.resume()
                }
                else {
                    (self.parentDelegate as? URLSessionDataDelegate)?.urlSession!(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
                }
            })
        }
        else {
    
            self.url = dataTask.originalRequest?.url
            self.response = response
            self.bytesSent = dataTask.countOfBytesSent

            (parentDelegate as? URLSessionDataDelegate)?.urlSession!(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
        
        (parentDelegate as? URLSessionDataDelegate)?.urlSession!(session, dataTask: dataTask, didBecome: downloadTask)
    }
    
    @available(iOS 9.0, *)
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome streamTask: URLSessionStreamTask) {
        
        (parentDelegate as? URLSessionDataDelegate)?.urlSession!(session, dataTask: dataTask, didBecome: streamTask)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        self.bytesReceived += data.count
        
        (parentDelegate as? URLSessionDataDelegate)?.urlSession!(session, dataTask: dataTask, didReceive: data)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        
        // No other delegate methods should be called after this one, so we are ready to record the request metadata.
        logRequestMetadata()
        
        (parentDelegate as? URLSessionDataDelegate)?.urlSession!(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler)
    }
}
    
    
    
// MARK: Helpers
    
extension BMSURLSessionDelegate {
    
    fileprivate func logRequestMetadata() {
        
        // This function can be called from 2 places (willCacheResponse and didCompleteWithError), so we make sure to log analytics only once in case both of those methods get called.
        if BMSURLSession.shouldRecordNetworkMetadata && !requestMetadataWasRecorded {
            let requestMetadata = BMSURLSession.getRequestMetadata(response: response, bytesSent: bytesSent, bytesReceived: bytesReceived, trackingId: trackingId, startTime: startTime, url: url)
            Analytics.log(metadata: requestMetadata)
            
            requestMetadataWasRecorded = true
        }
    }
    
}
    
    
    
    
    
/**************************************************************************************************/
    
    
    
    
    
// MARK: - Swift 2
    
#else
    
    

internal class BMSURLSessionDelegate: NSObject {
    
    
    // The user-supplied session delegate
    internal let parentDelegate: NSURLSessionDelegate?
    
    // Used to reconstruct the original task if using AuthorizationManager
    internal let originalTask: BMSURLSessionTaskType
    
    // Network request metadata that will be logged via Analytics
    internal let startTime: Int64
    internal let trackingId: String
    internal var url: NSURL?
    internal var response: NSURLResponse?
    internal var bytesSent: Int64 = 0
    internal var bytesReceived: Int64 = 0
    
    // When the request is complete, either the didBecomeInvalidWithError or willCacheResponse method will be called depending on the type of task. When this occurs, we log request metadata using the Analytics API. In case both of the prior methods are called, we want to make sure that the metadata does not get logged twice for the same request.
    internal var requestMetadataWasRecorded = false
    
    
    
    init(parentDelegate: NSURLSessionDelegate?, originalTask: BMSURLSessionTaskType) {
        
        self.parentDelegate = parentDelegate
        self.originalTask = originalTask
        
        // Allows Analytics to track each network request and its associated metadata.
        self.trackingId = NSUUID().UUIDString
        
        // The time at which the request is considered to have started.
        // We start the request timer here so that it doesn't need to get passed around via method parameters.
        // The request is considered to have begun when the URLSessionTask is created.
        self.startTime = Int64(NSDate.timeIntervalSinceReferenceDate() * 1000) // milliseconds

    }
}
    
    
    
// MARK: - Session Delegate
    
extension BMSURLSessionDelegate: NSURLSessionDelegate {
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        
        parentDelegate?.URLSession?(session, didBecomeInvalidWithError: error)
    }
    
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
        completionHandler(.PerformDefaultHandling, nil)
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        
        parentDelegate?.URLSessionDidFinishEventsForBackgroundURLSession?(session)
    }
}



// MARK: - Task delegate

extension BMSURLSessionDelegate: NSURLSessionTaskDelegate {
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
        
        (parentDelegate as? NSURLSessionTaskDelegate)?.URLSession?(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
        completionHandler(.PerformDefaultHandling, nil)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, needNewBodyStream completionHandler: (NSInputStream?) -> Void) {
        
        (parentDelegate as? NSURLSessionTaskDelegate)?.URLSession?(session, task: task, needNewBodyStream: completionHandler)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        (parentDelegate as? NSURLSessionTaskDelegate)?.URLSession?(session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        // No other delegate methods should be called after this one, so we are ready to record the request metadata.
        logRequestMetadata()
        
        (parentDelegate as? NSURLSessionTaskDelegate)?.URLSession?(session, task: task, didCompleteWithError: error)
    }
}



// MARK: - Data delegate

extension BMSURLSessionDelegate: NSURLSessionDataDelegate {
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        
        if BMSURLSession.isAuthorizationManagerRequired(response) {
            
            // originalRequest should always have a value. It can only be nil for stream tasks, which is not supported by BMSURLSession.
            let originalRequest = dataTask.originalRequest!.mutableCopy() as! NSMutableURLRequest
            
            BMSURLSession.handleAuthorizationChallenge(session: session, request: originalRequest, originalTask: self.originalTask, handleTask: { (urlSessionTask) in
                
                if let taskWithAuthorization = urlSessionTask {
                    
                    taskWithAuthorization.resume()
                }
                else {
                    (self.parentDelegate as? NSURLSessionDataDelegate)?.URLSession?(session, dataTask: dataTask, didReceiveResponse: response, completionHandler: completionHandler)
                }
            })
        }
        else {
            
            self.url = dataTask.originalRequest?.URL
            self.response = response
            self.bytesSent = dataTask.countOfBytesSent
            
            (parentDelegate as? NSURLSessionDataDelegate)?.URLSession?(session, dataTask: dataTask, didReceiveResponse: response, completionHandler: completionHandler)
        }
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeDownloadTask downloadTask: NSURLSessionDownloadTask) {
        
        (parentDelegate as? NSURLSessionDataDelegate)?.URLSession?(session, dataTask: dataTask, didBecomeDownloadTask: downloadTask)
    }
    
    @available(iOS 9.0, *)
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeStreamTask streamTask: NSURLSessionStreamTask) {
        
        (parentDelegate as? NSURLSessionDataDelegate)?.URLSession?(session, dataTask: dataTask, didBecomeStreamTask: streamTask)
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        
        self.bytesReceived += data.length
        
        (parentDelegate as? NSURLSessionDataDelegate)?.URLSession?(session, dataTask: dataTask, didReceiveData: data)
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, willCacheResponse proposedResponse: NSCachedURLResponse, completionHandler: (NSCachedURLResponse?) -> Void) {
        
        // No other delegate methods should be called after this one, so we are ready to record the request metadata.
        logRequestMetadata()
        
        (parentDelegate as? NSURLSessionDataDelegate)?.URLSession?(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler)
    }
}
    
    
    
// MARK: Helpers

extension BMSURLSessionDelegate {
    
    private func logRequestMetadata() {
        
        // This function can be called from 2 places (willCacheResponse and didCompleteWithError), so we make sure to log analytics only once in case both of those methods get called.
        if BMSURLSession.shouldRecordNetworkMetadata && !requestMetadataWasRecorded {
            let requestMetadata = BMSURLSession.getRequestMetadata(response: response, bytesSent: bytesSent, bytesReceived: bytesReceived, trackingId: trackingId, startTime: startTime, url: url)
            Analytics.log(metadata: requestMetadata)
            
            requestMetadataWasRecorded = true
        }
    }
    
}

    

#endif
