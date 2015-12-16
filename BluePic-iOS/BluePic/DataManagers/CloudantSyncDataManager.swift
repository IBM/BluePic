/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import Foundation

/**
 * Enum for Error types.
 */
enum CloudantSyncError: ErrorType {
    case DocDoesNotExist
}

/**
 * Using this class (and Cloudant Sync) the application will be able to:
 *  1. Perform CRUD operations on its LOCAL copy of the remote database.
 *  2. Sync with the remote database via push/pull calls.
 */
class CloudantSyncDataManager {
    
    // Shared instance of data manager.
    static let SharedInstance:CloudantSyncDataManager? = {
        let key = Utils.getKeyFromPlist("keys", key: "cdt_key")
        let pass = Utils.getKeyFromPlist("keys", key: "cdt_pass")
        let dbName = Utils.getKeyFromPlist("keys", key: "cdt_db_name")
        let username = Utils.getKeyFromPlist("keys", key: "cdt_username")
        do {
            return try CloudantSyncDataManager(apiKey: key, apiPassword: pass, dbName: dbName, username: username)
        } catch {
            print("CloudantSyncClient init, ERROR: \(error)")
            return nil
        }
    }()
    
    /**
     * Instance variables.
     */
    var dbName:String  // Name of remote database, also used to create local datastore.
    var username:String  // Username from BlueMix service credentials section. ONLY used to construst the database's URL, NOT for authentication purposes.
    var apiKey:String  // API Key, must have replication permissions for specified database.
    var apiPassword:String  // API password for the Key.
    var pushDelegate:PushDelegate
    var pullDelegate:PullDelegate
    var manager:CDTDatastoreManager!
    var datastore:CDTDatastore!
    var pushReplicator:CDTReplicator!
    var pullReplicator:CDTReplicator!
    
    /**
     * Constructor for singleton.
     */
    private init(apiKey:String, apiPassword:String, dbName:String, username:String) throws {
        self.apiKey = apiKey
        self.apiPassword = apiPassword
        self.dbName = dbName
        self.username = username
        self.pushDelegate = PushDelegate()
        self.pullDelegate = PullDelegate()
        // Create local datastore.
        try createLocalDatastore()
        // Initialize the push replicator.
        try createPushReplicator()
        // Initialize the pull replicator.
        try createPullReplicator()
    }
    
    /**
     * Creates a local datastore with the specific name stored in dbName instance variable.
     */
    func createLocalDatastore() throws {
        let fileManager = NSFileManager.defaultManager()
        let documentsDir = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last!
        let storeURL = documentsDir.URLByAppendingPathComponent("cloudant-sync-datastore")
        let path = storeURL.path
        self.manager = try CDTDatastoreManager(directory: path)
        self.datastore = try manager.datastoreNamed(dbName)
    }
    
    /**
     * Creates a new Push Replicator and stores it in pushReplicator instance variable.
     */
    func createPushReplicator() throws {
        // Initialize replicators.
        let replicatorFactory = CDTReplicatorFactory(datastoreManager: manager)
        let remoteDatabaseURL = generateURL()
        // Push Replicate from the local to remote database.
        let pushReplication = CDTPushReplication(source: datastore, target: remoteDatabaseURL)
        self.pushReplicator =  try replicatorFactory.oneWay(pushReplication)
        self.pushReplicator.delegate = pushDelegate;
    }
    
    /**
     * Creates a new Pull Replicator and stores it in pullReplicator instance variable.
     */
    func createPullReplicator() throws {
        // Initialize replicators.
        let replicatorFactory = CDTReplicatorFactory(datastoreManager: manager)
        let remoteDatabaseURL = generateURL()
        // Pull Replicate from remote database to the local.
        let pullReplication = CDTPullReplication(source: remoteDatabaseURL, target: datastore)
        self.pullReplicator =  try replicatorFactory.oneWay(pullReplication)
        self.pullReplicator.delegate = pullDelegate;
    }
    
    /**
     * Creates the URL of the remote database from instance variables.
     */
    private func generateURL() -> NSURL {
        let stringURL = "https://\(apiKey):\(apiPassword)@\(username).cloudant.com/\(dbName)"
        return NSURL(string: stringURL)!
    }
    
    /**
     * CRUD OPERATIONS
     */
     
     /**
     * Checks whether document with passed in id exists.
     *
     * @param id This is the unique ID of a document stored in the local datastore.
     *
     * @return Returns true if document exists, false if it does not.
     */
    func doesExist(id:String) -> Bool {
        do {
            try datastore.getDocumentWithId(id)
            print("Document with id \(id) does exist.")
            return true
        }
        catch {
            print("Document with id \(id) does NOT exist.")
            return false
        }
    }
    
    /**
     * Gets the document with passed in ID.
     *
     * @param id This is the unique ID of a document stored in the local datastore.
     *
     * @return Returns the document if it exists, return nil if it does not.
     */
    func getDoc(id:String) -> CDTDocumentRevision? {
        do {
            let retrieved = try datastore.getDocumentWithId(id)
            print("Retrieved doc with id: \(id)")
            return retrieved
        }
        catch {
            print("getDoc, ERROR: \(error)")
            return nil
        }
    }
    
    /**
     * Get profile name of specified user id.
     *
     * @param id This is the unique ID of a profile document stored in the local datastore.
     *
     * @return Returns profile name if it exists, return nil if doc does not exist.
     */
    func getProfileName(id:String) -> String? {
        do {
            let retrieved = try datastore.getDocumentWithId(id)
            let name = retrieved.body["profile_name"]! as! String
            print("getProfileName called: \(name)")
            return name
        }
        catch {
            print("getProfileName, ERROR: \(error)")
            return nil
        }
    }
    
