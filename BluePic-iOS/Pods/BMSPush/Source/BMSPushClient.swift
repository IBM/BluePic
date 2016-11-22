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


import UIKit
import BMSCore

#if swift(>=3.0)
    
    /**
     Used in the `BMSPushClient` class, the `IMFPushErrorvalues` denotes error in the requests.
     */
    public enum IMFPushErrorvalues: Int {
        
        /// - IMFPushErrorInternalError: Denotes the Internal Server Error occured.
        case IMFPushErrorInternalError = 1
        
        /// - IMFPushErrorEmptyTagArray: Denotes the Empty Tag Array Error.
        case IMFPushErrorEmptyTagArray = 2
        
        /// - IMFPushRegistrationVerificationError: Denotes the Previous Push registration Error.
        case IMFPushRegistrationVerificationError = 3
        
        /// - IMFPushRegistrationError: Denotes the First Time Push registration Error.
        case IMFPushRegistrationError = 4
        
        /// - IMFPushRegistrationUpdateError: Denotes the Device updation Error.
        case IMFPushRegistrationUpdateError = 5
        
        /// - IMFPushRetrieveSubscriptionError: Denotes the Subscribed tags retrieval error.
        case IMFPushRetrieveSubscriptionError = 6
        
        /// - IMFPushRetrieveSubscriptionError: Denotes the Available tags retrieval error.
        case IMFPushRetrieveTagsError = 7
        
        /// - IMFPushTagSubscriptionError: Denotes the Tag Subscription error.
        case IMFPushTagSubscriptionError = 8
        
        /// - IMFPushTagUnsubscriptionError: Denotes the tag Unsubscription error.
        case IMFPushTagUnsubscriptionError = 9
        
        /// - BMSPushUnregitrationError: Denotes the Push Unregistration error.
        case BMSPushUnregitrationError = 10
    }
    
    
    /**
     A singleton that serves as an entry point to Bluemix client- Push service communication.
     */
    public class BMSPushClient: NSObject {
        
        // MARK: Properties (Public)
        
        /// This singleton should be used for all `BMSPushClient` activity.
        public static let sharedInstance = BMSPushClient()
        
        // Specifies the bluemix push clientSecret value
        public private(set) var clientSecret: String?
        public private(set) var applicationId: String?
        
        // used to test in test zone and dev zone
        public static var overrideServerHost = "";
        
        // MARK: Properties (private)
        
        /// `BMSClient` object.
        private var bmsClient = BMSClient.sharedInstance
        
        // Notification Count
        
        private var notificationcount:Int = 0
        
        private var isInitialized = false;
        
        // MARK: Initializers
        
        /**
         The required intializer for the `BMSPushClient` class.
         
         This method will intialize the BMSPushClient with clientSecret based registration.
         
         - parameter clientSecret:    The clientSecret of the Push Service
         - parameter appGUID:    The pushAppGUID of the Push Service
         */
        public func initializeWithAppGUID (appGUID: String, clientSecret: String) {
            
            if validateString(object: clientSecret) {
                self.clientSecret = clientSecret
                self.applicationId = appGUID
                isInitialized = true;
            }
            else{
                self.sendAnalyticsData(logType: LogLevel.error, logStringData: "Error while registration - Client secret is not valid")
                print("Error while registration - Client secret is not valid")
            }
        }
        
        /**
         The required intializer for the `BMSPushClient` class.
         
         This method will intialize the BMSPushClient.
         
         - parameter appGUID:    The pushAppGUID of the Push Service
         */
        @available(*, deprecated, message: "This method was deprecated , please use initializeWithAppGUID(appGUID:_  clientSecret:_ )")
        public func initializeWithAppGUID (appGUID: String) {
            self.applicationId = appGUID;
            isInitialized = true;
        }
        
        
        // MARK: Methods (Public)
        
        //TODO: New method of device registraion with UsrId
        
        /**
         
         This Methode used to register the client device to the Bluemix Push service. This is the normal registration, without userId.
         
         Call this methode after successfully registering for remote push notification in the Apple Push
         Notification Service .
         
         - Parameter deviceToken: This is the response we get from the push registartion in APNS.
         - Parameter WithUserId: This is the userId value.
         - Parameter completionHandler: The closure that will be called when this request finishes. The response will contain response (String), StatusCode (Int) and error (string).
         */
        
        public func registerWithDeviceToken(deviceToken:Data , WithUserId:String?, completionHandler: @escaping(_ response:String?, _ statusCode:Int?, _ error:String) -> Void) {
            
            
            if (isInitialized){
                if (validateString(object: WithUserId!)){
                    
                    // Generate new ID
                    // TODO: This need to be verified. The Device Id is not storing anywhere in BMSCore
                    
                    var devId = String()
                    let authManager  = BMSClient.sharedInstance.authorizationManager
                    devId = authManager.deviceIdentity.ID!
                    BMSPushUtils.saveValueToNSUserDefaults(value: devId, key: "deviceId")
                    
                    var token = ""
                    for i in 0..<deviceToken.count {
                        token = token + String(format: "%02.2hhx", arguments: [deviceToken[i]])
                    }
                    
                    let urlBuilder = BMSPushUrlBuilder(applicationID: applicationId!,clientSecret:clientSecret!)
                    
                    let resourceURL:String = urlBuilder.getSubscribedDevicesUrl(devID: devId)
                    let headers = urlBuilder.addHeader()
                    
                    let method =  HttpMethod.GET
                    
                    self.sendAnalyticsData(logType: LogLevel.debug, logStringData: "Verifying previous device registration.")
                    let getRequest = Request(url: resourceURL, method: method, headers: headers, queryParameters: nil, timeout: 60)
                    
                    // MARK: FIrst Action, checking for previuos registration
                    
                    getRequest.send(completionHandler: { (response, error)  -> Void in
                        
                        if response?.statusCode != nil {
                            
                            let status = response?.statusCode ?? 0
                            let responseText = response?.responseText ?? ""
                            
                            
                            if (status == 404) {
                                
                                self.sendAnalyticsData(logType: LogLevel.debug, logStringData: "Device is not registered before.  Registering for the first time.")
                                let resourceURL:String = urlBuilder.getDevicesUrl()
                                
                                let headers = urlBuilder.addHeader()
                                
                                let method =  HttpMethod.POST
                                
                                let getRequest = BaseRequest(url: resourceURL, method: method, headers: headers, queryParameters: nil, timeout: 60)
                                
                                let data =  "{\"\(IMFPUSH_DEVICE_ID)\": \"\(devId)\", \"\(IMFPUSH_TOKEN)\": \"\(token)\", \"\(IMFPUSH_PLATFORM)\": \"A\", \"\(IMFPUSH_USERID)\": \"\(WithUserId!)\"}".data(using: .utf8)
                                // MARK: Registering for the First Time
                                
                                 getRequest.send(requestBody: data!, completionHandler: { (response, error) -> Void in
                                    
                                    if response?.statusCode != nil {
                                        
                                        let status = response?.statusCode ?? 0
                                        let responseText = response?.responseText ?? ""
                                        
                                        self.sendAnalyticsData(logType: LogLevel.info, logStringData: "Response of device registration - Response is: \(responseText)")
                                        completionHandler(responseText, status, "")
                                        
                                    }
                                    else if let responseError = error {
                                        
                                        self.sendAnalyticsData(logType: LogLevel.error, logStringData: "Error during device registration - Error is: \(responseError.localizedDescription)")
                                        completionHandler("", IMFPushErrorvalues.IMFPushRegistrationError.rawValue, "Error during device registration - Error is: \(responseError.localizedDescription)")
                                    }
                                })
                                
                            }
                            else if (status == 406) || (status == 500) {
                                
                                self.sendAnalyticsData(logType: LogLevel.error, logStringData: "Error while verifying previous registration - Error is: \(error!.localizedDescription)")
                                 completionHandler(responseText, status, "")
                            }
                            else {
                                
                                // MARK: device is already Registered
                                
                                self.sendAnalyticsData(logType: LogLevel.debug, logStringData: "Device is already registered. Return the device Id - Response is: \(response?.responseText)")
                                let respJson = response?.responseText
                                let data = respJson!.data(using: String.Encoding.utf8)
                                let jsonResponse:NSDictionary = try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
                                
                                let rToken = jsonResponse.object(forKey: IMFPUSH_TOKEN) as! String
                                let rDevId = jsonResponse.object(forKey: IMFPUSH_DEVICE_ID) as! String
                                let userId = jsonResponse.object(forKey: IMFPUSH_USERID) as! String
                                
                                if ((rToken.compare(token)) != ComparisonResult.orderedSame) ||
                                    (!(WithUserId!.isEmpty) && (WithUserId!.compare(userId) != ComparisonResult.orderedSame)) || (devId.compare(rDevId) != ComparisonResult.orderedSame){
                                    
                                    // MARK: Updating the registered device ,userID, token or deviceId changed
                                    
                                    self.sendAnalyticsData(logType: LogLevel.debug, logStringData: "Device token or DeviceId has changed. Sending update registration request.")
                                    let resourceURL:String = urlBuilder.getSubscribedDevicesUrl(devID: devId)
                                    
                                    let headers = urlBuilder.addHeader()
                                    
                                    let method =  HttpMethod.PUT
                                    
                                    let getRequest = BaseRequest(url: resourceURL, method: method, headers: headers, queryParameters: nil, timeout: 60)
                                    
                                    let data =  "{\"\(IMFPUSH_DEVICE_ID)\": \"\(devId)\", \"\(IMFPUSH_TOKEN)\": \"\(token)\", \"\(IMFPUSH_USERID)\": \"\(WithUserId!)\"}".data(using: .utf8)
                                    
                                    
                                    getRequest.send(requestBody: data!, completionHandler: { (response, error) -> Void in
                                        
                                        if response?.statusCode != nil  {
                                            
                                            let status = response?.statusCode ?? 0
                                            let responseText = response?.responseText ?? ""
                                            
                                            self.sendAnalyticsData(logType: LogLevel.info, logStringData: "Response of device updation - Response is: \(responseText)")
                                            completionHandler(responseText, status, "")
                                        }
                                        else if let responseError = error {
                                            
                                            self.sendAnalyticsData(logType: LogLevel.error, logStringData: "Error during device updatation - Error is : \(responseError.localizedDescription)")
                                            completionHandler("", IMFPushErrorvalues.IMFPushRegistrationUpdateError.rawValue, "Error during device updatation - Error is : \(responseError.localizedDescription)")
                                        }
                                    })
                                }
                                else {
                                    // MARK: device already registered and parameteres not changed.
                                    
                                    self.sendAnalyticsData(logType: LogLevel.info, logStringData: "Device is already registered and device registration parameters not changed.")
                                    completionHandler(response?.responseText, status, "")
                                }
                            }
                            
                        }
                        else if let responseError = error {
                            
                            self.sendAnalyticsData(logType: LogLevel.error, logStringData: "Error while verifying previous registration - Error is: \(responseError.localizedDescription)")
                            completionHandler("", IMFPushErrorvalues.IMFPushRegistrationVerificationError.rawValue , "Error while verifying previous registration - Error is: \(responseError.localizedDescription)")
                            
                        }
                        
                    })
                }else{
                    
                    self.sendAnalyticsData(logType: LogLevel.error, logStringData: "Error while registration - Provide a valid userId value")
                    completionHandler("", IMFPushErrorvalues.IMFPushRegistrationError.rawValue , "Error while registration - Provide a valid userId value")
                }
            }else{
                
                self.sendAnalyticsData(logType: LogLevel.error, logStringData: "Error while registration - BMSPush is not initialized")
                completionHandler("", IMFPushErrorvalues.IMFPushRegistrationError.rawValue , "Error while registration - BMSPush is not initialized")
            }
            
        }
        
        
        /**
         
         This Methode used to register the client device to the Bluemix Push service. This is the normal registration, without userId.
         
         Call this methode after successfully registering for remote push notification in the Apple Push
         Notification Service .
         
         - Parameter deviceToken: This is the response we get from the push registartion in APNS.
         - Parameter completionHandler: The closure that will be called when this request finishes. The response will contain response (String), StatusCode (Int) and error (string).
         */
        
        public func registerWithDeviceToken (deviceToken:Data, completionHandler: @escaping(_ response:String?, _ statusCode:Int?, _ error:String) -> Void) {
            
            // Generate new ID
            // TODO: This need to be verified. The Device Id is not storing anywhere in BMSCore
            
            if (isInitialized){
                var devId = String()
                let authManager  = BMSClient.sharedInstance.authorizationManager
                devId = authManager.deviceIdentity.ID!
                BMSPushUtils.saveValueToNSUserDefaults(value: devId, key: "deviceId")
                
                var token = ""
                for i in 0..<deviceToken.count {
                    token = token + String(format: "%02.2hhx", arguments: [deviceToken[i]])
                }
                
                
                let urlBuilder = BMSPushUrlBuilder(applicationID: applicationId!,clientSecret:clientSecret!)
                
                let resourceURL:String = urlBuilder.getSubscribedDevicesUrl(devID: devId)
                let headers = urlBuilder.addHeader()
                
                let method =  HttpMethod.GET
    
                self.sendAnalyticsData(logType: LogLevel.debug, logStringData: "Verifying previous device registration.")
                let getRequest = Request(url: resourceURL, method: method, headers: headers, queryParameters: nil, timeout: 60)
                
                // MARK: FIrst Action, checking for previuos registration
                getRequest.send(completionHandler: { (response, error)  -> Void in
                    
                    if response?.statusCode != nil {
                        
                        let status = response?.statusCode ?? 0
                        let responseText = response?.responseText ?? ""
                        
                        
                        if (status == 404) {
                            
                            self.sendAnalyticsData(logType: LogLevel.debug, logStringData: "Device is not registered before.  Registering for the first time.")
                            let resourceURL:String = urlBuilder.getDevicesUrl()
                            
                            let headers = urlBuilder.addHeader()
                            
                            let method =  HttpMethod.POST
                            
                            let getRequest = BaseRequest(url: resourceURL, method: method, headers: headers, queryParameters: nil, timeout: 60)
                            
                            let data =  "{\"\(IMFPUSH_DEVICE_ID)\": \"\(devId)\", \"\(IMFPUSH_TOKEN)\": \"\(token)\", \"\(IMFPUSH_PLATFORM)\": \"A\"}".data(using: .utf8)
                            
                            
                            // MARK: Registering for the First Time
                            
                            getRequest.send(requestBody: data!, completionHandler: { (response, error)  -> Void in
                                
                                if response?.statusCode != nil {
                                    
                                    let status = response?.statusCode ?? 0
                                    let responseText = response?.responseText ?? ""
                                    
                                    self.sendAnalyticsData(logType: LogLevel.info, logStringData: "Response of device registration - Response is: \(responseText)")
                                    completionHandler(responseText, status, "")
                                    
                                }
                                else if let responseError = error {
                                    
                                    self.sendAnalyticsData(logType: LogLevel.error, logStringData: "Error during device registration - Error is: \(responseError.localizedDescription)")
                                    completionHandler("", IMFPushErrorvalues.IMFPushRegistrationError.rawValue, "Error during device registration - Error is: \(responseError.localizedDescription)")
                                }
                            })
                            
                        }
                        else if (status == 406) || (status == 500) {
                            
                            self.sendAnalyticsData(logType: LogLevel.error, logStringData: "Error while verifying previous registration - Error is: \(error!.localizedDescription)")
                            completionHandler(responseText, status, "")
                        }
                        else {
                            
                            // MARK: device is already Registered
                            
                            self.sendAnalyticsData(logType: LogLevel.debug, logStringData: "Device is already registered. Return the device Id - Response is: \(response?.responseText)")
                            let respJson = response?.responseText
                            let data = respJson!.data(using: String.Encoding.utf8)
                            let jsonResponse:NSDictionary = try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
                            
                            let rToken = jsonResponse.object(forKey: IMFPUSH_TOKEN) as! String
                            let rDevId = jsonResponse.object(forKey: IMFPUSH_DEVICE_ID) as! String
                            let userId = jsonResponse.object(forKey: IMFPUSH_USERID) as! String
                            
                            if ((rToken.compare(token)) != ComparisonResult.orderedSame) || (devId.compare(rDevId) != ComparisonResult.orderedSame) || (userId != "anonymous") {
                                
                                // MARK: Updating the registered userID , token or deviceId changed
                                
                                self.sendAnalyticsData(logType: LogLevel.debug, logStringData: "Device token or DeviceId has changed. Sending update registration request.")
                                let resourceURL:String = urlBuilder.getSubscribedDevicesUrl(devID: devId)
                                
                                let headers = urlBuilder.addHeader()
                                
                                let method =  HttpMethod.PUT
                                
                                let getRequest = BaseRequest(url: resourceURL, method: method, headers: headers, queryParameters: nil, timeout: 60)
                               
                                let data =  "{\"\(IMFPUSH_DEVICE_ID)\": \"\(devId)\", \"\(IMFPUSH_TOKEN)\": \"\(token)\"}".data(using: .utf8)
                                
                                getRequest.send(requestBody: data!, completionHandler: { (response, error)  -> Void in
                                    
                                    if response?.statusCode != nil  {
                                        
                                        let status = response?.statusCode ?? 0
                                        let responseText = response?.responseText ?? ""
                                        
                                        self.sendAnalyticsData(logType: LogLevel.info, logStringData: "Response of device updation - Response is: \(responseText)")
                                       completionHandler(responseText, status, "")
                                    }
                                    else if let responseError = error {
                                        
                                        self.sendAnalyticsData(logType: LogLevel.error, logStringData: "Error during device updatation - Error is : \(responseError.localizedDescription)")
                                        completionHandler("", IMFPushErrorvalues.IMFPushRegistrationUpdateError.rawValue, "Error during device updatation - Error is : \(responseError.localizedDescription)")
                                    }
                                })
                            }
                            else {
                                // MARK: device already registered and parameteres not changed.
                                
                                self.sendAnalyticsData(logType: LogLevel.info, logStringData: "Device is already registered and device registration parameters not changed.")
                                completionHandler(response?.responseText, status, "")
                            }
                        }
                    }
                    else if let responseError = error {
                        
                        self.sendAnalyticsData(logType: LogLevel.error, logStringData: "Error while verifying previous registration - Error is: \(responseError.localizedDescription)")
                        completionHandler("", IMFPushErrorvalues.IMFPushRegistrationVerificationError.rawValue , "Error while verifying previous registration - Error is: \(responseError.localizedDescription)")
                    }
                })
            }else{
                
                self.sendAnalyticsData(logType: LogLevel.error, logStringData: "Error while registration - BMSPush is not initialized")
               completionHandler("", IMFPushErrorvalues.IMFPushRegistrationError.rawValue , "Error while registration - BMSPush is not initialized")
            }
        }
        

        
        /**
         
         This Method used to Retrieve all the available Tags in the Bluemix Push Service.
         
         This methode will return the list of available Tags in an Array.
         
         - Parameter completionHandler: The closure that will be called when this request finishes. The response will contain response (NSMutableArray), StatusCode (Int) and error (string).
         */
        public func retrieveAvailableTagsWithCompletionHandler (completionHandler: @escaping(_ response:NSMutableArray?, _ statusCode:Int?, _ error:String) -> Void){
            
            
            self.sendAnalyticsData(logType: LogLevel.debug, logStringData: "Entering retrieveAvailableTagsWithCompletitionHandler.")
            let urlBuilder = BMSPushUrlBuilder(applicationID: applicationId!,clientSecret:clientSecret!)
            
            let resourceURL:String = urlBuilder.getTagsUrl()
            
            let headers = urlBuilder.addHeader()
           
            let method =  HttpMethod.GET
            
            let getRequest = Request(url: resourceURL, method: method, headers: headers, queryParameters: nil, timeout: 60)
            
            getRequest.send(completionHandler:{ (response, error) -> Void in
                
                
                if response?.statusCode != nil {
                    
                    let status = response?.statusCode ?? 0
                    let responseText = response?.responseText ?? ""
                    
                    self.sendAnalyticsData(logType: LogLevel.info, logStringData: "Successfully retrieved available tags - Response is: \(responseText)")
                    let availableTagsArray = response?.availableTags()
                    
                    completionHandler(availableTagsArray, status, "")
                } else if let responseError = error {
                    
                    self.sendAnalyticsData(logType: LogLevel.error, logStringData: "Error while retrieving available tags - Error is: \(responseError.localizedDescription)")
                    completionHandler([], IMFPushErrorvalues.IMFPushRetrieveTagsError.rawValue,"Error while retrieving available tags - Error is: \(responseError.localizedDescription)")
                    
                }
            })
        }
        
        /**
         
         This Methode used to Subscribe to the Tags in the Bluemix Push srvice.
         
         
         This methode will return the list of subscribed tags. If you pass the tags that are not present in the Bluemix App it will be classified under the TAGS NOT FOUND section in the response.
         
         - parameter tagsArray: the array that contains name tags.
         - Parameter completionHandler: The closure that will be called when this request finishes. The response will contain response (NSMutableDictionary), StatusCode (Int) and error (string).
         */
        public func subscribeToTags (tagsArray:NSArray, completionHandler: @escaping (_ response:NSMutableDictionary?, _ statusCode:Int?, _ error:String) -> Void) {
            
            
            self.sendAnalyticsData(logType: LogLevel.debug, logStringData:"Entering: subscribeToTags." )
            
            if tagsArray.count != 0 {
                
                let authManager  = BMSClient.sharedInstance.authorizationManager
                let devId = authManager.deviceIdentity.ID!
                
                
                let urlBuilder = BMSPushUrlBuilder(applicationID: applicationId!,clientSecret:clientSecret!)
                let resourceURL:String = urlBuilder.getSubscriptionsUrl()
                
                let headers = urlBuilder.addHeader()
                
                let method =  HttpMethod.POST
                
                let getRequest = BaseRequest(url: resourceURL, method: method, headers: headers, queryParameters: nil, timeout: 60)
                
                let mappedArray = tagsArray.flatMap{"\($0)"}.description;
                
                let data =  "{\"\(IMFPUSH_TAGNAMES)\":\(mappedArray), \"\(IMFPUSH_DEVICE_ID)\":\"\(devId)\"}".data(using: .utf8)
                
                getRequest.send(requestBody: data!, completionHandler: { (response, error) -> Void in
                    
                    if response?.statusCode != nil {
                        
                        let status = response?.statusCode ?? 0
                        let responseText = response?.responseText ?? ""
                        
                        self.sendAnalyticsData(logType: LogLevel.info, logStringData: "Successfully subscribed to tags - Response is: \(responseText)")
                        let subscriptionResponse = response?.subscribeStatus()
                        
                        completionHandler(subscriptionResponse, status, "")
                        
                    } else if let responseError = error {
                        
                        let subscriptionResponse = NSMutableDictionary()
                        
                        self.sendAnalyticsData(logType: LogLevel.error, logStringData: "Error while subscribing to tags - Error is: \(responseError.localizedDescription)")
                        completionHandler(subscriptionResponse, IMFPushErrorvalues.IMFPushTagSubscriptionError.rawValue,"Error while retrieving available tags - Error is: \(responseError.localizedDescription)")
                        
                    }
                })
                
            } else {
                
                let subscriptionResponse = NSMutableDictionary()
                
                self.sendAnalyticsData(logType: LogLevel.error, logStringData: "Error.  Tag array cannot be null. Create tags in your Bluemix App")
                completionHandler(subscriptionResponse, IMFPushErrorvalues.IMFPushErrorEmptyTagArray.rawValue, "Error.  Tag array cannot be null. Create tags in your Bluemix App")
            }
        }
        
        
        /**
         
         This Methode used to Retrieve the Subscribed Tags in the Bluemix Push srvice.
         
         
         This methode will return the list of subscribed tags.
         
         - Parameter completionHandler: The closure that will be called when this request finishes. The response will contain response (NSMutableArray), StatusCode (Int) and error (string).
         */
        public func retrieveSubscriptionsWithCompletionHandler  (completionHandler: @escaping (_ response:NSMutableArray?, _ statusCode:Int?, _ error:String) -> Void) {
            
            
            self.sendAnalyticsData(logType: LogLevel.debug, logStringData: "Entering retrieveSubscriptionsWithCompletitionHandler.")
            
            let authManager  = BMSClient.sharedInstance.authorizationManager
            let devId = authManager.deviceIdentity.ID!
            
            
            let urlBuilder = BMSPushUrlBuilder(applicationID: applicationId!,clientSecret:clientSecret!)
            let resourceURL:String = urlBuilder.getAvailableSubscriptionsUrl(deviceId: devId)
            
            let headers = urlBuilder.addHeader()
            
            let method =  HttpMethod.GET
            
            let getRequest = Request(url: resourceURL, method: method, headers: headers, queryParameters: nil, timeout: 60)
            
            getRequest.send(completionHandler: { (response, error) -> Void in
                
                
                
                if response?.statusCode != nil {
                    
                    let status = response?.statusCode ?? 0
                    let responseText = response?.responseText ?? ""
                    
                    self.sendAnalyticsData(logType: LogLevel.info, logStringData: "Subscription retrieved successfully - Response is: \(responseText)")
                    let subscriptionArray = response?.subscriptions()
                    
                    completionHandler(subscriptionArray, status, "")
                    
                } else if let responseError = error {
                    
                    self.sendAnalyticsData(logType: LogLevel.error, logStringData: "Error while retrieving subscriptions - Error is: \(responseError.localizedDescription)")
                    
                    completionHandler([], IMFPushErrorvalues.IMFPushRetrieveSubscriptionError.rawValue,"Error while retrieving subscriptions - Error is: \(responseError.localizedDescription)")
                    
                }
            })
        }
        
        /**
         
         This Methode used to Unsubscribe from the Subscribed Tags in the Bluemix Push srvice.
         
         
         This methode will return the details of Unsubscription status.
         
         - Parameter tagsArray: The list of tags that need to be unsubscribed.
         - Parameter completionHandler: The closure that will be called when this request finishes. The response will contain response (NSMutableDictionary), StatusCode (Int) and error (string).
         */
        public func unsubscribeFromTags (tagsArray:NSArray, completionHandler: @escaping (_ response:NSMutableDictionary?, _ statusCode:Int?, _ error:String) -> Void) {
            
            self.sendAnalyticsData(logType: LogLevel.debug, logStringData: "Entering: unsubscribeFromTags")
            
            if tagsArray.count != 0 {
                
                
                let authManager  = BMSClient.sharedInstance.authorizationManager
                let devId = authManager.deviceIdentity.ID!
                
                
                let urlBuilder = BMSPushUrlBuilder(applicationID: applicationId!,clientSecret:clientSecret!)
                let resourceURL:String = urlBuilder.getUnSubscribetagsUrl()
                
                let headers = urlBuilder.addHeader()
                
                let method =  HttpMethod.POST
                
                let getRequest = BaseRequest(url: resourceURL, method: method, headers: headers, queryParameters: nil, timeout: 60)
                
                let mappedArray = tagsArray.flatMap{"\($0)"}.description;
                
                let data =  "{\"\(IMFPUSH_TAGNAMES)\":\(mappedArray), \"\(IMFPUSH_DEVICE_ID)\":\"\(devId)\"}".data(using: .utf8)
                
                getRequest.send(requestBody: data!, completionHandler: { (response, error)  -> Void in
                    
                    if response?.statusCode != nil {
                        
                        let status = response?.statusCode ?? 0
                        let responseText = response?.responseText ?? ""
                        
                        self.sendAnalyticsData(logType: LogLevel.info, logStringData: "Successfully unsubscribed from tags - Response is: \(responseText)")
                        let unSubscriptionResponse = response?.unsubscribeStatus()
                        
                        completionHandler(unSubscriptionResponse, status, "")
                        
                    } else if let responseError = error{
                        
                        let unSubscriptionResponse = NSMutableDictionary()
                        
                        self.sendAnalyticsData(logType: LogLevel.error, logStringData: "Error while unsubscribing from tags - Error is: \(responseError.localizedDescription)")
                        completionHandler(unSubscriptionResponse, IMFPushErrorvalues.IMFPushTagUnsubscriptionError.rawValue,"Error while retrieving available tags - Error is: \(responseError.localizedDescription)")
                    }
                })
            } else {
                
                let unSubscriptionResponse = NSMutableDictionary()
                
                self.sendAnalyticsData(logType: LogLevel.error, logStringData: "Error.  Tag array cannot be null.")
                completionHandler(unSubscriptionResponse, IMFPushErrorvalues.IMFPushErrorEmptyTagArray.rawValue, "Error.  Tag array cannot be null.")
            }
        }
        
        /**
         
         This Methode used to UnRegister the client App from the Bluemix Push srvice.
         
         
         - Parameter completionHandler: The closure that will be called when this request finishes. The response will contain response (String), StatusCode (Int) and error (string).
         */
        public func unregisterDevice  (completionHandler: @escaping (_ response:String?, _ statusCode:Int?, _ error:String) -> Void) {
            
            self.sendAnalyticsData(logType: LogLevel.debug, logStringData: "Entering unregisterDevice.")
            let authManager  = BMSClient.sharedInstance.authorizationManager
            let devId = authManager.deviceIdentity.ID!
            
            
            let urlBuilder = BMSPushUrlBuilder(applicationID: applicationId!,clientSecret:clientSecret!)
            let resourceURL:String = urlBuilder.getUnregisterUrl(deviceId: devId)
            
            let headers = urlBuilder.addHeader()
            
            let method =  HttpMethod.DELETE
            
            let getRequest = Request(url: resourceURL, method: method, headers: headers, queryParameters: nil, timeout: 60)
            
            
            getRequest.send(completionHandler: { (response, error) -> Void in
                
                if response?.statusCode != nil {
                    
                    let status = response?.statusCode ?? 0
                    let responseText = response?.responseText ?? ""
                    
                    self.sendAnalyticsData(logType: LogLevel.info, logStringData: "Successfully unregistered the device. - Response is: \(response?.responseText)")
                    
                    completionHandler(responseText, status, "")
                    
                } else if let responseError = error  {
                    
                    self.sendAnalyticsData(logType: LogLevel.error, logStringData: "Error while unregistering device - Error is: \(responseError.localizedDescription)")
                    completionHandler("", IMFPushErrorvalues.BMSPushUnregitrationError.rawValue,"Error while unregistering device - Error is: \(responseError.localizedDescription)")
                }
            })
        }
        
        public func sendMessageDeliveryStatus (messageId:String, status:String){
            
            
            self.sendAnalyticsData(logType: LogLevel.debug, logStringData: "Entering sendMessageDeliveryStatus.")
            let authManager  = BMSClient.sharedInstance.authorizationManager
            let devId = authManager.deviceIdentity.ID!
            
            
            let urlBuilder = BMSPushUrlBuilder(applicationID: applicationId!,clientSecret:clientSecret!)
            let resourceURL:String = urlBuilder.getSendMessageDeliveryStatus(messageId: messageId)
            
            let headers = urlBuilder.addHeader()
            
            let method =  HttpMethod.PUT
            
            let data =  "{\"\(IMFPUSH_DEVICE_ID)\":\"\(devId)\", \"\(IMFPUSH_STATUS)\":OPEN}".data(using: .utf8)
            
            let getRequest = Request(url: resourceURL, method: method, headers: headers, queryParameters: nil, timeout: 60)
            
            getRequest.send(requestBody: data!, completionHandler: { (response, error)  -> Void in
                
                if response?.statusCode != nil {
                    
                    let responseText = response?.responseText ?? ""
                    
                    self.sendAnalyticsData(logType: LogLevel.info, logStringData: "Successfully updated the message status.  The response is: \(responseText)")
                    print("Successfully updated the message status.  The response is: "+responseText)
                    
                } else if let responseError = error{
                    
                    
                    self.sendAnalyticsData(logType: LogLevel.error, logStringData: "Failed to update the message status.  The response is:  \(responseError.localizedDescription)")
                    print("Failed to update the message status.  The response is: "+responseError.localizedDescription)
                    
                    
                }
            })
        }
        
        // MARK: Methods (Internal)
        
        //Begin Logger implementation
    
        
        // Setting Log info
        internal func sendAnalyticsData (logType:LogLevel, logStringData:String){
            var devId = String()
            let authManager  = BMSClient.sharedInstance.authorizationManager
            devId = authManager.deviceIdentity.ID!
            let testLogger = Logger.logger(name:devId)
            if (logType == LogLevel.debug){
                Logger.logLevelFilter = LogLevel.debug
                testLogger.debug(message: logStringData)
            } else if (logType == LogLevel.error){
                Logger.logLevelFilter = LogLevel.error
                testLogger.error(message: logStringData)
            } else if (logType == LogLevel.analytics){
                Logger.logLevelFilter = LogLevel.analytics
                testLogger.debug(message: logStringData)
            } else if (logType == LogLevel.fatal){
                Logger.logLevelFilter = LogLevel.fatal
                testLogger.fatal(message: logStringData)
            } else if (logType == LogLevel.warn){
                Logger.logLevelFilter = LogLevel.warn
                testLogger.warn(message: logStringData)
            } else if (logType == LogLevel.info){
                Logger.logLevelFilter = LogLevel.info
                testLogger.info(message: logStringData)
            }
            else {
                Logger.logLevelFilter = LogLevel.none
                testLogger.debug(message: logStringData)
            }
        }
        
        internal func validateString(object:String) -> Bool{
            if (object.isEmpty || object == "") {
                return false;
            }
            return true
        }
        
    }
    
