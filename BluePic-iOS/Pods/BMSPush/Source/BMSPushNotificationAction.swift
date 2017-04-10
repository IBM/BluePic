//
//  BMSPushNotificationAction.swift
//  BMSPush
//
//  Created by Jim Dickens on 11/3/16.
//  Copyright © 2016 IBM Corp. All rights reserved.
//

import Foundation


public class BMSPushNotificationAction : NSObject {
    
    public static let sharedInstance = BMSPushClient()
    
    var identifier: String
    var title: String
    var authenticationRequired: Bool?
    var activationMode: UIUserNotificationActivationMode
    
    public init (identifierName identifier: String, buttonTitle title: String, isAuthenticationRequired authenticationRequired: Bool,
          defineActivationMode activationMode: UIUserNotificationActivationMode) {
        self.identifier = identifier
        self.title = title
        self.authenticationRequired = authenticationRequired
        self.activationMode = activationMode
    }
}
