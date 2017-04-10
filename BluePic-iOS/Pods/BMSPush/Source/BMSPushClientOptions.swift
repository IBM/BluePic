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


import Foundation

// MARK: - Swift 3

#if swift(>=3.0)

/**
 This class is to set options for push notifications.
 */
public class BMSPushClientOptions : NSObject {
    
    // MARK: - Properties
    
    /// Category value - An array of Push categories.
    var category: [BMSPushNotificationActionCategory]
    
    /// Device for registrations. This is a userinput value. If not given the default deviceId will be used.
    var deviceId: String
    
    // MARK: Initializers
    
    /**
     Initialze Method .
     */
    public override init() {
        self.category = []
        self.deviceId = ""
    }
    
    /**
     Initialze Method -  Deprecated.
     
     - parameter categoryName: An array of `BMSPushNotificationActionCategory`.
     */
    @available(*, deprecated, message: "This method was deprecated , please use init(categoryName:_  withDeviceId:_ )")
    public init (categoryName category: [BMSPushNotificationActionCategory]) {
        self.category = category
        self.deviceId = ""
    }
    
    /**
     set DeviceId Method
     
     - parameter withDeviceId:  (Optional) The DeviceId for applications.
     */
    public func setDeviceId(deviceId:String){
        self.deviceId = deviceId
        
    }
    
    /**
     set Interactive Notification Categories Method
     
     - parameter categoryName: An array of `BMSPushNotificationActionCategory`.
     */
    public func  setInteractiveNotificationCategories(categoryName category: [BMSPushNotificationActionCategory]){
        self.category = category
    }
}

#else


/**
 This class is to set options for push notifications.
*/
public class BMSPushClientOptions : NSObject {

    // MARK: Properties (Public)

    /// Category value - An array of Push categories.
    var category: [BMSPushNotificationActionCategory]

    /// Device for registrations. This is a userinput value. If not given the default deviceId will be used.
    var deviceId: String

    // MARK: Initializers

    /**
     Initialze Method.
     */
    public override init () {
        self.category = []
        self.deviceId = ""
    }
    /**
     Initialze Method -  Deprecated.
     - parameter categoryName: An array of `BMSPushNotificationActionCategory`.
     */
    @available(*, deprecated, message="This method was deprecated , please use init(categoryName:_  withDeviceId:_ )")
    public init (categoryName category: [BMSPushNotificationActionCategory]) {
        self.category = category
        self.deviceId = ""
    }

    /**
     set DeviceId Method
     
     - parameter withDeviceId:  (Optional) The DeviceId for applications.
     */
    public func setDeviceIdValue(deviceId:String){
        self.deviceId = deviceId
    }
    
    /**
     set Interactive Notification Categories Method
     
     - parameter categoryName: An array of `BMSPushNotificationActionCategory`.
     */
    public func  setInteractiveNotificationCategories(categoryName category: [BMSPushNotificationActionCategory]){
        self.category = category
    }
}
#endif
