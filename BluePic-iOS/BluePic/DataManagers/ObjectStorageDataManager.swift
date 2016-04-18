/**
 * Copyright IBM Corporation 2015
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/


import UIKit

class ObjectStorageDataManager: NSObject {

    /// Shared instance of data manager
    static let SharedInstance: ObjectStorageDataManager = {
        
        var manager = ObjectStorageDataManager()
        
        return manager
        
    }()
    
    
    private override init() {
        // Set up connection properties for Object Storage service on Bluemix
        let userId = Utils.getKeyFromPlist("keys", key: "obj_stg_user_id")
        let password = Utils.getKeyFromPlist("keys", key: "obj_stg_password")
        let projectId = Utils.getKeyFromPlist("keys", key: "obj_stg_project_id")
        let authURL = Utils.getKeyFromPlist("keys", key: "obj_stg_auth_url")
        let publicURL = Utils.getKeyFromPlist("keys", key: "obj_stg_public_url")
        self.objectStorageClient = ObjectStorageClient(userId: userId, password: password, projectId: projectId, authURL: authURL, publicURL: publicURL)
    
    }
    
    
    var objectStorageClient: ObjectStorageClient!
    
    
    
}
