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



// MARK: - Swift 3

#if swift(>=3.0)
    

    
// Custom wrapper for URLSessionDelegate
// Uses AuthorizationManager from the BMSSecurity framework to handle network requests to MCA-protected backends
internal class BMSURLSessionDelegate: NSObject {
    
    
    // The user-supplied session delegate
    internal let parentDelegate: URLSessionDelegate?
    
    // The session that this delegate serves.
    internal let bmsUrlSession: BMSURLSession
    
    // Used to reconstruct the original task if using AuthorizationManager
    internal let originalTask: BMSURLSessionTaskType
    
    // Network request metadata that will be logged via Analytics
    internal var requestMetadata: RequestMetadata
    
    // Checks if request metadata has already been recorded so that the same request is not logged more than once
    internal var requestMetadataWasRecorded: Bool = false
    
    // The number of times to resend the original request if it fails to send.
    internal var numberOfRetries: Int
    
    
    
    init(parentDelegate: URLSessionDelegate?, bmsUrlSession: BMSURLSession, originalTask: BMSURLSessionTaskType, numberOfRetries: Int) {
        
        self.parentDelegate = parentDelegate
        self.bmsUrlSession = bmsUrlSession
        self.originalTask = originalTask
        self.numberOfRetries = numberOfRetries
        
        let trackingId = UUID().uuidString
        let startTime = Int64(Date.timeIntervalSinceReferenceDate * 1000) // milliseconds
        self.requestMetadata = RequestMetadata(url: nil, startTime: startTime, trackingId: trackingId)
    }
}
    
    
    
// MARK: - Session delegate
    
extension BMSURLSessionDelegate: URLSessionDelegate {
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        
        parentDelegate?.urlSession?(session, didBecomeInvalidWithError: error)
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        completionHandler(.performDefaultHandling, nil)
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        
        parentDelegate?.urlSessionDidFinishEvents?(forBackgroundURLSession: session)
    }
}
    
    

// MARK: - Task delegate

extension BMSURLSessionDelegate: URLSessionTaskDelegate {
    
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        
        (parentDelegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        completionHandler(.performDefaultHandling, nil)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        
        (parentDelegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, needNewBodyStream: completionHandler)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        (parentDelegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if BMSURLSessionUtility.shouldRetryRequest(response: requestMetadata.response, error: error, numberOfRetries: numberOfRetries) {
            
            if let originalRequest = task.originalRequest {
                BMSURLSessionUtility.retryRequest(originalRequest: originalRequest, originalTask: originalTask, bmsUrlSession: bmsUrlSession)
            }
            else {
                (parentDelegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, didCompleteWithError: error)
            }
        }
        // Only log the request metadata if a response was received so that we have all of the required data for logging
        else if requestMetadata.response != nil && requestMetadata.url != nil {
    
            recordNetworkMetadata()
            (parentDelegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, didCompleteWithError: error)
        }
        else {
    
            (parentDelegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, didCompleteWithError: error)
        }
    }
    
    @available(watchOS 3.0, *)
    @available(iOS, introduced: 10)
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
    
        (parentDelegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, didFinishCollecting: metrics)
    }
}



// MARK: - Data delegate

extension BMSURLSessionDelegate: URLSessionDataDelegate {
    
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        if BMSURLSessionUtility.isAuthorizationManagerRequired(for: response) {
            
            // originalRequest should always have a value. It can only be nil for stream tasks, which is not supported by BMSURLSession.
            let originalRequest = dataTask.originalRequest!
            
            // Resend the original request with the "Authorization" header added
            BMSURLSessionUtility.handleAuthorizationChallenge(session: session, request: originalRequest, requestMetadata: requestMetadata, originalTask: self.originalTask, handleFailure: {
                    (self.parentDelegate as? URLSessionDataDelegate)?.urlSession!(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
            })
        }
        else {
            
            requestMetadata.url = dataTask.originalRequest?.url
            requestMetadata.response = response
            requestMetadata.bytesSent = dataTask.countOfBytesSent

            (parentDelegate as? URLSessionDataDelegate)?.urlSession?(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
        
        (parentDelegate as? URLSessionDataDelegate)?.urlSession?(session, dataTask: dataTask, didBecome: downloadTask)
    }
    
    @available(iOS 9.0, *)
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome streamTask: URLSessionStreamTask) {
        
        (parentDelegate as? URLSessionDataDelegate)?.urlSession?(session, dataTask: dataTask, didBecome: streamTask)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        requestMetadata.bytesReceived += data.count
        
        (parentDelegate as? URLSessionDataDelegate)?.urlSession?(session, dataTask: dataTask, didReceive: data)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        
        recordNetworkMetadata()
        
        (parentDelegate as? URLSessionDataDelegate)?.urlSession?(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler)
    }
    
    
    
    // MARK: - Helpers
    
    // Log the request network metadata if it has not been already
    func recordNetworkMetadata() {
        
        if !requestMetadataWasRecorded && BMSURLSession.shouldRecordNetworkMetadata {
    
            requestMetadata.endTime = Int64(Date.timeIntervalSinceReferenceDate * 1000) // milliseconds
            requestMetadata.recordMetadata()
            requestMetadataWasRecorded = true
        }
    }
}
    
    
    
    
    
/**************************************************************************************************/
    
    
    
    
    
// MARK: - Swift 2
    
#else
    
    

// Custom wrapper for NSURLSessionDelegate
// Uses AuthorizationManager from the BMSSecurity framework to handle network requests to MCA-protected backends
internal class BMSURLSessionDelegate: NSObject {
    
    
    // The user-supplied session delegate
    internal let parentDelegate: NSURLSessionDelegate?
    
