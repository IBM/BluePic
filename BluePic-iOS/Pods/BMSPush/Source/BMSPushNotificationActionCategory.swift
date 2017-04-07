//
//  BMSPushNotificationActionCategory.swift
//  BMSPush
//
//  Created by Jim Dickens on 11/3/16.
//  Copyright © 2016 IBM Corp. All rights reserved.
//

import Foundation


public class BMSPushNotificationActionCategory : NSObject {
    
    public static let sharedInstance = BMSPushClient()
    
    var identifier: String
    var actions: [BMSPushNotificationAction]
    
    public init (identifierName identifier: String, buttonActions actions: [BMSPushNotificationAction]) {
        self.identifier = identifier
        self.actions = actions
    }
}
