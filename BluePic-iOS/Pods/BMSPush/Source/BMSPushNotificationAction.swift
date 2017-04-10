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
  Creates action objects for push notifications
 */
public class BMSPushNotificationAction : NSObject {
   
    // MARK: - Properties
    
    public static let sharedInstance = BMSPushClient()
    
    var identifier: String
    var title: String
    var authenticationRequired: Bool?
    var activationMode: UIUserNotificationActivationMode
    
    // MARK: Initializers
    
    /**
     Initialze Method -  Deprecated.
     
     - parameter identifierName: identifier name for your actions.
     - parameter title: Title for your actions.
     - parameter authenticationRequired: Authenticationenbling option for your actions.
     - parameter activationMode: ActivationMode for your actions.
     */
    public init (identifierName identifier: String, buttonTitle title: String, isAuthenticationRequired authenticationRequired: Bool,
          defineActivationMode activationMode: UIUserNotificationActivationMode) {
        self.identifier = identifier
        self.title = title
        self.authenticationRequired = authenticationRequired
        self.activationMode = activationMode
    }
}
