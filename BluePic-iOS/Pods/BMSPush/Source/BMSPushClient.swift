/*
*     Copyright 2015 IBM Corp.
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
import BMSAnalyticsAPI

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
    
    public static var overrideServerHost = "";
    
    // MARK: Properties (private)
    
    /// `BMSClient` object.
    private var bmsClient = BMSClient.sharedInstance
    
    // Notification Count
    
    private var notificationcount:Int = 0
    
    // MARK: Methods (Public)
    
    /**
    
    This Methode used to register the client device to the Bluemix Push service.
    
    Call this methode after successfully registering for remote push notification in the Apple Push
    Notification Service .
    
    - Parameter deviceToken: This is the response we get from the push registartion in APNS.
    - Parameter completionHandler: The closure that will be called when this request finishes. The response will contain response (String), StatusCode (Int) and error (string).
    */
    
    public func registerDeviceToken (deviceToken:NSData, completionHandler: (response:String, statusCode:Int, error:String) -> Void) {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("appEnterActive"), name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("appEnterBackground"), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("appOpenedFromNotificationClick"), name: UIApplicationDidFinishLaunchingNotification, object: nil)
        
        // Generate new ID
        // TODO: This need to be verified. The Device Id is not storing anywhere in BMSCore
        
        var devId = String()
        let authManager  = BMSClient.sharedInstance.authorizationManager
        devId = authManager.deviceIdentity.id!
        BMSPushUtils.saveValueToNSUserDefaults(devId, key: "deviceId")
        
        var token:String = deviceToken.description
        token = token.stringByReplacingOccurrencesOfString("<", withString: "")
        token = token.stringByReplacingOccurrencesOfString(">", withString: "")
        token = token.stringByReplacingOccurrencesOfString(" ", withString: "").stringByTrimmingCharactersInSet(NSCharacterSet.symbolCharacterSet())
        
        
        let urlBuilder = BMSPushUrlBuilder(applicationID: bmsClient.bluemixAppGUID!)
        
        let resourceURL:String = urlBuilder.getSubscribedDevicesUrl(devId)
        let headers = urlBuilder.addHeader()
        
        let method =  HttpMethod.GET
        
        self.sendAnalyticsData(LogLevel.Debug, logStringData: "Verifying previous device registration.")
        let getRequest = Request(url: resourceURL, headers: headers, queryParameters: nil, method: method, timeout: 60)
        
        // MARK: FIrst Action, checking for previuos registration
        
        getRequest.sendWithCompletionHandler ({ (response: Response?, error: NSError?) -> Void in
            
            if response!.statusCode != nil {
                
                let status = response!.statusCode ?? 0
                let responseText = response!.responseText ?? ""
                
                
                if (status == 404) {
                    
                    self.sendAnalyticsData(LogLevel.Debug, logStringData: "Device is not registered before.  Registering for the first time.")
                    let resourceURL:String = urlBuilder.getDevicesUrl()
                    
                    let headers = urlBuilder.addHeader()
                    
                    let method =  HttpMethod.POST
                    
                    let getRequest = Request(url: resourceURL, headers: headers, queryParameters: nil, method: method, timeout: 60)
                    
                    
                    let dict:NSMutableDictionary = NSMutableDictionary()
                    
                    dict.setValue(devId, forKey: IMFPUSH_DEVICE_ID)
                    dict.setValue(token, forKey: IMFPUSH_TOKEN)
                    dict.setValue("A", forKey: IMFPUSH_PLATFORM)
                    
                    // here "jsonData" is the dictionary encoded in JSON data
                    let jsonData = try! NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions.PrettyPrinted)
                    
                    // here "jsonData" is convereted to string
                    let jsonString = NSString(data: jsonData, encoding: NSUTF8StringEncoding)! as String
                    
                    
                    // MARK: Registering for the First Time
                    
                    getRequest.sendString(jsonString , completionHandler: { (response: Response?, error: NSError?) -> Void in
                        
                        if response!.statusCode != nil {
                            
                            let status = response!.statusCode ?? 0
                            let responseText = response!.responseText ?? ""
                            
                            self.sendAnalyticsData(LogLevel.Info, logStringData: "Response of device registration - Response is: \(responseText)")
                            completionHandler(response: responseText, statusCode: status, error: "")
                            
                        }
                        else if let responseError = error {
                            
                            self.sendAnalyticsData(LogLevel.Error, logStringData: "Error during device registration - Error is: \(responseError.localizedDescription)")
                            completionHandler(response: "", statusCode: IMFPushErrorvalues.IMFPushRegistrationError.rawValue, error: "Error during device registration - Error is: \(responseError.localizedDescription)")
                        }
                    })
                    
                }
                else if (status == 406) || (status == 500) {
                    
                    self.sendAnalyticsData(LogLevel.Error, logStringData: "Error while verifying previous registration - Error is: \(error!.localizedDescription)")
                    completionHandler(response: responseText, statusCode: status, error: "")
                }
                else {
                    
                    // MARK: device is already Registered
                    
                    self.sendAnalyticsData(LogLevel.Debug, logStringData: "Device is already registered. Return the device Id - Response is: \(response?.responseText)")
                    let respJson = response!.responseText
                    let data = respJson!.dataUsingEncoding(NSUTF8StringEncoding)
                    let jsonResponse:NSDictionary = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
                    
                    let rToken = jsonResponse.objectForKey(IMFPUSH_TOKEN) as! String
                    let devId = jsonResponse.objectForKey(IMFPUSH_DEVICE_ID) as! String
                    
                    //print(authManager.userIdentity.debugDescription)
                    //let consumerId:String = (authManager.userIdentity?.displayName)!
                    let consumerId:String =  ""
                    let consumerIdFromJson = jsonResponse.objectForKey(IMFPUSH_USER_ID) as! String
                    
                    if ((rToken.compare(token)) != NSComparisonResult.OrderedSame) || (!(consumerId.isEmpty) && (consumerId.compare(consumerIdFromJson) != NSComparisonResult.OrderedSame))  {
                        
                        // MARK: Updating the registered device , token or deviceId changed
                        
                        self.sendAnalyticsData(LogLevel.Debug, logStringData: "Device token or DeviceId has changed. Sending update registration request.")
                        let resourceURL:String = urlBuilder.getSubscribedDevicesUrl(devId)
                        
                        let headers = urlBuilder.addHeader()
                        
                        let method =  HttpMethod.PUT
                        
                        let getRequest = Request(url: resourceURL, headers: headers, queryParameters: nil, method: method, timeout: 60)
                        
                        
                        let dict:NSMutableDictionary = NSMutableDictionary()
                        
                        dict.setValue(token, forKey: IMFPUSH_TOKEN)
                        dict.setValue(consumerId, forKey: IMFPUSH_USER_ID)
                        dict.setValue(devId, forKey: IMFPUSH_DEVICE_ID)
                        
                        
                        let jsonData = try! NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions.PrettyPrinted)
                        
                        let jsonString = NSString(data: jsonData, encoding: NSUTF8StringEncoding)! as String
                        
                        getRequest.sendString(jsonString , completionHandler: { (response: Response?, error: NSError?) -> Void in
                            
                            
                            
                            if response!.statusCode != nil  {
                                
                                let status = response!.statusCode ?? 0
                                let responseText = response!.responseText ?? ""
                                
                                self.sendAnalyticsData(LogLevel.Info, logStringData: "Response of device updation - Response is: \(responseText)")
                                completionHandler(response: responseText, statusCode: status, error: "")
                            }
                            else if let responseError = error {
                                
                                self.sendAnalyticsData(LogLevel.Error, logStringData: "Error during device updatation - Error is : \(responseError.description)")
                                completionHandler(response: "", statusCode: IMFPushErrorvalues.IMFPushRegistrationUpdateError.rawValue, error: "Error during device updatation - Error is : \(responseError.description)")
                            }
                            
                        })
                        
                    }
                    else {
                        // MARK: device already registered and parameteres not changed.
                        
                        self.sendAnalyticsData(LogLevel.Info, logStringData: "Device is already registered and device registration parameters not changed.")
                        completionHandler(response: "Device is already registered and device registration parameters not changed", statusCode: status, error: "")
                    }
                }
                
            }
            else if let responseError = error {
                
                self.sendAnalyticsData(LogLevel.Error, logStringData: "Error while verifying previous registration - Error is: \(responseError.localizedDescription)")
                completionHandler(response: "", statusCode: IMFPushErrorvalues.IMFPushRegistrationVerificationError.rawValue , error: "Error while verifying previous registration - Error is: \(responseError.localizedDescription)")
                
            }
            
        })
    }
    
    /**
     
     This Method used to Retrieve all the available Tags in the Bluemix Push Service.
     
     This methode will return the list of available Tags in an Array.
     
     - Parameter completionHandler: The closure that will be called when this request finishes. The response will contain response (NSMutableArray), StatusCode (Int) and error (string).
     */
    public func retrieveAvailableTagsWithCompletionHandler (completionHandler: (response:NSMutableArray, statusCode:Int, error:String) -> Void){
        
        
        self.sendAnalyticsData(LogLevel.Debug, logStringData: "Entering retrieveAvailableTagsWithCompletitionHandler.")
        let urlBuilder = BMSPushUrlBuilder(applicationID: bmsClient.bluemixAppGUID!)
        
        let resourceURL:String = urlBuilder.getTagsUrl()
        
        let headers = urlBuilder.addHeader()
        
        let method =  HttpMethod.GET
        
        let getRequest = Request(url: resourceURL, headers: headers, queryParameters: nil, method: method, timeout: 60)
        
        
        getRequest.sendWithCompletionHandler ({ (response, error) -> Void in
            
            var availableTagsArray = NSMutableArray()
            
            if response!.statusCode != nil {
                
                let status = response!.statusCode ?? 0
                let responseText = response!.responseText ?? ""
                
                self.sendAnalyticsData(LogLevel.Info, logStringData: "Successfully retrieved available tags - Response is: \(responseText)")
                availableTagsArray = response!.availableTags()
                
                completionHandler(response: availableTagsArray, statusCode: status, error: "")
            } else if let responseError = error {
                
                self.sendAnalyticsData(LogLevel.Error, logStringData: "Error while retrieving available tags - Error is: \(responseError.description)")
                completionHandler(response: availableTagsArray, statusCode: IMFPushErrorvalues.IMFPushRetrieveTagsError.rawValue,error: "Error while retrieving available tags - Error is: \(responseError.description)")
                
            }
        })
    }
    
    /**
     
     This Methode used to Subscribe to the Tags in the Bluemix Push srvice.
     
     
     This methode will return the list of subscribed tags. If you pass the tags that are not present in the Bluemix App it will be classified under the TAGS NOT FOUND section in the response.
     
     - parameter tagsArray: the array that contains name tags.
     - Parameter completionHandler: The closure that will be called when this request finishes. The response will contain response (NSMutableDictionary), StatusCode (Int) and error (string).
     */
    public func subscribeToTags (tagsArray:NSArray, completionHandler: (response:NSMutableDictionary, statusCode:Int, error:String) -> Void) {
        
        
        self.sendAnalyticsData(LogLevel.Debug, logStringData:"Entering: subscribeToTags." )
        var subscriptionResponse = NSMutableDictionary()
        
        if tagsArray.count != 0 {
            
            let authManager  = BMSClient.sharedInstance.authorizationManager
            let devId = authManager.deviceIdentity.id!
            
            
            let urlBuilder = BMSPushUrlBuilder(applicationID: bmsClient.bluemixAppGUID!)
            let resourceURL:String = urlBuilder.getSubscriptionsUrl()
            
            let headers = urlBuilder.addHeader()
            
            let method =  HttpMethod.POST
            
            let getRequest = Request(url: resourceURL, headers: headers, queryParameters: nil, method: method, timeout: 60)
            
            
            let dict:NSMutableDictionary = NSMutableDictionary()
            
            dict.setValue(tagsArray, forKey: IMFPUSH_TAGNAMES)
            dict.setValue(devId, forKey: IMFPUSH_DEVICE_ID)
            
            let jsonData = try! NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions.PrettyPrinted)
            
            let jsonString = NSString(data: jsonData, encoding: NSUTF8StringEncoding)! as String
            
            getRequest.sendString(jsonString, completionHandler: { (response, error) -> Void in
                
                if response!.statusCode != nil {
                    
                    let status = response!.statusCode ?? 0
                    let responseText = response!.responseText ?? ""
                    
                    self.sendAnalyticsData(LogLevel.Info, logStringData: "Successfully subscribed to tags - Response is: \(responseText)")
                    subscriptionResponse = response!.subscribeStatus()
                    
                    completionHandler(response: subscriptionResponse, statusCode: status, error: "")
                    
                } else if let responseError = error {
                    
                    self.sendAnalyticsData(LogLevel.Error, logStringData: "Error while subscribing to tags - Error is: \(responseError.description)")
                    completionHandler(response: subscriptionResponse, statusCode: IMFPushErrorvalues.IMFPushTagSubscriptionError.rawValue,error: "Error while retrieving available tags - Error is: \(responseError.description)")
                    
                }
            })
            
        } else {
            
            self.sendAnalyticsData(LogLevel.Error, logStringData: "Error.  Tag array cannot be null. Create tags in your Bluemix App")
            completionHandler(response: subscriptionResponse, statusCode: IMFPushErrorvalues.IMFPushErrorEmptyTagArray.rawValue, error: "Error.  Tag array cannot be null. Create tags in your Bluemix App")
        }
    }
    
    
    /**
     
     This Methode used to Retrieve the Subscribed Tags in the Bluemix Push srvice.
     
     
     This methode will return the list of subscribed tags.
     
     - Parameter completionHandler: The closure that will be called when this request finishes. The response will contain response (NSMutableArray), StatusCode (Int) and error (string).
     */
    public func retrieveSubscriptionsWithCompletionHandler (completionHandler: (response:NSMutableArray, statusCode:Int, error:String) -> Void) {
        
        
        self.sendAnalyticsData(LogLevel.Debug, logStringData: "Entering retrieveSubscriptionsWithCompletitionHandler.")
        
        let authManager  = BMSClient.sharedInstance.authorizationManager
        let devId = authManager.deviceIdentity.id!
        
        
        let urlBuilder = BMSPushUrlBuilder(applicationID: bmsClient.bluemixAppGUID!)
        let resourceURL:String = urlBuilder.getAvailableSubscriptionsUrl(devId)
        
        let headers = urlBuilder.addHeader()
        
        let method =  HttpMethod.GET
        
        let getRequest = Request(url: resourceURL, headers: headers, queryParameters: nil, method: method, timeout: 60)
        
        
        getRequest.sendWithCompletionHandler({ (response: Response?, error: NSError?) -> Void in
            
            var subscriptionArray = NSMutableArray()
            
            if response!.statusCode != nil {
                
                let status = response!.statusCode ?? 0
                let responseText = response!.responseText ?? ""
                
                self.sendAnalyticsData(LogLevel.Info, logStringData: "Subscription retrieved successfully - Response is: \(responseText)")
                subscriptionArray = response!.subscriptions()
                
                completionHandler(response: subscriptionArray, statusCode: status, error: "")
                
            } else if let responseError = error {
                
                self.sendAnalyticsData(LogLevel.Error, logStringData: "Error while retrieving subscriptions - Error is: \(responseError.localizedDescription)")
                
                completionHandler(response: subscriptionArray, statusCode: IMFPushErrorvalues.IMFPushRetrieveSubscriptionError.rawValue,error: "Error while retrieving subscriptions - Error is: \(responseError.localizedDescription)")
                
            }
        })
    }
    
    /**
     
     This Methode used to Unsubscribe from the Subscribed Tags in the Bluemix Push srvice.
     
     
     This methode will return the details of Unsubscription status.
     
     - Parameter tagsArray: The list of tags that need to be unsubscribed.
     - Parameter completionHandler: The closure that will be called when this request finishes. The response will contain response (NSMutableDictionary), StatusCode (Int) and error (string).
     */
    public func unsubscribeFromTags (tagsArray:NSArray, completionHandler: (response:NSMutableDictionary, statusCode:Int, error:String) -> Void) {
        
        self.sendAnalyticsData(LogLevel.Debug, logStringData: "Entering: unsubscribeFromTags")
        var unSubscriptionResponse = NSMutableDictionary()
        
        if tagsArray.count != 0 {
            
            
            let authManager  = BMSClient.sharedInstance.authorizationManager
            let devId = authManager.deviceIdentity.id!
            
            
            let urlBuilder = BMSPushUrlBuilder(applicationID: bmsClient.bluemixAppGUID!)
            let resourceURL:String = urlBuilder.getUnSubscribetagsUrl()
            
            let headers = urlBuilder.addHeader()
            
            let method =  HttpMethod.POST
            
            let getRequest = Request(url: resourceURL, headers: headers, queryParameters: nil, method: method, timeout: 60)
            
            
            let dict:NSMutableDictionary = NSMutableDictionary()
            
            dict.setValue(tagsArray, forKey: IMFPUSH_TAGNAMES)
            dict.setValue(devId, forKey: IMFPUSH_DEVICE_ID)
            
            let jsonData = try! NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions.PrettyPrinted)
            
            let jsonString = NSString(data: jsonData, encoding: NSUTF8StringEncoding)! as String
            
            getRequest.sendString(jsonString, completionHandler: { (response, error) -> Void in
                
                if response!.statusCode != nil {
                    
                    let status = response!.statusCode ?? 0
                    let responseText = response!.responseText ?? ""
                    
                    self.sendAnalyticsData(LogLevel.Info, logStringData: "Successfully unsubscribed from tags - Response is: \(responseText)")
                    unSubscriptionResponse = response!.unsubscribeStatus()
                    
                    completionHandler(response: unSubscriptionResponse, statusCode: status, error: "")
                    
                } else if let responseError = error{
                    
                    self.sendAnalyticsData(LogLevel.Error, logStringData: "Error while unsubscribing from tags - Error is: \(responseError.description)")
                    completionHandler(response: unSubscriptionResponse, statusCode: IMFPushErrorvalues.IMFPushTagUnsubscriptionError.rawValue,error: "Error while retrieving available tags - Error is: \(responseError.description)")
                }
            })
        } else {
            
            self.sendAnalyticsData(LogLevel.Error, logStringData: "Error.  Tag array cannot be null.")
            completionHandler(response: unSubscriptionResponse, statusCode: IMFPushErrorvalues.IMFPushErrorEmptyTagArray.rawValue, error: "Error.  Tag array cannot be null.")
        }
    }
    
    /**
     
     This Methode used to UnRegister the client App from the Bluemix Push srvice.
     
     
     - Parameter completionHandler: The closure that will be called when this request finishes. The response will contain response (String), StatusCode (Int) and error (string).
     */
    public func unregisterDevice (completionHandler: (response:String, statusCode:Int, error:String) -> Void) {
        
        self.sendAnalyticsData(LogLevel.Debug, logStringData: "Entering unregisterDevice.")
        let authManager  = BMSClient.sharedInstance.authorizationManager
        let devId = authManager.deviceIdentity.id!
        
        
        let urlBuilder = BMSPushUrlBuilder(applicationID: bmsClient.bluemixAppGUID!)
        let resourceURL:String = urlBuilder.getUnregisterUrl(devId)
        
        let headers = urlBuilder.addHeader()
        
        let method =  HttpMethod.DELETE
        
        let getRequest = Request(url: resourceURL, headers: headers, queryParameters: nil, method: method, timeout: 60)
        
        
        getRequest.sendWithCompletionHandler ({ (response, error) -> Void in
            
            if response!.statusCode != nil {
                
                let status = response!.statusCode ?? 0
                let responseText = response!.responseText ?? ""
                
                self.sendAnalyticsData(LogLevel.Info, logStringData: "Successfully unregistered the device. - Response is: \(response?.responseText)")
                
                completionHandler(response: responseText, statusCode: status, error: "")
                
            } else if let responseError = error  {
                
                self.sendAnalyticsData(LogLevel.Error, logStringData: "Error while unregistering device - Error is: \(responseError.description)")
                completionHandler(response:"", statusCode: IMFPushErrorvalues.BMSPushUnregitrationError.rawValue,error: "Error while unregistering device - Error is: \(responseError.description)")
            }
        })
    }
    
    
    // MARK: Methods (Internal)
    
    //Begin Logger implementation
    
    /**
    Send the Logger info when the client app come from Background state to Active state.
    */
    internal func appEnterActive () {
        
        self.sendAnalyticsData(LogLevel.Info, logStringData: "Application Enter Active.")
        BMSPushUtils.generateMetricsEvents(IMFPUSH_OPEN, messageId: "Application Enter Active.", timeStamp: BMSPushUtils.generateTimeStamp())
    }
    
    /**
     Send the Logger info when the client app goes Background state from Active state.
     */
    internal func appEnterBackground () {
        
        func completionHandler(sendType: String) -> BmsCompletionHandler {
            return {
                (response: Response?, error: NSError?) -> Void in
                if let response = response {
                    print("\n\(sendType) sent successfully: " + String(response.isSuccessful))
                    print("Status code: " + String(response.statusCode))
                    if let responseText = response.responseText {
                        print("Response text: " + responseText)
                    }
                    print("\n")
                }
            }
        }
        
        print("Application Enter Background. Sending analytics information to server.")
        //Analytics.send(completionHandler: completionHandler("Analytics"))
    }
    
    /**
     Send the Logger info while the app is opened by clicking the notification.
     */
    internal func appOpenedFromNotificationClick (notification:NSNotification){
        
        // No use now..
        notificationcount--
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
        
        let launchOptions: NSDictionary = notification.userInfo!
        if launchOptions.allKeys.count > 0  {
            
            let pushNotificationPayload:NSDictionary = launchOptions.valueForKey(UIApplicationLaunchOptionsRemoteNotificationKey) as! NSDictionary
            
            if pushNotificationPayload.allKeys.count > 0 {
                
                self.sendAnalyticsData(LogLevel.Info, logStringData: "App opened by clicking on push notification.")
                
                let messageId:NSString = pushNotificationPayload.objectForKey("nid") as! String
                BMSPushUtils.generateMetricsEvents(IMFPUSH_SEEN, messageId: messageId as String, timeStamp: BMSPushUtils.generateTimeStamp())
            }
        }
    }
    
    /**
     Assigning Re-Write Domain.
     */
    internal func buildRewriteDomain() -> String {
        return BMSClient.sharedInstance.bluemixRegion!
    }
    
    // Setting Log info
    internal func sendAnalyticsData (logType:LogLevel, logStringData:String){
        var devId = String()
        let authManager  = BMSClient.sharedInstance.authorizationManager
        devId = authManager.deviceIdentity.id!
        let testLogger = Logger.logger(forName:devId)
        
        if (logType == LogLevel.Debug){
            
            Logger.logLevelFilter = LogLevel.Debug
            testLogger.debug(logStringData)
            
        } else if (logType == LogLevel.Error){
            
            Logger.logLevelFilter = LogLevel.Error
            testLogger.error(logStringData)
            
        } else if (logType == LogLevel.Analytics){
            
            Logger.logLevelFilter = LogLevel.Analytics
            testLogger.debug(logStringData)
            
        } else if (logType == LogLevel.Fatal){
            
            Logger.logLevelFilter = LogLevel.Fatal
            testLogger.fatal(logStringData)
            
        } else if (logType == LogLevel.Warn){
            
            Logger.logLevelFilter = LogLevel.Warn
            testLogger.warn(logStringData)
            
        } else if (logType == LogLevel.Info){
            
            Logger.logLevelFilter = LogLevel.Info
            testLogger.info(logStringData)
            
        }
        else {
            Logger.logLevelFilter = LogLevel.None
            testLogger.debug(logStringData)
        }
        
    }
    
    public func application (application:UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject] ){
        
        notificationcount++
        
        let text = (userInfo as NSDictionary).valueForKey("payload") as! String
        
        if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? [String:AnyObject]
                
                let messageId = (json! as NSDictionary).valueForKey("nid") as! String
                BMSPushUtils.generateMetricsEvents(IMFPUSH_RECEIVED, messageId: messageId, timeStamp: BMSPushUtils.generateTimeStamp())
                
                if (application.applicationState == UIApplicationState.Active){
                    
                    
                    self.sendAnalyticsData(LogLevel.Info, logStringData: "Push notification received when application is in active state.")
                    
                    BMSPushUtils.generateMetricsEvents(IMFPUSH_SEEN, messageId: messageId, timeStamp: BMSPushUtils.generateTimeStamp())
                }
                
                let pushStatus:Bool = BMSPushUtils.getPushSettingValue()
                
                if pushStatus {
                    
                    self.sendAnalyticsData(LogLevel.Info, logStringData: "Push notification is enabled on device")
                    BMSPushUtils.generateMetricsEvents(IMFPUSH_ACKNOWLEDGED, messageId: messageId, timeStamp: BMSPushUtils.generateTimeStamp())
                }
                
            } catch {
                print("Something went wrong")
            }
        }
        
        
    }
}
