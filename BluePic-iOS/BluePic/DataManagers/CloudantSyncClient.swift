//
//  CloudantSyncClient.swift
//  BluePic
//
//  Created by Rolando Asmat on 11/21/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import Foundation

/**
 * With Cloudant Sync, the application will be able to 
 * 1. Perform CRUD operations on its LOCAL copy of the remote database.
 * 2. Sync with the remote database via push/pull calls.
 */

class CloudantSyncClient {
    
    // Shared instance of data manager
    static let SharedInstance: CloudantSyncClient = {
        
        let key = Utils.getKeyFromPlist("keys", key: "cdt_key")
        let pass = Utils.getKeyFromPlist("keys", key: "cdt_pass")
        let dbName = Utils.getKeyFromPlist("keys", key: "cdt_db_name")
        let username = Utils.getKeyFromPlist("keys", key: "cdt_username")
        var manager = CloudantSyncClient(apiKey: key, apiPassword: pass, dbName: dbName, username: username)
        
        return manager
        
    }()
    
    /**
     * Instance variables
     */
    
    var dbName:String // Name of remote database, also used to create local datastore.
    var username:String // Username from BlueMix service credentials section.
    var apiKey:String // API Key, must have replication permissions for specified database.
    var apiPassword:String // API password for the Key.
    var pushDlgt:pushDelegate
    var pullDlgt:pullDelegate
    var manager:CDTDatastoreManager!
    var datastore:CDTDatastore!
    var pushReplicator:CDTReplicator!
    var pullReplicator:CDTReplicator!
    
    /**
    * Constructor
    */
    init(apiKey:String, apiPassword:String, dbName:String, username:String) {
        self.apiKey = apiKey
        self.apiPassword = apiPassword
        self.dbName = dbName
        self.username = username
        self.pushDlgt = pushDelegate()
        self.pullDlgt = pullDelegate()
        // Create local datastore
        createLocalDatastore()
        // Initialize the push replicator
        createPushReplicator()
        // Initialize the pull replicator
        createPullReplicator()
    }
    
    func createLocalDatastore() {
        do {
            // Create local datastore
            let fileManager = NSFileManager.defaultManager()
            let documentsDir = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last!
            let storeURL = documentsDir.URLByAppendingPathComponent("cloudant-sync-datastore")
            let path = storeURL.path
            self.manager = try CDTDatastoreManager(directory: path)
            self.datastore = try manager.datastoreNamed(dbName)
            // Initialize the push replicator
            createPushReplicator()
            // Initialize the pull replicator
            createPullReplicator()
        } catch {
            print("createLocalDatastore, ERROR: \(error)")
        }
    }
    
    func createPushReplicator() {
        do {
            //Initialize replicators
            let replicatorFactory = CDTReplicatorFactory(datastoreManager: manager)
            let s = "https://"+apiKey+":"+apiPassword+"@"+username+".cloudant.com/"+dbName
            let remoteDatabaseURL = NSURL(string: s)
            // Push Replicate from the local to remote database
            let pushReplication = CDTPushReplication(source: datastore, target: remoteDatabaseURL)
            self.pushReplicator =  try replicatorFactory.oneWay(pushReplication)
            self.pushReplicator.delegate = pushDlgt;
        } catch {
            print("createPushReplicator, ERROR: \(error)")
        }
    }
    
    func createPullReplicator() {
        do {
            //Initialize replicators
            let replicatorFactory = CDTReplicatorFactory(datastoreManager: manager)
            let s = "https://"+apiKey+":"+apiPassword+"@"+username+".cloudant.com/"+dbName
            let remoteDatabaseURL = NSURL(string: s)
            // Pull Replicate from remote database to the local
            let pullReplication = CDTPullReplication(source: remoteDatabaseURL, target: datastore)
            self.pullReplicator =  try replicatorFactory.oneWay(pullReplication)
            self.pullReplicator.delegate = pullDlgt;
        } catch {
            print("createPullReplicator, ERROR: \(error)")
        }
        
    }
    
    

/**
* CRUD Operations
*/
     // Checks if document with given ID exists or not
    func doesExist(id:String) -> Bool {
        do {
            try datastore.getDocumentWithId(id)
            print("Document with id "+id+" does exist.")
            return true
        }
        catch {
            print("Document with id "+id+" does NOT exist.")
            return false
        }
    }
    
    // Return document with passed ID, if it exists.
    func getDoc(id:String) -> CDTDocumentRevision? {
        do {
            let retrieved = try datastore.getDocumentWithId(id)
            print("Retrieved doc with id: "+id)
            return retrieved
        }
        catch {
            print("getDoc, ERROR: \(error)")
            return nil
        }

    }
    
    // Get profile name of specified user id
    func getProfileName(id:String) -> String {
        do {
            let retrieved = try datastore.getDocumentWithId(id)
            let name = retrieved.body["profile_name"]! as! String
            print("Retrieved profile name: "+name)
            return name
        }
        catch {
            print("getProfileName, ERROR: \(error)")
            return ""
        }
    }
    
