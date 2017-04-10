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

/**
 Creates Category objects for push notifications
 */
public class BMSPushNotificationActionCategory : NSObject {
    
    public static let sharedInstance = BMSPushClient()
    
    var identifier: String
    var actions: [BMSPushNotificationAction]
    
    // MARK: Initializers
    
    /**
     Initialze Method -  Deprecated.
     
     - parameter identifierName: identifier name for category.
     - parameter buttonActions: Array of `BMSPushNotificationAction`.
     */
    public init (identifierName identifier: String, buttonActions actions: [BMSPushNotificationAction]) {
        self.identifier = identifier
        self.actions = actions
    }
}