    /**
     * Creates a profile document.
     *
     * @param id Unique ID the created document to have.
     * @param name Profile name for the created document.
     */
    func createProfileDoc(id:String, name:String) throws -> Void {
        // Create a document.
        let rev = CDTDocumentRevision(docId: id)
        rev.body = ["profile_name":name, "Type":"profile"]
        // Save the document to the datastore.
        try datastore.createDocumentFromRevision(rev)
        print("Created profile doc with id: \(id)")
    }
    
    /**
     * Creates a profile document to use in test cases.
     *
     * @param name Profile name for the created document.
     */
    func createProfileDocForTestCases(name:String) throws -> String {
        // Create a document.
        let rev = CDTDocumentRevision()
        rev.body = ["profile_name":name, "Type":"profile"]
        // Save the document to the datastore.
        let createdDocument = try datastore.createDocumentFromRevision(rev)
        let id = createdDocument.docId
        print("Created profile doc with id: \(id)")
        return id
    }
    
    /**
     * Deletes a document.
     *
     * @param id Unique ID of the document to delete.
     */
    func deleteDoc(id:String) throws -> Void {
        // Delete document.
        try datastore.deleteDocumentWithId(id)
        print("Deleted doc with id: \(id)")
    }
    
    /**
     * Deletes the picture documents of passed in user id.
     *
     * @param id Unique ID of the user.
     */
    func deletePicturesOfUser(id:String) throws -> Void {
        // Define query to run.
        let query = [
            "ownerID" : id,
            "Type" : "picture"
        ]
        // Run query and get a CDTQResultSet object.
        let docs = datastore.find(query)
        let idArray = docs.documentIds
        // Delete documents.
        for id in idArray {
            try deleteDoc(id as! String)
        }
    }
    
    /**
     * Create a local picture document given an display name, file name, URL, owner.
     *
     * @param displayName id Unique ID the created document to have.
     * @param fileName Profile name for the created document.
     * @param url URL of the image.
     * @param ownerID ID of the profile doc this picture belongs to.
     * @param width Width of the picture, in points.
     * @param height Height of the picture, in points.
     */
    func createPictureDoc(displayName:String, fileName:String, url:String, ownerID:String, width:String, height:String) throws -> Void {
        if(doesExist(ownerID)) {
            let ts = NSDate.timeIntervalSinceReferenceDate()
            let rev = CDTDocumentRevision()
            rev.body = ["display_name":displayName,
                "file_name":fileName,
                "URL":url,
                "ownerID":ownerID,
                "ts":ts,
                "width":width,
                "height":height,
                "Type":"picture"]
            try datastore.createDocumentFromRevision(rev)
            print("Created picture doc with display name: \(displayName)")
        } else {
            print("Passed in owner id does NOT exist: \(ownerID)")
            throw CloudantSyncError.DocDoesNotExist
        }
    }
    
    /**
     * Get array of picture objects, sorted from newest to oldest. If an ID is passed in
     * then only the pictures that belong to that user is returned, if nil is passed in
     * then all pictures will be returned.
     *
     * @param id Optional parameter, unique ID of the user.
     *
     * @return Array of Picture objects.
     */
    func getPictureObjects(id :String?) -> [Picture] {
        // Create index for sort method to use.
        datastore.ensureIndexed(["ts"], withName: "timestamps")
        // Create sort document.
        let sortDocument = [["ts":"desc"]]
        var query:[NSObject:AnyObject]!
        if (id != nil) {
            // User id was passed in.
            query = [
                "ownerID" : id!,
                "Type" : "picture"
            ]
        } else {
            // nil was passed in.
            query = [
                "Type" : "picture"
            ]
        }
        // Run query and get a CDTQResultSet object.
        let result = datastore.find(query, skip: 0, limit: 0, fields: nil, sort: sortDocument)
        return createPictureObjects(result)
    }
    
    /**
     * Convenience method that converts a set of picture documents to an array of Picture objects.
     *
     * @param docs Set of picture documents.
     *
     * @return Array of picture objects.
     */
    func createPictureObjects(docs:CDTQResultSet) ->[Picture] {
        var pictureObjects = [Picture]()
        docs.enumerateObjectsUsingBlock({ (rev, idx, stop) -> Void in
            let newPicture = Picture()
            newPicture.fileName = rev.body["file_name"] as? String
            newPicture.url = rev.body["URL"] as? String
            newPicture.displayName = rev.body["display_name"] as? String
            newPicture.timeStamp = rev.body["ts"] as? Double
            newPicture.ownerName = self.getProfileName((rev.body["ownerID"] as? String)!)
            newPicture.setWidthAndHeight(rev.body["width"] as? String, height: rev.body["height"] as? String)
            pictureObjects.append(newPicture)
        })
        return pictureObjects
    }
    
    /**
     * PUSH and PULL network calls.
     */
     
     /**
      * This method will create a new Replicator object and push any new docs/updates on the local datastore to the remote database.
      * This is a asynchronous call and will run on a separate replication thread.
      */
    func pushToRemoteDatabase() throws {
        //Initialize replicator.
        try createPushReplicator()
        //Start the replicator.
        try self.pushReplicator.start()
    }
    
    /**
     * This method will create a new Replicator object and pull any new docs/updates from the remote database to the local datastore.
     * This is a asynchronous call and will run on a separate replication thread.
     */
    func pullFromRemoteDatabase() throws {
        //Initialize replicator.
        try createPullReplicator()
        //Start the replicator.
        try pullReplicator.start()
    }
}
