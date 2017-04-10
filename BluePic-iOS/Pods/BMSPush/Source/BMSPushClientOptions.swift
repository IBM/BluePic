//
//  BMSPushClientOptions.swift
//  BMSPush
//
//  Created by Jim Dickens on 11/3/16.
//  Copyright © 2016 IBM Corp. All rights reserved.
//

import Foundation

    public class BMSPushClientOptions : NSObject {
        
        var category: [BMSPushNotificationActionCategory]
        
        public init (categoryName category: [BMSPushNotificationActionCategory]) {
            self.category = category
        }
    }
