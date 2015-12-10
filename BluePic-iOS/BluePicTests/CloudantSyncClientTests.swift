//
//  CloudantSyncClientTests.swift
//  BluePic
//
//  Created by Rolando Asmat on 11/25/15.
//  Copyright © 2015 MIL. All rights reserved.
//

@testable import BluePic
import XCTest

class CloudantSyncClientTests: XCTestCase {
    
    var xctExpectation:XCTestExpectation?
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        CloudantSyncClient.SharedInstance!.dbName = "tests_db"
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreateProfileLocally() throws {
        // Create User
        let id = "4876"
        let name = "Ellen Harrison"
        try CloudantSyncClient.SharedInstance!.createProfileDoc(id, name: name)
        // Check if doc with provided id exists
        let exists = CloudantSyncClient.SharedInstance!.doesExist(id)
        XCTAssertTrue(exists)
        // Delete doc
        try CloudantSyncClient.SharedInstance!.deleteDoc(id)
    }
    
    func testDeleteProfileLocally() throws {
        // Create User to delete
        let id = "1039"
        let name = "Brad Tyler"
        try CloudantSyncClient.SharedInstance!.createProfileDoc(id, name: name)
        // Delete User
        try CloudantSyncClient.SharedInstance!.deleteDoc(id)
        // Make sure doc does not exist
        let exists = CloudantSyncClient.SharedInstance!.doesExist(id)
        XCTAssertFalse(exists)
    }
    
    // Tests creation of pictures, assigning them to a specific user, iterating through a user's pictures and finally deleting them.
    func testUserPictures() throws {
        // Create User
        let id = "7532"
        let name = "Kenny Reid"
        let created = try CloudantSyncClient.SharedInstance!.createProfileDoc(id, name: name)
        XCTAssertNotNil(created)
        
        // Create 3 pictures and set their owner id
        let displayNames = ["Keys", "Big Bend", "Yosemite"]
        let fileNames = ["keys.jpg", "bigbend.jpg", "yosemite.jpg"]
        // Picture 1
        let picture1URL = "http://www.tenayalodge.com/img/Carousel-DiscoverYosemite_img3.jpg"
        var picDoc = try CloudantSyncClient.SharedInstance!.createPictureDoc(displayNames[2], fileName: fileNames[2], url: picture1URL, ownerID: id, width:"400", height:"100", orientation:"0")
        XCTAssertNotNil(picDoc)
        // Picture 2
        let picture2URL = "http://media-cdn.tripadvisor.com/media/photo-s/02/92/12/75/sierra-del-carmen-sunset.jpg"
        picDoc = try CloudantSyncClient.SharedInstance!.createPictureDoc(displayNames[1], fileName: fileNames[1], url: picture2URL, ownerID: id, width:"200", height:"300", orientation:"0")
        XCTAssertNotNil(picDoc)
        // Picture 3
        let picture3URL = "https://www.flmnh.ufl.edu/fish/SouthFlorida/images/bocachita.JPG"
        picDoc = try CloudantSyncClient.SharedInstance!.createPictureDoc(displayNames[0], fileName: fileNames[0], url: picture3URL, ownerID: id, width:"500", height:"150", orientation:"0")
        XCTAssertNotNil(picDoc)
        
        // Run Query to get pictures corresponding to specified user id
        let result = try CloudantSyncClient.SharedInstance!.getPictureObjects(id)
        
        // Delete created user and their pictures
        try CloudantSyncClient.SharedInstance!.deletePicturesOfUser(id)
        try CloudantSyncClient.SharedInstance!.deleteDoc(id)
        let exists = CloudantSyncClient.SharedInstance!.doesExist(id)
        XCTAssertEqual(exists, false)
    }
    
    // Tests retrieval of ALL pictures of BluePic
    func testGetAllPictures() throws {
        // Create Users
        let id1 = "1837"
        let name1 = "Earl Fleming"
        try CloudantSyncClient.SharedInstance!.createProfileDoc(id1, name: name1)
        
        let id2 = "2948"
        let name2 = "Johnnie Willis"
        try CloudantSyncClient.SharedInstance!.createProfileDoc(id2, name: name2)
        
        let id3 = "1087"
        let name3 = "Marsha Cobb"
        try CloudantSyncClient.SharedInstance!.createProfileDoc(id3, name: name3)
        
        // Create 3 pictures and set their owner id
        let displayNames = ["Keys", "Big Bend", "Yosemite"]
        let fileNames = ["keys.jpg", "bigbend.jpg", "yosemite.jpg"]
        // Picture 1
        let picture1URL = "http://www.tenayalodge.com/img/Carousel-DiscoverYosemite_img3.jpg"
        try CloudantSyncClient.SharedInstance!.createPictureDoc(displayNames[2], fileName: fileNames[2], url: picture1URL, ownerID: id1, width:"100", height:"500", orientation:"0")
        // Picture 2
        let picture2URL = "http://media-cdn.tripadvisor.com/media/photo-s/02/92/12/75/sierra-del-carmen-sunset.jpg"
        try CloudantSyncClient.SharedInstance!.createPictureDoc(displayNames[1], fileName: fileNames[1], url: picture2URL, ownerID: id2, width:"100", height:"500", orientation:"0")
        // Picture 3
        let picture3URL = "https://www.flmnh.ufl.edu/fish/SouthFlorida/images/bocachita.JPG"
        try CloudantSyncClient.SharedInstance!.createPictureDoc(displayNames[0], fileName: fileNames[0], url: picture3URL, ownerID: id3, width:"100", height:"500", orientation:"0")
        
        // Run Query to get ALL pictures in BluePic
        let result = try CloudantSyncClient.SharedInstance!.getPictureObjects(nil)
        
        // Delete created users'pictures
        try CloudantSyncClient.SharedInstance!.deletePicturesOfUser(id1)
        try CloudantSyncClient.SharedInstance!.deletePicturesOfUser(id2)
        try CloudantSyncClient.SharedInstance!.deletePicturesOfUser(id3)
        
        // Delete created users
        try CloudantSyncClient.SharedInstance!.deleteDoc(id1)
        try CloudantSyncClient.SharedInstance!.deleteDoc(id2)
        try CloudantSyncClient.SharedInstance!.deleteDoc(id3)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
}


/**
 * Delegate for test Replicators.
 */
class ReplicatorDelegate:NSObject, CDTReplicatorDelegate {
    
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
        print("PUSH Replicator ERROR: \(info)")
    }
}