    // Create a local profile document given an ID and name.
    func createProfileDoc(id:String, name:String) -> CDTDocumentRevision? {
        do {
            // Create a document
            let rev = CDTDocumentRevision(docId: id)
            rev.body = ["profile_name":name, "Type":"profile"]
            // Save the document to the datastore
            try datastore.createDocumentFromRevision(rev)
            print("Created profile doc with id: "+id)
            return rev
        } catch {
            print("createProfileDoc: Encountered an error: \(error)")
            return nil
        }
    }
    
    // Delete document given an ID.
    func deleteDoc(id:String) -> Void {
        do {
            // Delete document
            try datastore.deleteDocumentWithId(id)
            print("Deleted doc with id: "+id)
        } catch {
            print("deleteDoc: Encountered an error: \(error)")
        }
    }
    
    // Delete the pictures belonging to a user
    func deletePicturesOfUser(id:String) -> Void {
        // Get all picture documents that belong to passed in id
        let docs = getPicturesOfOwnerId(id)
        let idArray = docs.documentIds
        for id in idArray {
            deleteDoc(id as! String)
        }
    }
    
    // Create a local picture document given an display name, file name, URL, owner.
    func createPictureDoc(displayName:String, fileName:String, url:String, ownerID:String,width:String, height:String, orientation:String) -> CDTDocumentRevision? {
        if(doesExist(ownerID)) {
            do {
                // Get current timestamp
                let ts = NSDate.timeIntervalSinceReferenceDate()
                // Get display name of owner id
                let ownerName = getProfileName(ownerID)
                // Create a document
                let rev = CDTDocumentRevision()
                rev.body = ["display_name":displayName,
                    "file_name":fileName,
                    "URL":url,
                    "ownerID":ownerID,
                    "ownerName":ownerName,
                    "ts":ts,
                    "width":width,
                    "height":height,
                    "orientation":orientation,
                    "Type":"picture"]
                // Save the document to the database
                try datastore.createDocumentFromRevision(rev)
                print("Created picture doc with display name: "+displayName)
                return rev
            } catch {
                print("createPictureDoc: Encountered an error: \(error)")
                return nil
            }
        }
        else {
            print("Passed in owner id does NOT exist: "+ownerID)
            return nil
        }
    }
    
    // Get array of picture documents that belong to specified user, sorted from newest to oldest.
    func getPicturesOfOwnerId(id:String) -> CDTQResultSet {
        
        // Create index for sort method to use
        datastore.ensureIndexed(["ts"], withName: "timestamps")
        
        // Create sort document
        let sortDocument = [["ts":"desc"]]
        
        // Define query to run
        let query = [
            "ownerID" : id,
            "Type" : "picture"
        ]
        
        // Run query and get a CDTQResultSet object
        let result = datastore.find(query, skip: 0, limit: 0, fields: nil, sort: sortDocument)
        
        return result
    }
    
    
    func getAllPictureObjectsOfOwnerId(id :String) -> [Picture] {
        
        let result = getPicturesOfOwnerId(id)
        
        var pictureObjects = [Picture]()
        
        result.enumerateObjectsUsingBlock({ (rev, idx, stop) -> Void in
            let newPicture = Picture()
            
            newPicture.url = rev.body["URL"] as? String
            newPicture.displayName = rev.body["display_name"] as? String
            newPicture.timeStamp = rev.body["ts"] as? String
            newPicture.ownerName = rev.body["ownerName"] as? String
            
            pictureObjects.append(newPicture)
        })
        
        return pictureObjects
        
    }
    
    
    // Get ALL picture documents, sorted from newest to oldest.
    func getAllPictureDocs() -> CDTQResultSet {
        
        // Create index for sort method to use
        datastore.ensureIndexed(["ts"], withName: "timestamps")
        
        // Create sort document
        let sortDocument = [["ts":"desc"]]
        
        // Define query to run
        let query = [
            "Type" : "picture"
        ]
        
        // Run query and get a CDTQResultSet object
        let result = datastore.find(query, skip: 0, limit: 0, fields: nil, sort: sortDocument)
        
        return result
    }
    
    
    /**
     Method that returns all picture objects by converting the picture docs to picture objects
     
     - returns: [Picture]
     */
    func getAllPictureObjects() -> [Picture] {
        
       let result = self.getAllPictureDocs()
        
        var pictureObjects = [Picture]()
        
        result.enumerateObjectsUsingBlock({ (rev, idx, stop) -> Void in
            let newPicture = Picture()
            
            newPicture.url = rev.body["URL"] as? String
            newPicture.displayName = rev.body["display_name"] as? String
            newPicture.timeStamp = rev.body["ts"] as? String
            newPicture.ownerName = rev.body["ownerName"] as? String
            
            pictureObjects.append(newPicture)
        })

        return pictureObjects
    }
    
    
    
/**
* PUSH and PULL network calls
*/
     
    // Push changes to remote database
    func pushToRemoteDatabase() {
        do {
            //Initialize replicator
            createPushReplicator()
            //Start the replicator
            try self.pushReplicator.start()
            
        } catch {
            print("Encountered an error: \(error)")
        }
    }
    