#else
    
    /**
     Used in the `BMSPushClient` class, the `IMFPushErrorvalues` denotes error in the requests.
     */
    public enum IMFPushErrorvalues: Int {
        
        /// - IMFPushErrorInternalError: Denotes the Internal Server Error occured.
        case IMFPushErrorInternalError = 1
        
        /// - IMFPushErrorEmptyTagArray: Denotes the Empty Tag Array Error.
        case IMFPushErrorEmptyTagArray = 2
        
        /// - IMFPushRegistrationVerificationError: Denotes the Previous Push registration Error.
        case IMFPushRegistrationVerificationError = 3
        
        /// - IMFPushRegistrationError: Denotes the First Time Push registration Error.
        case IMFPushRegistrationError = 4
        
        /// - IMFPushRegistrationUpdateError: Denotes the Device updation Error.
        case IMFPushRegistrationUpdateError = 5
        
        /// - IMFPushRetrieveSubscriptionError: Denotes the Subscribed tags retrieval error.
        case IMFPushRetrieveSubscriptionError = 6
        
        /// - IMFPushRetrieveSubscriptionError: Denotes the Available tags retrieval error.
        case IMFPushRetrieveTagsError = 7
        
        /// - IMFPushTagSubscriptionError: Denotes the Tag Subscription error.
        case IMFPushTagSubscriptionError = 8
        
        /// - IMFPushTagUnsubscriptionError: Denotes the tag Unsubscription error.
        case IMFPushTagUnsubscriptionError = 9
        
        /// - BMSPushUnregitrationError: Denotes the Push Unregistration error.
        case BMSPushUnregitrationError = 10
    }
    
    
    /**
     A singleton that serves as an entry point to Bluemix client- Push service communication.
     */
    public class BMSPushClient: NSObject {
        
        // MARK: Properties (Public)
        
        /// This singleton should be used for all `BMSPushClient` activity.
        public static let sharedInstance = BMSPushClient()
        
        // Specifies the bluemix push clientSecret value
        public private(set) var clientSecret: String?
        public private(set) var applicationId: String?
        
        // used to test in test zone and dev zone
        public static var overrideServerHost = "";
        
        // MARK: Properties (private)
        
        /// `BMSClient` object.
        private var bmsClient = BMSClient.sharedInstance
        
        // Notification Count
        
        private var notificationcount:Int = 0
        
        private var isInitialized = false;
        
        // MARK: Initializers
        
        /**
         The required intializer for the `BMSPushClient` class.
         
         This method will intialize the BMSPushClient with clientSecret based registration.
         
         - parameter clientSecret:    The clientSecret of the Push Service
         - parameter appGUID:    The pushAppGUID of the Push Service
         */
        public func initializeWithAppGUID (appGUID appGUID: String, clientSecret: String) {
            
            if validateString(clientSecret) {
                self.clientSecret = clientSecret
                self.applicationId = appGUID
                isInitialized = true;
            }
            else{
                self.sendAnalyticsData(LogLevel.error, logStringData: "Error while registration - Client secret is not valid")
                print("Error while registration - Client secret is not valid")
            }
        }
        
        /**
         The required intializer for the `BMSPushClient` class.
         
         This method will intialize the BMSPushClient.
         
         - parameter appGUID:    The pushAppGUID of the Push Service
         */
        @available(*, deprecated, message="This method was deprecated , please use initializeWithAppGUID(appGUID:_  clientSecret:_ )")
        public func initializeWithAppGUID (appGUID appGUID: String) {
            self.applicationId = appGUID;
            isInitialized = true;
        }
        
        
        // MARK: Methods (Public)
        
        //TODO: New method of device registraion with UsrId
        
        /**
         
         This Methode used to register the client device to the Bluemix Push service. This is the normal registration, without userId.
         
         Call this methode after successfully registering for remote push notification in the Apple Push
         Notification Service .
         
         - Parameter deviceToken: This is the response we get from the push registartion in APNS.
         - Parameter WithUserId: This is the userId value.
         - Parameter completionHandler: The closure that will be called when this request finishes. The response will contain response (String), StatusCode (Int) and error (string).
         */
        
        public func registerWithDeviceToken(deviceToken:NSData , WithUserId:String?, completionHandler: (response:String?, statusCode:Int?, error:String) -> Void) {
            
            
            if (isInitialized){
                if (validateString(WithUserId!)){
                    
                    // Generate new ID
                    // TODO: This need to be verified. The Device Id is not storing anywhere in BMSCore
                    
                    var devId = String()
                    let authManager  = BMSClient.sharedInstance.authorizationManager
                    devId = authManager.deviceIdentity.ID!
                    BMSPushUtils.saveValueToNSUserDefaults(devId, key: "deviceId")
                    
                    var token:String = deviceToken.description
                    token = token.stringByReplacingOccurrencesOfString("<", withString: "")
                    token = token.stringByReplacingOccurrencesOfString(">", withString: "")
                    token = token.stringByReplacingOccurrencesOfString(" ", withString: "").stringByTrimmingCharactersInSet(NSCharacterSet.symbolCharacterSet())
                    
                    
                    let urlBuilder = BMSPushUrlBuilder(applicationID: self.applicationId!, clientSecret: clientSecret!)
                    
                    let resourceURL:String = urlBuilder.getSubscribedDevicesUrl(devId)
                    let headers = urlBuilder.addHeader()
                    
                    let method =  HttpMethod.GET
                    
                    self.sendAnalyticsData(LogLevel.debug, logStringData: "Verifying previous device registration.")
                    let getRequest = Request(url: resourceURL, headers: headers, queryParameters: nil, method: method, timeout: 60)
                    
                    // MARK: FIrst Action, checking for previuos registration
                    
                     getRequest.send(completionHandler: { (response, error) -> Void in
                        
                        if response?.statusCode != nil {
                            
                            let status = response?.statusCode ?? 0
                            let responseText = response?.responseText ?? ""
                            
                            
                            if (status == 404) {
                                
                                self.sendAnalyticsData(LogLevel.debug, logStringData: "Device is not registered before.  Registering for the first time.")
                                let resourceURL:String = urlBuilder.getDevicesUrl()
                                
                                let headers = urlBuilder.addHeader()
                                let method =  HttpMethod.POST
                                
                                let getRequest = BaseRequest(url: resourceURL, headers: headers, queryParameters: nil, method: method, timeout: 60)
                                
                                let data =  "{\"\(IMFPUSH_DEVICE_ID)\": \"\(devId)\", \"\(IMFPUSH_TOKEN)\": \"\(token)\", \"\(IMFPUSH_PLATFORM)\": \"A\", \"\(IMFPUSH_USERID)\": \"\(WithUserId!)\"}".dataUsingEncoding(NSUTF8StringEncoding)
                                
                                // MARK: Registering for the First Time
                                getRequest.send(requestBody: data!, completionHandler: { (response, error)  -> Void in
                                    
                                    if response?.statusCode != nil {
                                        
                                        let status = response?.statusCode ?? 0
                                        let responseText = response?.responseText ?? ""
                                        
                                        self.sendAnalyticsData(LogLevel.info, logStringData: "Response of device registration - Response is: \(responseText)")
                                        completionHandler(response: responseText, statusCode: status, error: "")
                                        
                                    }
                                    else if let responseError = error {
                                        
                                        self.sendAnalyticsData(LogLevel.error, logStringData: "Error during device registration - Error is: \(responseError.localizedDescription)")
                                        completionHandler(response: "", statusCode: IMFPushErrorvalues.IMFPushRegistrationError.rawValue, error: "Error during device registration - Error is: \(responseError.localizedDescription)")
                                    }
                                })
                                
                            }
                            else if (status == 406) || (status == 500) {
                                
                                self.sendAnalyticsData(LogLevel.error, logStringData: "Error while verifying previous registration - Error is: \(error!.localizedDescription)")
                                completionHandler(response: responseText, statusCode: status, error: "")
                            }
                            else {
                                
                                // MARK: device is already Registered
                                
                                self.sendAnalyticsData(LogLevel.debug, logStringData: "Device is already registered. Return the device Id - Response is: \(response?.responseText)")
                                let respJson = response?.responseText
                                let data = respJson!.dataUsingEncoding(NSUTF8StringEncoding)
                                let jsonResponse:NSDictionary = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
                                
                                let rToken = jsonResponse.objectForKey(IMFPUSH_TOKEN) as! String
                                let rDevId = jsonResponse.objectForKey(IMFPUSH_DEVICE_ID) as! String
                                let userId = jsonResponse.objectForKey(IMFPUSH_USERID) as! String
                                
                                if ((rToken.compare(token)) != NSComparisonResult.OrderedSame) ||
                                    (!(WithUserId!.isEmpty) && (WithUserId!.compare(userId) != NSComparisonResult.OrderedSame)) || (devId.compare(rDevId) != NSComparisonResult.OrderedSame){
                                    
                                    // MARK: Updating the registered device ,userID, token or deviceId changed
                                    
                                    self.sendAnalyticsData(LogLevel.debug, logStringData: "Device token or DeviceId has changed. Sending update registration request.")
                                    let resourceURL:String = urlBuilder.getSubscribedDevicesUrl(devId)
                                    
                                    let headers = urlBuilder.addHeader()
                                    
                                    let method =  HttpMethod.PUT
                                    
                                    let getRequest = BaseRequest(url: resourceURL, headers: headers, queryParameters: nil, method: method, timeout: 60)
                                    
                                    let data =  "{\"\(IMFPUSH_DEVICE_ID)\": \"\(devId)\", \"\(IMFPUSH_TOKEN)\": \"\(token)\", \"\(IMFPUSH_USERID)\": \"\(WithUserId!)\"}".dataUsingEncoding(NSUTF8StringEncoding)
                                    
                                    getRequest.send(requestBody: data!, completionHandler: { (response, error) -> Void in
                                        
                                        if response?.statusCode != nil  {
                                            
                                            let status = response?.statusCode ?? 0
                                            let responseText = response?.responseText ?? ""
                                            
                                            self.sendAnalyticsData(LogLevel.info, logStringData: "Response of device updation - Response is: \(responseText)")
                                            completionHandler(response: responseText, statusCode: status, error: "")
                                        }
                                        else if let responseError = error {
                                            
                                            self.sendAnalyticsData(LogLevel.error, logStringData: "Error during device updatation - Error is : \(responseError.description)")
                                            completionHandler(response: "", statusCode: IMFPushErrorvalues.IMFPushRegistrationUpdateError.rawValue, error: "Error during device updatation - Error is : \(responseError.description)")
                                        }
                                    })
                                }
                                else {
                                    // MARK: device already registered and parameteres not changed.
                                    
                                    self.sendAnalyticsData(LogLevel.info, logStringData: "Device is already registered and device registration parameters not changed.")
                                    completionHandler(response: response?.responseText, statusCode: status, error: "")
                                }
                            }
                            
                        }
                        else if let responseError = error {
                            
                            self.sendAnalyticsData(LogLevel.error, logStringData: "Error while verifying previous registration - Error is: \(responseError.localizedDescription)")
                            completionHandler(response: "", statusCode: IMFPushErrorvalues.IMFPushRegistrationVerificationError.rawValue , error: "Error while verifying previous registration - Error is: \(responseError.localizedDescription)")
                            
                        }
                        
                    })
                }else{
                    
                    self.sendAnalyticsData(LogLevel.error, logStringData: "Error while registration - Provide a valid userId value")
                    completionHandler(response: "", statusCode: IMFPushErrorvalues.IMFPushRegistrationError.rawValue , error: "Error while registration - Provide a valid userId value")
                }
            }else{
                
                self.sendAnalyticsData(LogLevel.error, logStringData: "Error while registration - BMSPush is not initialized")
                completionHandler(response: "", statusCode: IMFPushErrorvalues.IMFPushRegistrationError.rawValue , error: "Error while registration - BMSPush is not initialized")
            }
            
        }
        
        
        /**
         
         This Methode used to register the client device to the Bluemix Push service. This is the normal registration, without userId.
         
         Call this methode after successfully registering for remote push notification in the Apple Push
         Notification Service .
         
         - Parameter deviceToken: This is the response we get from the push registartion in APNS.
         - Parameter completionHandler: The closure that will be called when this request finishes. The response will contain response (String), StatusCode (Int) and error (string).
         */
        
        public func registerWithDeviceToken (deviceToken:NSData, completionHandler: (response:String?, statusCode:Int?, error:String) -> Void) {
            
            // Generate new ID
            // TODO: This need to be verified. The Device Id is not storing anywhere in BMSCore
            
            if (isInitialized){
                var devId = String()
                let authManager  = BMSClient.sharedInstance.authorizationManager
                devId = authManager.deviceIdentity.ID!
                BMSPushUtils.saveValueToNSUserDefaults(devId, key: "deviceId")
                
                var token:String = deviceToken.description
                token = token.stringByReplacingOccurrencesOfString("<", withString: "")
                token = token.stringByReplacingOccurrencesOfString(">", withString: "")
                token = token.stringByReplacingOccurrencesOfString(" ", withString: "").stringByTrimmingCharactersInSet(NSCharacterSet.symbolCharacterSet())
                
                
                
                let urlBuilder = BMSPushUrlBuilder(applicationID: self.applicationId!, clientSecret: clientSecret!)
                
                let resourceURL:String = urlBuilder.getSubscribedDevicesUrl(devId)
                let headers = urlBuilder.addHeader()
              
                let method =  HttpMethod.GET
                
                self.sendAnalyticsData(LogLevel.debug, logStringData: "Verifying previous device registration.")
                let getRequest = Request(url: resourceURL, headers: headers, queryParameters: nil, method: method, timeout: 60)
                
                // MARK: FIrst Action, checking for previuos registration
                
                 getRequest.send(completionHandler: { (response, error)  -> Void in
                    
                    if response?.statusCode != nil {
                        
                        let status = response?.statusCode ?? 0
                        let responseText = response?.responseText ?? ""
                        
                        
                        if (status == 404) {
                            
                            self.sendAnalyticsData(LogLevel.debug, logStringData: "Device is not registered before.  Registering for the first time.")
                            let resourceURL:String = urlBuilder.getDevicesUrl()
                            
                            let headers = urlBuilder.addHeader()
                            let method =  HttpMethod.POST
                            
                            let getRequest = BaseRequest(url: resourceURL, headers: headers, queryParameters: nil, method: method, timeout: 60)
                            
                            let data =  "{\"\(IMFPUSH_DEVICE_ID)\": \"\(devId)\", \"\(IMFPUSH_TOKEN)\": \"\(token)\", \"\(IMFPUSH_PLATFORM)\": \"A\"}".dataUsingEncoding(NSUTF8StringEncoding)
                            
                            // MARK: Registering for the First Time
                            getRequest.send(requestBody: data!, completionHandler: { (response, error) -> Void in
                                
                                if response?.statusCode != nil {
                                    
                                    let status = response?.statusCode ?? 0
                                    let responseText = response?.responseText ?? ""
                                    
                                    self.sendAnalyticsData(LogLevel.info, logStringData: "Response of device registration - Response is: \(responseText)")
                                    completionHandler(response: responseText, statusCode: status, error: "")
                                    
                                }
                                else if let responseError = error {
                                    
                                    self.sendAnalyticsData(LogLevel.error, logStringData: "Error during device registration - Error is: \(responseError.localizedDescription)")
                                    completionHandler(response: "", statusCode: IMFPushErrorvalues.IMFPushRegistrationError.rawValue, error: "Error during device registration - Error is: \(responseError.localizedDescription)")
                                }
                            })
                            
                        }
                        else if (status == 406) || (status == 500) {
                            
                            self.sendAnalyticsData(LogLevel.error, logStringData: "Error while verifying previous registration - Error is: \(error!.localizedDescription)")
                            completionHandler(response: responseText, statusCode: status, error: "")
                        }
                        else {
                            
                            // MARK: device is already Registered
                            
                            self.sendAnalyticsData(LogLevel.debug, logStringData: "Device is already registered. Return the device Id - Response is: \(response?.responseText)")
                            let respJson = response?.responseText
                            let data = respJson!.dataUsingEncoding(NSUTF8StringEncoding)
                            let jsonResponse:NSDictionary = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
                            
                            let rToken = jsonResponse.objectForKey(IMFPUSH_TOKEN) as! String
                            let rDevId = jsonResponse.objectForKey(IMFPUSH_DEVICE_ID) as! String
                            let userId = jsonResponse.objectForKey(IMFPUSH_USERID) as! String
                            
                            if ((rToken.compare(token)) != NSComparisonResult.OrderedSame) || (devId.compare(rDevId) != NSComparisonResult.OrderedSame) || (userId != "anonymous") {
                                
                                // MARK: Updating the registered userID , token or deviceId changed
                                
                                self.sendAnalyticsData(LogLevel.debug, logStringData: "Device token or DeviceId has changed. Sending update registration request.")
                                let resourceURL:String = urlBuilder.getSubscribedDevicesUrl(devId)
                                
                                let headers = urlBuilder.addHeader()
                                
                                let method =  HttpMethod.PUT
                                
                                let getRequest = BaseRequest(url: resourceURL, headers: headers, queryParameters: nil, method: method, timeout: 60)
                                
                                
                                let data =  "{\"\(IMFPUSH_DEVICE_ID)\": \"\(devId)\", \"\(IMFPUSH_TOKEN)\": \"\(token)\"}".dataUsingEncoding(NSUTF8StringEncoding)
                                
                                getRequest.send(requestBody: data!, completionHandler: { (response, error)  -> Void in
                                    
                                    if response?.statusCode != nil  {
                                        
                                        let status = response?.statusCode ?? 0
                                        let responseText = response?.responseText ?? ""
                                        
                                        self.sendAnalyticsData(LogLevel.info, logStringData: "Response of device updation - Response is: \(responseText)")
                                        completionHandler(response: responseText, statusCode: status, error: "")
                                    }
                                    else if let responseError = error {
                                        
                                        self.sendAnalyticsData(LogLevel.error, logStringData: "Error during device updatation - Error is : \(responseError.description)")
                                        completionHandler(response: "", statusCode: IMFPushErrorvalues.IMFPushRegistrationUpdateError.rawValue, error: "Error during device updatation - Error is : \(responseError.description)")
                                    }
                                    
                                })
                                
                            }
                            else {
                                // MARK: device already registered and parameteres not changed.
                                
                                self.sendAnalyticsData(LogLevel.info, logStringData: "Device is already registered and device registration parameters not changed.")
                                completionHandler(response: response?.responseText, statusCode: status, error: "")
                            }
                        }
                        
                    }
                    else if let responseError = error {
                        
                        self.sendAnalyticsData(LogLevel.error, logStringData: "Error while verifying previous registration - Error is: \(responseError.localizedDescription)")
                        completionHandler(response: "", statusCode: IMFPushErrorvalues.IMFPushRegistrationVerificationError.rawValue , error: "Error while verifying previous registration - Error is: \(responseError.localizedDescription)")
                    }
                })
            }else{
                
                self.sendAnalyticsData(LogLevel.error, logStringData: "Error while registration - BMSPush is not initialized")
                completionHandler(response: "", statusCode: IMFPushErrorvalues.IMFPushRegistrationError.rawValue , error: "Error while registration - BMSPush is not initialized")
            }
        }
        
        
        /**
         
         This Method used to Retrieve all the available Tags in the Bluemix Push Service.
         
         This methode will return the list of available Tags in an Array.
         
         - Parameter completionHandler: The closure that will be called when this request finishes. The response will contain response (NSMutableArray), StatusCode (Int) and error (string).
         */
        public func retrieveAvailableTagsWithCompletionHandler (completionHandler: (response:NSMutableArray?, statusCode:Int?, error:String) -> Void){
            
            
            self.sendAnalyticsData(LogLevel.debug, logStringData: "Entering retrieveAvailableTagsWithCompletitionHandler.")
            let urlBuilder = BMSPushUrlBuilder(applicationID: self.applicationId!, clientSecret: clientSecret!)
            
            let resourceURL:String = urlBuilder.getTagsUrl()
            
            let headers = urlBuilder.addHeader()
            let method =  HttpMethod.GET
            
            let getRequest = Request(url: resourceURL, headers: headers, queryParameters: nil, method: method, timeout: 60)
            
            
            getRequest.send(completionHandler: { (response, error) -> Void in
                
                if response?.statusCode != nil {
                    
                    let status = response?.statusCode ?? 0
                    let responseText = response?.responseText ?? ""
                    
                    self.sendAnalyticsData(LogLevel.info, logStringData: "Successfully retrieved available tags - Response is: \(responseText)")
                    let availableTagsArray = response?.availableTags()
                    
                    completionHandler(response: availableTagsArray, statusCode: status, error: "")
                } else if let responseError = error {
                    
                    self.sendAnalyticsData(LogLevel.error, logStringData: "Error while retrieving available tags - Error is: \(responseError.description)")
                    completionHandler(response: [], statusCode: IMFPushErrorvalues.IMFPushRetrieveTagsError.rawValue,error: "Error while retrieving available tags - Error is: \(responseError.description)")
                    
                }
            })
        }
        
        /**
         
         This Methode used to Subscribe to the Tags in the Bluemix Push srvice.
         
         
         This methode will return the list of subscribed tags. If you pass the tags that are not present in the Bluemix App it will be classified under the TAGS NOT FOUND section in the response.
         
         - parameter tagsArray: the array that contains name tags.
         - Parameter completionHandler: The closure that will be called when this request finishes. The response will contain response (NSMutableDictionary), StatusCode (Int) and error (string).
         */
        public func subscribeToTags (tagsArray:NSArray, completionHandler: (response:NSMutableDictionary?, statusCode:Int?, error:String) -> Void) {
            
            
            self.sendAnalyticsData(LogLevel.debug, logStringData:"Entering: subscribeToTags." )
            
            if tagsArray.count != 0 {
                
                let authManager  = BMSClient.sharedInstance.authorizationManager
                let devId = authManager.deviceIdentity.ID!
                
                
                let urlBuilder = BMSPushUrlBuilder(applicationID: self.applicationId!, clientSecret: clientSecret!)
                let resourceURL:String = urlBuilder.getSubscriptionsUrl()
                
                let headers = urlBuilder.addHeader()
                
                let method =  HttpMethod.POST
                
                let getRequest = BaseRequest(url: resourceURL, headers: headers, queryParameters: nil, method: method, timeout: 60)
                
                let mappedArray = tagsArray.flatMap{"\($0)"}.description;
                
                let data =  "{\"\(IMFPUSH_TAGNAMES)\":\(mappedArray), \"\(IMFPUSH_DEVICE_ID)\":\"\(devId)\"}".dataUsingEncoding(NSUTF8StringEncoding)
                
                getRequest.send(requestBody: data!, completionHandler: { (response, error) -> Void in
                    
                    if response?.statusCode != nil {
                        
                        let status = response?.statusCode ?? 0
                        let responseText = response?.responseText ?? ""
                        
                        self.sendAnalyticsData(LogLevel.info, logStringData: "Successfully subscribed to tags - Response is: \(responseText)")
                        let subscriptionResponse = response?.subscribeStatus()
                        
                        completionHandler(response: subscriptionResponse, statusCode: status, error: "")
                        
                    } else if let responseError = error {
                        
                        let subscriptionResponse = NSMutableDictionary()
                        
                        self.sendAnalyticsData(LogLevel.error, logStringData: "Error while subscribing to tags - Error is: \(responseError.description)")
                        completionHandler(response: subscriptionResponse, statusCode: IMFPushErrorvalues.IMFPushTagSubscriptionError.rawValue,error: "Error while retrieving available tags - Error is: \(responseError.description)")
                        
                    }
                })
                
            } else {
                
                let subscriptionResponse = NSMutableDictionary()
                
                self.sendAnalyticsData(LogLevel.error, logStringData: "Error.  Tag array cannot be null. Create tags in your Bluemix App")
                completionHandler(response: subscriptionResponse, statusCode: IMFPushErrorvalues.IMFPushErrorEmptyTagArray.rawValue, error: "Error.  Tag array cannot be null. Create tags in your Bluemix App")
            }
        }
        
        
        /**
         
         This Methode used to Retrieve the Subscribed Tags in the Bluemix Push srvice.
         
         
         This methode will return the list of subscribed tags.
         
         - Parameter completionHandler: The closure that will be called when this request finishes. The response will contain response (NSMutableArray), StatusCode (Int) and error (string).
         */
        public func retrieveSubscriptionsWithCompletionHandler (completionHandler: (response:NSMutableArray?, statusCode:Int?, error:String) -> Void) {
            
            
            self.sendAnalyticsData(LogLevel.debug, logStringData: "Entering retrieveSubscriptionsWithCompletitionHandler.")
            
            let authManager  = BMSClient.sharedInstance.authorizationManager
            let devId = authManager.deviceIdentity.ID!
            
            
            let urlBuilder = BMSPushUrlBuilder(applicationID: self.applicationId!, clientSecret: clientSecret!)
            let resourceURL:String = urlBuilder.getAvailableSubscriptionsUrl(devId)
            
            let headers = urlBuilder.addHeader()
           
            let method =  HttpMethod.GET
            
            let getRequest = Request(url: resourceURL, headers: headers, queryParameters: nil, method: method, timeout: 60)
            
            getRequest.send(completionHandler: { (response, error)  -> Void in
                
                if response?.statusCode != nil {
                    
                    let status = response?.statusCode ?? 0
                    let responseText = response?.responseText ?? ""
                    
                    self.sendAnalyticsData(LogLevel.info, logStringData: "Subscription retrieved successfully - Response is: \(responseText)")
                    let subscriptionArray = response?.subscriptions()
                    
                    completionHandler(response: subscriptionArray, statusCode: status, error: "")
                    
                } else if let responseError = error {
                    
                    self.sendAnalyticsData(LogLevel.error, logStringData: "Error while retrieving subscriptions - Error is: \(responseError.localizedDescription)")
                    
                    completionHandler(response: [], statusCode: IMFPushErrorvalues.IMFPushRetrieveSubscriptionError.rawValue,error: "Error while retrieving subscriptions - Error is: \(responseError.localizedDescription)")
                    
                }
            })
        }
        
        /**
         
         This Methode used to Unsubscribe from the Subscribed Tags in the Bluemix Push srvice.
         
         
         This methode will return the details of Unsubscription status.
         
         - Parameter tagsArray: The list of tags that need to be unsubscribed.
         - Parameter completionHandler: The closure that will be called when this request finishes. The response will contain response (NSMutableDictionary), StatusCode (Int) and error (string).
         */
        public func unsubscribeFromTags (tagsArray:NSArray, completionHandler: (response:NSMutableDictionary?, statusCode:Int?, error:String) -> Void) {
            
            self.sendAnalyticsData(LogLevel.debug, logStringData: "Entering: unsubscribeFromTags")
            
            if tagsArray.count != 0 {
                
                
                let authManager  = BMSClient.sharedInstance.authorizationManager
                let devId = authManager.deviceIdentity.ID!
                
                
                let urlBuilder = BMSPushUrlBuilder(applicationID: self.applicationId!, clientSecret: clientSecret!)
                let resourceURL:String = urlBuilder.getUnSubscribetagsUrl()
                
                let headers = urlBuilder.addHeader()
                
                let method =  HttpMethod.POST
                
                let getRequest = BaseRequest(url: resourceURL, headers: headers, queryParameters: nil, method: method, timeout: 60)
                
                let data1 = tagsArray.flatMap{"\($0)"}.description;
                
                let data =  "{\"\(IMFPUSH_TAGNAMES)\":\(data1), \"\(IMFPUSH_DEVICE_ID)\":\"\(devId)\"}".dataUsingEncoding(NSUTF8StringEncoding)
                
                getRequest.send(requestBody: data, completionHandler: { (response, error) -> Void in

                    
                    if response?.statusCode != nil {
                        
                        let status = response?.statusCode ?? 0
                        let responseText = response?.responseText ?? ""
                        
                        self.sendAnalyticsData(LogLevel.info, logStringData: "Successfully unsubscribed from tags - Response is: \(responseText)")
                        let unSubscriptionResponse = response?.unsubscribeStatus()
                        
                        completionHandler(response: unSubscriptionResponse, statusCode: status, error: "")
                        
                    } else if let responseError = error{
                        
                        let unSubscriptionResponse = NSMutableDictionary()
                        
                        self.sendAnalyticsData(LogLevel.error, logStringData: "Error while unsubscribing from tags - Error is: \(responseError.description)")
                        completionHandler(response: unSubscriptionResponse, statusCode: IMFPushErrorvalues.IMFPushTagUnsubscriptionError.rawValue,error: "Error while retrieving available tags - Error is: \(responseError.description)")
                    }
                })
            } else {
                
                let unSubscriptionResponse = NSMutableDictionary()
                
                self.sendAnalyticsData(LogLevel.error, logStringData: "Error.  Tag array cannot be null.")
                completionHandler(response: unSubscriptionResponse, statusCode: IMFPushErrorvalues.IMFPushErrorEmptyTagArray.rawValue, error: "Error.  Tag array cannot be null.")
            }
        }
        
        /**
         
         This Methode used to UnRegister the client App from the Bluemix Push srvice.
         
         
         - Parameter completionHandler: The closure that will be called when this request finishes. The response will contain response (String), StatusCode (Int) and error (string).
         */
        public func unregisterDevice (completionHandler: (response:String?, statusCode:Int?, error:String) -> Void) {
            
            self.sendAnalyticsData(LogLevel.debug, logStringData: "Entering unregisterDevice.")
            let authManager  = BMSClient.sharedInstance.authorizationManager
            let devId = authManager.deviceIdentity.ID!
            
            
            let urlBuilder = BMSPushUrlBuilder(applicationID: self.applicationId!, clientSecret: clientSecret!)
            let resourceURL:String = urlBuilder.getUnregisterUrl(devId)
            
            let headers = urlBuilder.addHeader()
            
            let method =  HttpMethod.DELETE
            
            let getRequest = Request(url: resourceURL, headers: headers, queryParameters: nil, method: method, timeout: 60)
            
            
            getRequest.send(completionHandler: { (response, error) -> Void in
                
                if response?.statusCode != nil {
                    
                    let status = response?.statusCode ?? 0
                    let responseText = response?.responseText ?? ""
                    
                    self.sendAnalyticsData(LogLevel.info, logStringData: "Successfully unregistered the device. - Response is: \(response?.responseText)")
                    
                    completionHandler(response: responseText, statusCode: status, error: "")
                    
                } else if let responseError = error  {
                    
                    self.sendAnalyticsData(LogLevel.error, logStringData: "Error while unregistering device - Error is: \(responseError.description)")
                    completionHandler(response:"", statusCode: IMFPushErrorvalues.BMSPushUnregitrationError.rawValue,error: "Error while unregistering device - Error is: \(responseError.description)")
                }
            })
        }
    
    
    
        public func sendMessageDeliveryStatus (messageId:String, status:String){
            
            
            self.sendAnalyticsData(LogLevel.debug, logStringData: "Entering sendMessageDeliveryStatus.")
            let authManager  = BMSClient.sharedInstance.authorizationManager
            let devId = authManager.deviceIdentity.ID!
            
            
            let urlBuilder = BMSPushUrlBuilder(applicationID: applicationId!,clientSecret:clientSecret!)
            let resourceURL:String = urlBuilder.getSendMessageDeliveryStatus(messageId)
            
            let headers = urlBuilder.addHeader()
            
            let method =  HttpMethod.PUT
            
            let data =  "{\"\(IMFPUSH_DEVICE_ID)\":\"\(devId)\", \"\(IMFPUSH_STATUS)\":OPEN}".dataUsingEncoding(NSUTF8StringEncoding)
            
            let getRequest = Request(url: resourceURL, method: method, headers: headers, queryParameters: nil, timeout: 60)
            
            getRequest.send(requestBody: data!, completionHandler: { (response, error)  -> Void in
                
                if response?.statusCode != nil {
                    
                    let responseText = response?.responseText ?? ""
                    
                    self.sendAnalyticsData(LogLevel.info, logStringData: "Successfully updated the message status.  The response is: \(responseText)")
                    print("Successfully updated the message status.  The response is: "+responseText)
                    
                } else if let responseError = error{
                    
                    
                    self.sendAnalyticsData(LogLevel.error, logStringData: "Failed to update the message status.  The response is:  \(responseError.localizedDescription)")
                    print("Failed to update the message status.  The response is: "+responseError.localizedDescription)
                    
                    
                }
            })
        }
    
        // MARK: Methods (Internal)
    
        //Begin Logger implementation
    
        // Setting Log info
        internal func sendAnalyticsData (logType:LogLevel, logStringData:String){
            var devId = String()
            let authManager  = BMSClient.sharedInstance.authorizationManager
            devId = authManager.deviceIdentity.ID!
            let testLogger = Logger.logger(name:devId)
            
            if (logType == LogLevel.debug){
                
                Logger.logLevelFilter = LogLevel.debug
                testLogger.debug(message: logStringData)
                
            } else if (logType == LogLevel.error){
                
                Logger.logLevelFilter = LogLevel.error
                testLogger.error(message: logStringData)
                
            } else if (logType == LogLevel.analytics){
                
                Logger.logLevelFilter = LogLevel.analytics
                testLogger.debug(message: logStringData)
                
            } else if (logType == LogLevel.fatal){
                
                Logger.logLevelFilter = LogLevel.fatal
                testLogger.fatal(message: logStringData)
                
            } else if (logType == LogLevel.warn){
                
                Logger.logLevelFilter = LogLevel.warn
                testLogger.warn(message: logStringData)
                
            } else if (logType == LogLevel.warn){
                
                Logger.logLevelFilter = LogLevel.warn
                testLogger.info(message: logStringData)
            }
            else {
                Logger.logLevelFilter = LogLevel.none
                testLogger.debug(message: logStringData)
            }
        }
        
        internal func validateString(object:String) -> Bool{
            if (object.isEmpty || object == "") {
                return false;
            }
            return true
        }
        
    }
    
#endif

