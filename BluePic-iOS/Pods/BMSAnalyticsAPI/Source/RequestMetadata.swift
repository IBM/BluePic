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
    
    
    
/*
    Contains all of the metadata for one network request made via the `Request` or `BMSURLSession` APIs in BMSCore.
    Once the response is received and all of the metadata has been gathered, the metadata can be logged with Analytics.
     
    Note: This is not part of the API documentation because it is only meant to be used by BMSCore.
*/
public struct RequestMetadata {
    
    
    // The URL of the resource that the request is being sent to.
    public var url: URL?
    
    // The time at which the request is considered to have started.
    public let startTime: Int64
    
    // Allows Analytics to track each network request and its associated metadata.
    public let trackingId: String
    
    // The response received.
    public var response: URLResponse? = nil
    
    // The time at which the request is considered complete.
    public var endTime: Int64 = 0
    
    // Amount of data sent.
    public var bytesSent: Int64 = 0
    
    // Amount of data received in the response.
    public var bytesReceived: Int64 = 0
    
    // Combines all of the metadata into a single JSON object
    public var combinedMetadata: [String: Any] {
        
        var roundTripTime = 0
        // If this is not true, that means some BMSCore developer forgot to set the endTime somewhere
        if endTime > startTime {
            roundTripTime = endTime - startTime
        }
        
        // Data for analytics logging
        // NSNumber is used because, for some reason, JSONSerialization fails to convert Int64 to JSON
        var responseMetadata: [String: Any] = [:]
        responseMetadata["$category"] = "network"
        responseMetadata["$trackingid"] = trackingId
        responseMetadata["$outboundTimestamp"] = NSNumber(value: startTime)
        responseMetadata["$inboundTimestamp"] = NSNumber(value: endTime)
        responseMetadata["$roundTripTime"] = NSNumber(value: roundTripTime)
        responseMetadata["$bytesSent"] = NSNumber(value: bytesSent)
        responseMetadata["$bytesReceived"] = NSNumber(value: bytesReceived)
        
        if let urlString = url?.absoluteString {
            responseMetadata["$path"] = urlString
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            responseMetadata["$responseCode"] = httpResponse.statusCode
        }
        
        return responseMetadata
    }
    
    
    
    public init(url: URL?, startTime: Int64, trackingId: String) {
        self.url = url
        self.startTime = startTime
        self.trackingId = trackingId
    }
    
    
    // Use analytics to record the request metadata
    public func recordMetadata() {
        
        Analytics.log(metadata: combinedMetadata)
    }
}





/**************************************************************************************************/





// MARK: - Swift 2

#else



/*
    Contains all of the metadata for one network request made via the `Request` or `BMSURLSession` APIs in BMSCore.
    Once the response is received and all of the metadata has been gathered, the metadata can be logged with Analytics.
     
    Note: This is not part of the API documentation because it is only meant to be used by BMSCore.
*/
public struct RequestMetadata {

    
    // The URL of the resource that the request is being sent to.
    public var url: NSURL?
    
    // The time at which the request is considered to have started.
    public let startTime: Int64
    
    // Allows Analytics to track each network request and its associated metadata.
    public let trackingId: String
    
    // The response received.
    public var response: NSURLResponse? = nil
    
    // The time at which the request is considered complete.
    public var endTime: Int64 = 0
    
    // Amount of data sent.
    public var bytesSent: Int64 = 0
    
    // Amount of data received in the response.
    public var bytesReceived: Int64 = 0
    
    // Combines all of the metadata into a single JSON object
    public var combinedMetadata: [String: AnyObject] {
        
        var roundTripTime = 0
        // If this is not true, that means some BMSCore developer forgot to set the endTime somewhere
        if endTime > startTime {
            roundTripTime = endTime - startTime
        }
        
        // Data for analytics logging
        // NSNumber is used because, for some reason, JSONSerialization fails to convert Int64 to JSON
        var responseMetadata: [String: AnyObject] = [:]
        responseMetadata["$category"] = "network"
        responseMetadata["$trackingid"] = trackingId
        responseMetadata["$outboundTimestamp"] = NSNumber(longLong: startTime)
        responseMetadata["$inboundTimestamp"] = NSNumber(longLong: endTime)
        responseMetadata["$roundTripTime"] = NSNumber(integer: roundTripTime)
        responseMetadata["$bytesSent"] = NSNumber(longLong: bytesSent)
        responseMetadata["$bytesReceived"] = NSNumber(longLong: bytesReceived)
        
        if let urlString = url?.absoluteString {
            responseMetadata["$path"] = urlString
        }
        
        if let httpResponse = response as? NSHTTPURLResponse {
            responseMetadata["$responseCode"] = httpResponse.statusCode
        }
        
        return responseMetadata
    }
    
    
    
    public init(url: NSURL?, startTime: Int64, trackingId: String) {
        self.url = url
        self.startTime = startTime
        self.trackingId = trackingId
    }
    
    
    // Use analytics to record the request metadata
    public func recordMetadata() {
        
        Analytics.log(metadata: combinedMetadata)
    }
}
    
    
    
#endif