    // Push changes to remote database - BLOCKING
    func pushToRemoteDatabaseSynchronous() {
        do {
            //Initialize replicators
            createPushReplicator()
            //Start the replicator
            try self.pushReplicator.start()
            var count = 1
            repeat {
                print(self.pushReplicator)
                print(count)
                count++
                NSThread.sleepForTimeInterval(1.0)
            } while(self.pushReplicator.isActive())
            print("replicator pushed \(pushReplicator.changesProcessed) documents")
            
        } catch {
            print("Encountered an error: \(error)")
        }
    }
    
    // Pull changes from remote database
    func pullFromRemoteDatabase() {
        do {
            //Initialize replicator
            createPullReplicator()
            //Start the replicator
            try pullReplicator.start()
            
        } catch {
            print("Encountered an error: \(error)")
        }
    }
    
    // Pull changes from remote database - BLOCKING
    func pullFromRemoteDatabaseSynchronous() {
        do {
            //Initialize replicator
            createPullReplicator()
            //Start the replicator
            try pullReplicator.start()
            var count = 1
            repeat {
                print(self.pullReplicator)
                print(count)
                count++
                NSThread.sleepForTimeInterval(1.0)
            } while(self.pullReplicator.isActive())
            print("replicator pulled \(pullReplicator.changesProcessed) documents")
            
        } catch {
            print("Encountered an error: \(error)")
        }
    }
}

/**
* Delegates for Push and Pull asynchronous tasks.
*/

class pushDelegate:NSObject, CDTReplicatorDelegate {
    
    //var handleAppStartUpResultCallback : ((dataManagerNotification : DataManagerNotification)->())!
    
    
    /**
     * Called when the replicator changes state.
     */
    func replicatorDidChangeState(replicator:CDTReplicator) {
        print("PUSH Replicator changed state.")
    }
    
    /**
     * Called whenever the replicator changes progress
     */
    func replicatorDidChangeProgress(replicator:CDTReplicator) {
        print("PUSH Replicator changed progess.")
    }
    
    /**
     * Called when a state transition to COMPLETE or STOPPED is
     * completed.
     */
    func replicatorDidComplete(replicator:CDTReplicator) {
        print("PUSH Replicator completed.")
        //check if cameraDataManager != nil, then stop loading
        if let _ = CameraDataManager.SharedInstance.confirmationView {
            dispatch_async(dispatch_get_main_queue()) { //dismiss the camera confirmation view on the main thread
                CameraDataManager.SharedInstance.dismissCameraConfirmation()
            }
            
        }
    }
    
    /**
     * Called when a state transition to ERROR is completed.
     */
    func replicatorDidError(replicator:CDTReplicator, info:NSError) {
        print("PUSH Replicator ERROR: \(info)")
        //show error here -- check whether to show it on tabVC or confirmationView (depending on if confirmationView is nil or not)
        if let _ = CameraDataManager.SharedInstance.confirmationView {
            dispatch_async(dispatch_get_main_queue()) {
                CameraDataManager.SharedInstance.showCloudantErrorAlert()
            }
            
        } else { //show error when trying to push when creating
            dispatch_async(dispatch_get_main_queue()) {
//                let tabVC = Utils.rootViewController() as! TabBarViewController
//                tabVC.showCloudantPushingErrorAlert()
                
                //self.handleAppStartUpResultCallback(dataManagerNotification: DataManagerNotification.showCloudantPushingErrorAlert)
                DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.CloudantPushDataFailiure)
            }
            
        }
    }
}

class pullDelegate:NSObject, CDTReplicatorDelegate {
    
    
    /**
     * Called when the replicator changes state.
     */
    func replicatorDidChangeState(replicator:CDTReplicator) {
        print("PULL Replicator changed state.")
    }
    
    /**
     * Called whenever the replicator changes progress
     */
    func replicatorDidChangeProgress(replicator:CDTReplicator) {
        print("PULL Replicator changed progess.")
    }
    
    /**
     * Called when a state transition to COMPLETE or STOPPED is
     * completed.
     */
    func replicatorDidComplete(replicator:CDTReplicator) {
        print("PULL Replicator completed.")
//        let tabVC = Utils.rootViewController() as! TabBarViewController
//        tabVC.stopLoadingImageView()
        
        
        DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.CloudantPullDataSuccess)
        //self.handleAppStartUpResultCallback(dataManagerNotification: DataManagerNotification.stopLoadingImageView)
    }
    
    /**
     * Called when a state transition to ERROR is completed.
     */
    func replicatorDidError(replicator:CDTReplicator, info:NSError) {
        print("PULL Replicator ERROR: \(info)")
//        let tabVC = Utils.rootViewController() as! TabBarViewController
//        tabVC.showCloudantPullingErrorAlert()
        
        DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.CloudantPullDataFailure)
       // self.handleAppStartUpResultCallback(dataManagerNotification: DataManagerNotification.showCloudantPullingErrorAlert)
    }
    
}