    // The session that this delegate serves.
    internal let bmsUrlSession: BMSURLSession
    
    // Used to reconstruct the original task if using AuthorizationManager
    internal let originalTask: BMSURLSessionTaskType
    
    // Network request metadata that will be logged via Analytics
    internal var requestMetadata: RequestMetadata
    
    // Checks if request metadata has already been recorded so that the same request is not logged more than once
    internal var requestMetadataWasRecorded: Bool = false
    
    // The number of times to resend the original request if it fails to send.
    internal var numberOfRetries: Int

    
    
    init(parentDelegate: NSURLSessionDelegate?, bmsUrlSession: BMSURLSession, originalTask: BMSURLSessionTaskType, numberOfRetries: Int) {
        
        self.parentDelegate = parentDelegate
        self.bmsUrlSession = bmsUrlSession
        self.originalTask = originalTask
        self.numberOfRetries = numberOfRetries
        
        let trackingId = NSUUID().UUIDString
        let startTime = Int64(NSDate.timeIntervalSinceReferenceDate() * 1000) // milliseconds
        self.requestMetadata = RequestMetadata(url: nil, startTime: startTime, trackingId: trackingId)
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
        
        if BMSURLSessionUtility.shouldRetryRequest(response: requestMetadata.response, error: error, numberOfRetries: numberOfRetries) {
            
            if let originalRequest = task.originalRequest {
                BMSURLSessionUtility.retryRequest(originalRequest: originalRequest, originalTask: originalTask, bmsUrlSession: bmsUrlSession)
            }
            else {
                (parentDelegate as? NSURLSessionTaskDelegate)?.URLSession?(session, task: task, didCompleteWithError: error)
            }
        }
        // Only log the request metadata if a response was received so that we have all of the required data for logging
        else if requestMetadata.response != nil && requestMetadata.url != nil {
            
            recordNetworkMetadata()
            (parentDelegate as? NSURLSessionTaskDelegate)?.URLSession?(session, task: task, didCompleteWithError: error)
        }
        else {
            
            (parentDelegate as? NSURLSessionTaskDelegate)?.URLSession?(session, task: task, didCompleteWithError: error)
        }
    }
}



// MARK: - Data delegate

extension BMSURLSessionDelegate: NSURLSessionDataDelegate {
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        
        if BMSURLSessionUtility.isAuthorizationManagerRequired(response) {
            
            // originalRequest should always have a value. It can only be nil for stream tasks, which is not supported by BMSURLSession.
            let originalRequest = dataTask.originalRequest!.mutableCopy() as! NSMutableURLRequest
            
            BMSURLSessionUtility.handleAuthorizationChallenge(session: session, request: originalRequest, requestMetadata: requestMetadata, originalTask: self.originalTask, handleFailure: {
                    (self.parentDelegate as? NSURLSessionDataDelegate)?.URLSession?(session, dataTask: dataTask, didReceiveResponse: response, completionHandler: completionHandler)
            })
        }
        else {
            
            requestMetadata.url = dataTask.originalRequest?.URL
            requestMetadata.response = response
            requestMetadata.bytesSent = dataTask.countOfBytesSent
            
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
    
        requestMetadata.bytesReceived += data.length
    
        (parentDelegate as? NSURLSessionDataDelegate)?.URLSession?(session, dataTask: dataTask, didReceiveData: data)
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, willCacheResponse proposedResponse: NSCachedURLResponse, completionHandler: (NSCachedURLResponse?) -> Void) {
        
        recordNetworkMetadata()
        
        (parentDelegate as? NSURLSessionDataDelegate)?.URLSession?(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler)
    }
    
    
    
    // MARK: - Helpers
    
    // Log the request network metadata if it has not been already
    func recordNetworkMetadata() {
        
        if !requestMetadataWasRecorded && BMSURLSession.shouldRecordNetworkMetadata {
            
            requestMetadata.endTime = Int64(NSDate.timeIntervalSinceReferenceDate() * 1000) // milliseconds
            requestMetadata.recordMetadata()
            requestMetadataWasRecorded = true
        }
    }
    
}



#endif
