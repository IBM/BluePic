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
    
    
    
/**
    Indicates a failure that occurred within the BMSCore framework.
*/
public enum BMSCoreError: Error {
    
    
    /// The URL provided in the `Request` initializer is invalid.
    case malformedUrl
    
    /// Need to call the `BMSClient.initialize(bluemixAppRoute:bluemixAppGUID:bluemixRegion:)` method.
    case clientNotInitialized
    
    /// The network request failed due to a 4xx or 5xx status code.
	case serverRespondedWithError
    
    static let domain = "com.ibm.mobilefirstplatform.clientsdk.swift.bmscore"
}
    
    
    
    
    
/**************************************************************************************************/
    
    
    
    
    
// MARK: - Swift 2
    
#else
    
    
    
/**
    Indicates a failure that occurred within the BMSCore framework.
*/
public enum BMSCoreError: Int, ErrorType {
    
    
    /// The URL provided in the `Request` initializer is invalid.
    case malformedUrl
    
    /// Need to call the `BMSClient.initialize(bluemixAppRoute:bluemixAppGUID:bluemixRegion:)` method.
    case clientNotInitialized
    
    /// The network request failed due to a 4xx or 5xx status code.
    case serverRespondedWithError
    
    static let domain = "com.ibm.mobilefirstplatform.clientsdk.swift.bmscore"
}


#endif
