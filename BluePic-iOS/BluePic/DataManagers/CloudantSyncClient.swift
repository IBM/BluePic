//
//  CloudantSyncClient.swift
//  BluePic
//
//  Created by Rolando Asmat on 11/21/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import Foundation

/**
 * With Cloudant Sync, the application will be able to perform CRUD operations its local replication of the
 * remote database.
 *
 * The only network calls will be to sync the local database with the remote one. This is accomplished via
 * 2 main methods: pushToRemoteDatabase and pullFromRemoteDatabase. These are asynchronous calls made in order 
 * to push new documents and pull new documents, respectively.
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
    var manager:CDTDatastoreManager
    var datastore:CDTDatastore
    var apiKey:String
    var apiPassword:String
    var dbName:String
    var username:String
    var pushDlgt:pushDelegate
    var pullDlgt:pullDelegate
    var pushReplicator:CDTReplicator
    var pullReplicator:CDTReplicator
    
    /**
    * Constructor
    */
    init(apiKey:String, apiPassword:String, dbName:String, username:String) {
        self.apiKey = apiKey
        self.apiPassword = apiPassword
        self.dbName = dbName
        self.username = username
        manager = CDTDatastoreManager()
        datastore = CDTDatastore()
        pushDlgt = pushDelegate()
        pullDlgt = pullDelegate()
        self.pushReplicator = CDTReplicator()
        self.pullReplicator = CDTReplicator()
        do {
            let fileManager = NSFileManager.defaultManager()
            let documentsDir = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last!
            let storeURL = documentsDir.URLByAppendingPathComponent("cloudant-sync-datastore")
            let path = storeURL.path
            manager = try CDTDatastoreManager(directory: path)
            datastore = try manager.datastoreNamed(dbName)
            
            //Initialize replicators
            let replicatorFactory = CDTReplicatorFactory(datastoreManager: manager)
            let s = "https://"+apiKey+":"+apiPassword+"@"+username+".cloudant.com/"+dbName
            let remoteDatabaseURL = NSURL(string: s)
            // Push Replicate from the local to remote database
            let pushReplication = CDTPushReplication(source: datastore, target: remoteDatabaseURL)
            self.pushReplicator =  try replicatorFactory.oneWay(pushReplication)
            pushReplicator.delegate = pushDlgt;
            // Pull Replicate from remote database to the local
            let pullReplication = CDTPullReplication(source: remoteDatabaseURL, target: datastore)
            self.pullReplicator =  try replicatorFactory.oneWay(pullReplication)
            pullReplicator.delegate = pullDlgt;
            
        } catch {
            print("Init, ERROR: \(error)")
        }
    }
    
    // Checks if document with given ID exists or not
    func doesExist(id:String) -> Bool {
        var exists:Bool
        do {
            try datastore.getDocumentWithId(id)
            exists = true
            print("Document with id "+id+" does exist.")
        }
        catch {
            exists = false
            print("Document with id "+id+" does NOT exist.")
        }
        return exists
    }
    
