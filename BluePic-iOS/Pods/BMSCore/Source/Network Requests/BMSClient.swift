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

/**
    A singleton that serves as an entry point to Bluemix client-server communication.
*/
public class BMSClient {
	
    // MARK: Constants
    
    /// The southern United States Bluemix region
    /// - Note: Use this in the `BMSClient initializeWithBluemixAppRoute` method.
    public static let REGION_US_SOUTH = ".ng.bluemix.net"
    
    /// The United Kingdom Bluemix region
    /// - Note: Use this in the `BMSClient initializeWithBluemixAppRoute` method.
    public static let REGION_UK = ".eu-gb.bluemix.net"
    
    /// The Sydney Bluemix region
    /// - Note: Use this in the `BMSClient initializeWithBluemixAppRoute` method.
    public static let REGION_SYDNEY = ".au-syd.bluemix.net"
    
    

    // MARK: Properties (API)
    
    /// This singleton should be used for all `BMSClient` activity
    public static let sharedInstance = BMSClient()
    
    /// Specifies the base backend URL
    public private(set) var bluemixAppRoute: String?
    
    // Specifies the bluemix region
    public private(set) var bluemixRegion: String?
    
    /// Specifies the backend application id
    public private(set) var bluemixAppGUID: String?
        
    /// Specifies the default timeout (in seconds) for all BMS network requests.
    public var defaultRequestTimeout: Double = 20.0
    
    
	public var authorizationManager: AuthorizationManager
	
    // MARK: Initializers
    
    /**
        The required intializer for the `BMSClient` class.
    
        Sets the base URL for the authorization server.
    
        - Note: The `backendAppRoute` and `backendAppGUID` parameters are not required to use the `BMSAnalytics` framework.

        - parameter backendAppRoute:           The base URL for the authorization server
        - parameter backendAppGUID:            The GUID of the Bluemix application
        - parameter bluemixRegion:          The region where your Bluemix application is hosted. Use one of the `BMSClient.REGION` constants.
     */
    public func initializeWithBluemixAppRoute(bluemixAppRoute: String?, bluemixAppGUID: String?, bluemixRegion: String) {
        self.bluemixAppRoute = bluemixAppRoute
        self.bluemixAppGUID = bluemixAppGUID
        self.bluemixRegion = bluemixRegion	
    }
    
	private init() {
		self.authorizationManager = BaseAuthorizationManager()
	} // Prevent users from using BMSClient() initializer - They must use BMSClient.sharedInstance
    
}
