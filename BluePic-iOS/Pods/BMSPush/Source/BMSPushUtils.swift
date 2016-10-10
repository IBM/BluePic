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
     Used to Support the `BMSPushClient` and creating exact Logger information.
     
     This class is responsilble for creating time logs, matrics events etc.
     */
    public class BMSPushUtils: NSObject {
        
        static var loggerMessage:String = ""
        
        class func saveValueToNSUserDefaults (value:String, key:String){
            
            
            let standardUserDefaults : UserDefaults = UserDefaults.standard
            if standardUserDefaults.object(forKey: key) != nil  {
                
                UserDefaults.standard.set(value, forKey: key)
                UserDefaults.standard.synchronize()
                
            }
            loggerMessage = ("Saving value to NSUserDefaults with Key: \(key) and Value: \(value)")
            self.sendLoggerData()
        }
        
        class func getPushSettingValue() -> Bool {
            
            
            var pushEnabled = false
            
            if  ((UIDevice.current.systemVersion as NSString).floatValue >= 8.0) {
                
                if (UIApplication.shared.isRegisteredForRemoteNotifications) {
                    pushEnabled = true
                }
                else {
                    pushEnabled = false
                }
            } else {
                
                let grantedSettings = UIApplication.shared.currentUserNotificationSettings
                
                if grantedSettings!.types.rawValue & UIUserNotificationType.alert.rawValue != 0 {
                    // Alert permission granted
                    pushEnabled = true
                }
                else{
                    pushEnabled = false
                }
            }
            
            return pushEnabled;
        }
        
        class func sendLoggerData () {
            
            var devId = String()
            let authManager  = BMSClient.sharedInstance.authorizationManager
            devId = authManager.deviceIdentity.ID!
            let testLogger = Logger.logger(name:devId)
            Logger.logLevelFilter = LogLevel.debug
            testLogger.debug(message: loggerMessage)
            Logger.logLevelFilter = LogLevel.info
            testLogger.info(message: loggerMessage)
            
        }
        
        
    }
    
    
#else
    
    /**
     Used to Support the `BMSPushClient` and creating exact Logger information.
     
     This class is responsilble for creating time logs, matrics events etc.
     */
    public class BMSPushUtils: NSObject {
        
        static var loggerMessage:String = ""
        
        class func saveValueToNSUserDefaults (value:String, key:String){
            
            
            let standardUserDefaults : NSUserDefaults = NSUserDefaults.standardUserDefaults()
            if standardUserDefaults.objectForKey(key) != nil  {
                
                NSUserDefaults.standardUserDefaults().setObject(value, forKey: key)
                NSUserDefaults.standardUserDefaults().synchronize()
                
            }
            loggerMessage = ("Saving value to NSUserDefaults with Key: \(key) and Value: \(value)")
            self.sendLoggerData()
        }
        
        class func getPushSettingValue() -> Bool {
            
            
            var pushEnabled = false
            
            if  ((UIDevice.currentDevice().systemVersion as NSString).floatValue >= 8.0) {
                
                if (UIApplication.sharedApplication().isRegisteredForRemoteNotifications()) {
                    pushEnabled = true
                }
                else {
                    pushEnabled = false
                }
            } else {
                
                let grantedSettings = UIApplication.sharedApplication().currentUserNotificationSettings()
                
                if grantedSettings!.types.rawValue & UIUserNotificationType.Alert.rawValue != 0 {
                    // Alert permission granted
                    pushEnabled = true
                }
                else{
                    pushEnabled = false
                }
            }
            
            return pushEnabled;
        }
        
        class func sendLoggerData () {
            
            var devId = String()
            let authManager  = BMSClient.sharedInstance.authorizationManager
            devId = authManager.deviceIdentity.ID!
            let testLogger = Logger.logger(name: devId)
            Logger.logLevelFilter = LogLevel.debug
            testLogger.debug(message: loggerMessage)
            Logger.logLevelFilter = LogLevel.info
            testLogger.info(message: loggerMessage)
            
        }
        
        
    }
    
    
#endif