/**
* CRUD Operations
*/
     
    // Return document with passed ID, if it exists.
    func getDoc(id:String) -> CDTDocumentRevision {
        var retrieved:CDTDocumentRevision = CDTDocumentRevision()
        do {
            retrieved = try datastore.getDocumentWithId(id)
            print("Retrieved doc with id: "+id)
        }
        catch {
            print("getDoc, ERROR: \(error)")
        }
        return retrieved
    }
    
    // Get display name
    func getDisplayName(id:String) -> String {
        var retrieved:CDTDocumentRevision = CDTDocumentRevision()
        do {
            retrieved = try datastore.getDocumentWithId(id)
            let name = retrieved.body["profile_name"]! as! String
            print("Retrieved display name: "+name)
            return name
        }
        catch {
            print("getDisplayName, ERROR: \(error)")
        }
        return ""
    }
    
    // Create a local profile document given an ID and name.
    func createProfileDoc(id:String, name:String) -> CDTDocumentRevision {
        let rev:CDTDocumentRevision = CDTDocumentRevision()
        do {
            // Create a document
            let rev = CDTDocumentRevision(docId: id)
            rev.body = ["profile_name":name, "Type":"profile"]
            // Save the document to the database
            try datastore.createDocumentFromRevision(rev)
            print("Created profile doc with id: "+id)
        } catch {
            print("createProfileDoc: Encountered an error: \(error)")
        }
        return rev
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
    func createPictureDoc(displayName:String, fileName:String, url:String, ownerID:String,width:String, height:String) -> Bool {
        if(doesExist(ownerID)) {
            do {
                // Get current timestamp + formatted date
                let ts = NSDate.timeIntervalSinceReferenceDate()
                // Get display name of owner id
                let ownerName = getDisplayName(ownerID)
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
                    "Type":"picture"]
                
                // Save the document to the database
                try datastore.createDocumentFromRevision(rev)
                print("Created picture doc with display name: "+displayName)
            } catch {
                print("createPictureDoc: Encountered an error: \(error)")
            }
            return true
        }
        else {
            print("Passed in owner id does NOT exist: "+ownerID)
            return false
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
* PUSH and PULL network calls
*/
     
    // Push changes to remote database
    func pushToRemoteDatabase() {
        do {
            //Initialize replicators
            let replicatorFactory = CDTReplicatorFactory(datastoreManager: manager)
            let s = "https://"+apiKey+":"+apiPassword+"@"+username+".cloudant.com/"+dbName
            let remoteDatabaseURL = NSURL(string: s)
            // Push Replicate from the local to remote database
            let pushReplication = CDTPushReplication(source: datastore, target: remoteDatabaseURL)
            self.pushReplicator =  try replicatorFactory.oneWay(pushReplication)
            pushReplicator.delegate = pushDlgt;
            //Start the replicator
            try pushReplicator.start()
            
        } catch {
            print("Encountered an error: \(error)")
        }
    }
    
    // Push changes to remote database - BLOCKING
    func pushToRemoteDatabaseSynchronous() {
        do {
            //Initialize replicators
            let replicatorFactory = CDTReplicatorFactory(datastoreManager: manager)
            let s = "https://"+apiKey+":"+apiPassword+"@"+username+".cloudant.com/"+dbName
            let remoteDatabaseURL = NSURL(string: s)
            // Push Replicate from the local to remote database
            let pushReplication = CDTPushReplication(source: datastore, target: remoteDatabaseURL)
            self.pushReplicator =  try replicatorFactory.oneWay(pushReplication)
            pushReplicator.delegate = pushDlgt;
            //Start the replicator
            try pushReplicator.start()
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
            //Initialize replicators
            let replicatorFactory = CDTReplicatorFactory(datastoreManager: manager)
            let s = "https://"+apiKey+":"+apiPassword+"@"+username+".cloudant.com/"+dbName
            let remoteDatabaseURL = NSURL(string: s)
            // Pull Replicate from remote database to the local
            let pullReplication = CDTPullReplication(source: remoteDatabaseURL, target: datastore)
            self.pullReplicator =  try replicatorFactory.oneWay(pullReplication)
            pullReplicator.delegate = pullDlgt;
            //Start the replicator
            try pullReplicator.start()
            
        } catch {
            print("Encountered an error: \(error)")
        }
    }
    
    // Pull changes from remote database - BLOCKING
    func pullFromRemoteDatabaseSynchronous() {
        do {
            //Initialize replicators
            let replicatorFactory = CDTReplicatorFactory(datastoreManager: manager)
            let s = "https://"+apiKey+":"+apiPassword+"@"+username+".cloudant.com/"+dbName
            let remoteDatabaseURL = NSURL(string: s)
            // Pull Replicate from remote database to the local
            let pullReplication = CDTPullReplication(source: remoteDatabaseURL, target: datastore)
            self.pullReplicator =  try replicatorFactory.oneWay(pullReplication)
            pullReplicator.delegate = pullDlgt;
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
    }
    
    /**
     * Called when a state transition to ERROR is completed.
     */
    func replicatorDidError(replicator:CDTReplicator, info:NSError) {
        print("PUSH Replicator ERROR: ")
        print(info)
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
        let tabVC = Utils.rootViewController() as! TabBarViewController
        tabVC.stopLoadingImageView()
        //tabVC.showErrorAlert()
    }
    
    /**
     * Called when a state transition to ERROR is completed.
     */
    func replicatorDidError(replicator:CDTReplicator, info:NSError) {
        print("PULL Replicator ERROR: \(info)")
        let tabVC = Utils.rootViewController() as! TabBarViewController
        tabVC.showCloudantErrorAlert()
    }
    
}

