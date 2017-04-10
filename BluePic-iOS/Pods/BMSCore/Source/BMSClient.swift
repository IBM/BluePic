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
    A singleton that serves as the entry point to Bluemix client-server communication.
*/
public class BMSClient {
    
    
    // MARK: - Constants
    
    /**
        The region where your Bluemix service is hosted.
    */
    public struct Region {
        
        
        /**
            The southern United States Bluemix region.
 
            - note: Use this in the `BMSClient.initialize(bluemixAppRoute:bluemixAppGUID:bluemixRegion:)` method.
         */
        public static let usSouth = ".ng.bluemix.net"
        
        /** 
            The United Kingdom Bluemix region.
         
            - note: Use this in the `BMSClient.initialize(bluemixAppRoute:bluemixAppGUID:bluemixRegion:)` method.
         */
        public static let unitedKingdom = ".eu-gb.bluemix.net"
        
        /**
            The Sydney Bluemix region.
 
            - note: Use this in the `BMSClient.initialize(bluemixAppRoute:bluemixAppGUID:bluemixRegion:)` method.
         */
        public static let sydney = ".au-syd.bluemix.net"
    }
    
    

    // MARK: - Properties
    
    /// The singleton that is used for all `BMSClient` activity.
    public static let sharedInstance = BMSClient()
    
    /// Specifies the base Bluemix application backend URL.
    public private(set) var bluemixAppRoute: String?
    
    /// Specifies the region where the Bluemix service is hosted.
    public private(set) var bluemixRegion: String?
    
    /// Specifies the Bluemix application backend identifier.
    public private(set) var bluemixAppGUID: String?
    
    /// Specifies the allowed timeout (in seconds) for all `Request` network requests.
    public var requestTimeout: Double = 20.0
    
    
    
    // MARK: - Properties (internal)
    
    // Handles the authentication process for network requests.
	public var authorizationManager: AuthorizationManager
	
    
    
    // MARK: - Initializer
    
    /**
        The required intializer for the `BMSClient` class.
     
        Call this method on `BMSClient.sharedInstance`.

        - Note: The `backendAppRoute` and `backendAppGUID` parameters are not required; they are only used for making network requests to the Bluemix server using the `Request` class.

        - parameter backendAppRoute:           (Optional) The base URL for the authorization server.
        - parameter backendAppGUID:            (Optional) The GUID of the Bluemix application.
        - parameter bluemixRegion:             The region where your Bluemix application is hosted. Use one of the `BMSClient.Region` constants.
    */
    public func initialize(bluemixAppRoute: String? = nil, bluemixAppGUID: String? = nil, bluemixRegion: String...) {
        
        self.bluemixAppRoute = bluemixAppRoute
        self.bluemixAppGUID = bluemixAppGUID
        self.bluemixRegion = bluemixRegion[0]
    }
    
    
    // Prevent users from using BMSClient() initializer - They must use BMSClient.sharedInstance
	private init() {
		self.authorizationManager = BaseAuthorizationManager()
	}

}





/**************************************************************************************************/





// MARK: - Swift 2

#else



/**
    A singleton that serves as the entry point to Bluemix client-server communication.
*/
public class BMSClient {
    
    
    // MARK: - Constants
    
    /**
        The region where your Bluemix service is hosted.
    */
    public struct Region {
    
    
        /**
             The southern United States Bluemix region.
             
             - note: Use this in the `BMSClient.initialize(bluemixAppRoute:bluemixAppGUID:bluemixRegion:)` method.
         */
        public static let usSouth = ".ng.bluemix.net"
        
        /**
             The United Kingdom Bluemix region.
             
             - note: Use this in the `BMSClient.initialize(bluemixAppRoute:bluemixAppGUID:bluemixRegion:)` method.
         */
        public static let unitedKingdom = ".eu-gb.bluemix.net"
    
        /**
             The Sydney Bluemix region.
             
             - note: Use this in the `BMSClient.initialize(bluemixAppRoute:bluemixAppGUID:bluemixRegion:)` method.
         */
        public static let sydney = ".au-syd.bluemix.net"
    }
    
    
    
    // MARK: - Properties
    
    /// The singleton that is used for all `BMSClient` activity.
    public static let sharedInstance = BMSClient()
    
    /// Specifies the base Bluemix application backend URL.
    public private(set) var bluemixAppRoute: String?
    
    /// Specifies the region where the Bluemix service is hosted.
    public private(set) var bluemixRegion: String?
    
    /// Specifies the Bluemix application backend identifier.
    public private(set) var bluemixAppGUID: String?
    
    /// Specifies the allowed timeout (in seconds) for all `Request` network requests.
    public var requestTimeout: Double = 20.0
    
    
    
    // MARK: - Properties (internal)
    
    // Handles the authentication process for network requests.
    public var authorizationManager: AuthorizationManager
    
    
    
    // MARK: - Initializer
    
    /**
        The required intializer for the `BMSClient` class.

        Call this method on `BMSClient.sharedInstance`.

        - Note: The `backendAppRoute` and `backendAppGUID` parameters are not required; they are only used for making network requests to the Bluemix server using the `Request` class.

        - parameter backendAppRoute:           (Optional) The base URL for the authorization server.
        - parameter backendAppGUID:            (Optional) The GUID of the Bluemix application.
        - parameter bluemixRegion:             The region where your Bluemix application is hosted. Use one of the `BMSClient.Region` constants.
    */
    public func initialize(bluemixAppRoute bluemixAppRoute: String? = nil, bluemixAppGUID: String? = nil, bluemixRegion: String...) {
    
        self.bluemixAppRoute = bluemixAppRoute
        self.bluemixAppGUID = bluemixAppGUID
        self.bluemixRegion = bluemixRegion[0]
    }
    
    
    // Prevent users from using BMSClient() initializer - They must use BMSClient.sharedInstance
    private init() {
        self.authorizationManager = BaseAuthorizationManager()
    }
    
}



#endif
