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



public enum PersistencePolicy: String {
    
    case always = "ALWAYS"
    case never = "NEVER"
}



public protocol AuthorizationManager {

    /*!
        @brief check if authorization is Required, using the responseAuthorizationHeader string
        @param statusCode http response status code
        @param responseAuthorizationHeader authirization header
    
        @return Whether authorization is required
    */
    func isAuthorizationRequired(for statusCode: Int, httpResponseAuthorizationHeader: String) -> Bool
    
    /*
        @brief Whether authorization is required
        @param httpResponse http response ti check
    */
    func isAuthorizationRequired(for httpResponse: Response) -> Bool
    
    /*!
        @brief Starts authorization process
        @param completionHandler The completion handler
    */
    func obtainAuthorization(completionHandler callback: BMSCompletionHandler?)
    
	/*!
        @brief Clears authorization data
    */
	func clearAuthorizationData()

	/*!
        @brief Returns previously obtained authorization header. The value will be added to all outgoing requests as Authorization header.
        @return cached authorization header
    */
	var cachedAuthorizationHeader: String? { get }
	
    /*!
        @return UserIdentity object
    */
	var userIdentity: UserIdentity? { get }
    
    /*!
        @return DeviceIdentity object
    */
	var deviceIdentity: DeviceIdentity { get }
    
    /*!
        @return AppIdentity object
    */
	var appIdentity: AppIdentity { get }
}
