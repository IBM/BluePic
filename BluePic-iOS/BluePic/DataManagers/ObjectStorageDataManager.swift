//
//  ObjectStorageDataManager.swift
//  BluePic
//
//  Created by Nathan Hekman on 11/24/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit

class ObjectStorageDataManager: NSObject {

    /// Shared instance of data manager
    static let SharedInstance: ObjectStorageDataManager = {
        
        var manager = ObjectStorageDataManager()
        manager.initializeObjectStorageClient()
        
        return manager
        
    }()
    
    
    private override init() {} //This prevents others from using the default '()' initializer for this class.
    
    
    var objectStorageClient: ObjectStorageClient!
    
    
    private func initializeObjectStorageClient() {
        // Set up connection properties for Object Storage service on Bluemix
        let userId = Utils.getKeyFromPlist("keys", key: "obj_stg_user_id")
        let password = Utils.getKeyFromPlist("keys", key: "obj_stg_password")
        let projectId = Utils.getKeyFromPlist("keys", key: "obj_stg_project_id")
        let authURL = Utils.getKeyFromPlist("keys", key: "obj_stg_auth_url")
        let publicURL = Utils.getKeyFromPlist("keys", key: "obj_stg_public_url")
        self.objectStorageClient = ObjectStorageClient(userId: userId, password: password, projectId: projectId, authURL: authURL, publicURL: publicURL)
        
    }
    
    
    
}
