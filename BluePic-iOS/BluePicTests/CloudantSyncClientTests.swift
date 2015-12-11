//
//  CloudantSyncClientTests.swift
//  BluePic
//
//  Created by Rolando Asmat on 11/25/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import XCTest
@testable import BluePic

/**
 * Test class for the ObjectStorageClient class.
 */
class CloudantSyncClientTests: XCTestCase {
    
    static var xctExpectation:XCTestExpectation?
    
    override func setUp() {
        super.setUp()
        // Make sure test cases point to tests_db database.
        CloudantSyncDataManager.SharedInstance!.dbName = "tests_db"
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    /**
     * Tests the creation of a user to the local datastore.
     */
    func testCreateProfileLocally() {
        do {
            // Create User
            let id = "4876"
            let name = "Ellen Harrison"
            try CloudantSyncDataManager.SharedInstance!.createProfileDoc(id, name: name)
            // Make sure doc exists now
            XCTAssertTrue(CloudantSyncDataManager.SharedInstance!.doesExist(id))
            // Delete doc
            try CloudantSyncDataManager.SharedInstance!.deleteDoc(id)
        } catch {
            XCTFail()
        }
    }
    
    /**
     * Tests the deletion of a user from the local datastore.
     */
    func testDeleteProfileLocally() {
        do {
            // Create User to delete
            let id = "1039"
            let name = "Brad Tyler"
            try CloudantSyncDataManager.SharedInstance!.createProfileDoc(id, name: name)
            // Delete User
            try CloudantSyncDataManager.SharedInstance!.deleteDoc(id)
            // Make sure doc does not exist
            XCTAssertFalse(CloudantSyncDataManager.SharedInstance!.doesExist(id))
        } catch {
            XCTFail()
        }
    }
    
    /**
     * Tests creation of picture doc where owner id DOES exist.
     */
    func testCreateValidPicture() {
        do {
            // Create User
            let id = "7532"
            let name = "Kenny Reid"
            try CloudantSyncDataManager.SharedInstance!.createProfileDoc(id, name: name)
            // Create Picture
            let displayName = "Yosemite"
            let fileName = "yosemite.jpg"
            let url = "http://www.tenayalodge.com/img/Carousel-DiscoverYosemite_img3.jpg"
            let width = "400"
            let height = "100"
            let orientation = "0"
            try CloudantSyncDataManager.SharedInstance!.createPictureDoc(displayName, fileName: fileName, url: url, ownerID: id, width: width, height: height, orientation: orientation)
        } catch {
            XCTFail()
        }
    }
    
    /**
     * Tests creation of picture doc where owner id does NOT exist.
     */
    func testCreateInvalidPicture() {
        do {
            // Create Picture
            let displayName = "Yosemite"
            let fileName = "yosemite.jpg"
            let url = "http://www.tenayalodge.com/img/Carousel-DiscoverYosemite_img3.jpg"
            let width = "400"
            let height = "100"
            let orientation = "0"
            try CloudantSyncDataManager.SharedInstance!.createPictureDoc(displayName, fileName: fileName, url: url, ownerID: "", width: width, height: height, orientation: orientation)
        } catch {
            print("Test passed, creation of this doc SHOULD fail")
        }
    }

    /**
     * Tests the assignment of multiple pictures to a SPECIFIC user and the order of which they are returned in when queried.
     */
    func testUserPictures() throws {
        do {
            // Create User
            let id = "7532"
            let name = "Kenny Reid"
            try CloudantSyncDataManager.SharedInstance!.createProfileDoc(id, name: name)
            
            // Create 3 pictures and set their owner id
            let displayNames = ["Keys", "Big Bend", "Yosemite"]
            let fileNames = ["keys.jpg", "bigbend.jpg", "yosemite.jpg"]
            let urls = ["https://www.flmnh.ufl.edu/fish/SouthFlorida/images/bocachita.JPG", "http://media-cdn.tripadvisor.com/media/photo-s/02/92/12/75/sierra-del-carmen-sunset.jpg", "http://www.tenayalodge.com/img/Carousel-DiscoverYosemite_img3.jpg","https://www.flmnh.ufl.edu/fish/SouthFlorida/images/bocachita.JPG"]
            let widths = ["500, 200", "400"]
            let heights = ["150, 300", "100"]
            let orientations = ["0", "1", "2"]
            // Picture 1
            try CloudantSyncDataManager.SharedInstance!.createPictureDoc(
                displayNames[2], fileName: fileNames[2], url: urls[2], ownerID: id, width: widths[2], height: heights[2], orientation: orientations[2])
            // Picture 2
            try CloudantSyncDataManager.SharedInstance!.createPictureDoc(
                displayNames[1], fileName: fileNames[1], url: urls[1], ownerID: id, width: widths[1], height: heights[1], orientation: orientations[1])
            // Picture 3
            try CloudantSyncDataManager.SharedInstance!.createPictureDoc(
                displayNames[0], fileName: fileNames[0], url: urls[0], ownerID: id, width: widths[0], height: heights[0], orientation: orientations[0])
            // Run Query to get pictures corresponding to specified user id
            let result = CloudantSyncDataManager.SharedInstance!.getPictureObjects(id)
            // Check array for size and order
            XCTAssertEqual(result.count, 3)
            XCTAssertEqual(result[0].displayName, displayNames[2])
            XCTAssertEqual(result[1].displayName, displayNames[1])
            XCTAssertEqual(result[2].displayName, displayNames[0])
            
            // Delete created user and their pictures
            try CloudantSyncDataManager.SharedInstance!.deletePicturesOfUser(id)
            try CloudantSyncDataManager.SharedInstance!.deleteDoc(id)
            XCTAssertFalse(CloudantSyncDataManager.SharedInstance!.doesExist(id))
        } catch {
            XCTFail()
        }
    }
    
    /**
     * Tests order of when querying local database for ALL pictures.
     */
    func testGetAllPictures() throws {
        do {
            // Create Users
            let id1 = "1837"
            let name1 = "Earl Fleming"
            try CloudantSyncDataManager.SharedInstance!.createProfileDoc(id1, name: name1)
            let id2 = "2948"
            let name2 = "Johnnie Willis"
            try CloudantSyncDataManager.SharedInstance!.createProfileDoc(id2, name: name2)
            let id3 = "1087"
            let name3 = "Marsha Cobb"
            try CloudantSyncDataManager.SharedInstance!.createProfileDoc(id3, name: name3)
            
            // Create 3 pictures and set their owner id
            let displayNames = ["Keys", "Big Bend", "Yosemite"]
            let fileNames = ["keys.jpg", "bigbend.jpg", "yosemite.jpg"]
            let urls = ["https://www.flmnh.ufl.edu/fish/SouthFlorida/images/bocachita.JPG", "http://media-cdn.tripadvisor.com/media/photo-s/02/92/12/75/sierra-del-carmen-sunset.jpg", "http://www.tenayalodge.com/img/Carousel-DiscoverYosemite_img3.jpg", "https://www.flmnh.ufl.edu/fish/SouthFlorida/images/bocachita.JPG"]
            let widths = ["500, 200", "400"]
            let heights = ["150, 300", "100"]
            let orientations = ["0", "1", "2"]
            // Picture 1
            try CloudantSyncDataManager.SharedInstance!.createPictureDoc(
                displayNames[2], fileName: fileNames[2], url: urls[2], ownerID: id1, width: widths[2], height: heights[2], orientation: orientations[2])
            // Picture 2
            try CloudantSyncDataManager.SharedInstance!.createPictureDoc(
                displayNames[1], fileName: fileNames[1], url: urls[1], ownerID: id2, width: widths[1], height: heights[1], orientation: orientations[1])
            // Picture 3
            try CloudantSyncDataManager.SharedInstance!.createPictureDoc(
                displayNames[0], fileName: fileNames[0], url: urls[0], ownerID: id3, width: widths[0], height: heights[0], orientation: orientations[0])
            // Run Query to get pictures corresponding to specified user id
            let result = CloudantSyncDataManager.SharedInstance!.getPictureObjects(nil)
            // Check array for size and order
            XCTAssertEqual(result.count, 3)
            XCTAssertEqual(result[0].displayName, displayNames[2])
            XCTAssertEqual(result[1].displayName, displayNames[1])
            XCTAssertEqual(result[2].displayName, displayNames[0])
            
            // Delete created users'pictures
            try CloudantSyncDataManager.SharedInstance!.deletePicturesOfUser(id1)
            try CloudantSyncDataManager.SharedInstance!.deletePicturesOfUser(id2)
            try CloudantSyncDataManager.SharedInstance!.deletePicturesOfUser(id3)
            
            // Delete created users
            try CloudantSyncDataManager.SharedInstance!.deleteDoc(id1)
            try CloudantSyncDataManager.SharedInstance!.deleteDoc(id2)
            try CloudantSyncDataManager.SharedInstance!.deleteDoc(id3)
        } catch {
            XCTFail()
        }
    }
    
    //TODO: can't do a pull in expectation handler because pull method throws an error.
    /**
     * Tests the push of 2 documents, deleting them locally, then pulling them and finally making sure they exist again locally.
     */
//    func testPushNPull(){
//        do {
//            // Create User
//            let id = "7532"
//            let name = "Kenny Reid"
//            try CloudantSyncDataManager.SharedInstance!.createProfileDoc(id, name: name)
//            
//            // Create picture and set their owner id
//            let displayName = "Keys"
//            let fileName = "keys"
//            let url = "https://www.flmnh.ufl.edu/fish/SouthFlorida/images/bocachita.JPG"
//            let width = "500"
//            let height = "150"
//            let orientation = "0"
//            // Picture 1
//            try CloudantSyncDataManager.SharedInstance!.createPictureDoc(
//                displayName, fileName: fileName, url: url, ownerID: id, width: width, height: height, orientation: orientation)
//            // Push documents
//            CloudantSyncDataManager.SharedInstance!.pushDelegate = TestPushDelegate()
//            try CloudantSyncDataManager.SharedInstance!.pushToRemoteDatabase()
//            self.waitForExpectationsWithTimeout(20.0
//                , handler: { (NSError) in
//                    do {
//                        // Delete the 2 documents.
//                        try CloudantSyncDataManager.SharedInstance!.deletePicturesOfUser(id)
//                        try CloudantSyncDataManager.SharedInstance!.deleteDoc(id)
//                        // Perform PULL
//                        CloudantSyncDataManager.SharedInstance!.pullDelegate = TestPullDelegate()
//                        try CloudantSyncDataManager.SharedInstance!.pullFromRemoteDatabase()
//                        self.waitForExpectationsWithTimeout(20.0
//                            , handler: { (NSError) in
//                                XCTAssertTrue(CloudantSyncDataManager.SharedInstance!.doesExist(id))
//                                let result = CloudantSyncDataManager.SharedInstance!.getPictureObjects(id)
//                                // Check array for size
//                                XCTAssertEqual(result.count, 1)
//                            })
//                        
//                    } catch {
//                        print(error)
//                        XCTFail()
//                    }
//                })
//            
//        } catch {
//            print(error)
//            XCTFail()
//        }
//    }
}

/**
 * Delegates for test Replicators.
 */
class TestPullDelegate:PullDelegate{
    
    /**
     * Called when the replicator changes state.
     */
    override func replicatorDidChangeState(replicator:CDTReplicator) {
        print("Replicator changed state.")
    }
    
    /**
     * Called whenever the replicator changes progress
     */
    override func replicatorDidChangeProgress(replicator:CDTReplicator) {
        print("Replicator changed progess.")
    }
    
    /**
     * Called when a state transition to COMPLETE or STOPPED is
     * completed.
     */
    override func replicatorDidComplete(replicator:CDTReplicator) {
        print("PULL Replicator completed.")
        CloudantSyncClientTests.xctExpectation?.fulfill()
    }
    
    /**
     * Called when a state transition to ERROR is completed.
     */
    override func replicatorDidError(replicator:CDTReplicator, info:NSError) {
        print("Replicator ERROR: \(info)")
        XCTFail()
    }
}
class TestPushDelegate:PushDelegate{
    
    /**
     * Called when the replicator changes state.
     */
    override func replicatorDidChangeState(replicator:CDTReplicator) {
        print("Replicator changed state.")
    }
    
    /**
     * Called whenever the replicator changes progress
     */
    override func replicatorDidChangeProgress(replicator:CDTReplicator) {
        print("Replicator changed progess.")
    }
    
    /**
     * Called when a state transition to COMPLETE or STOPPED is
     * completed.
     */
    override func replicatorDidComplete(replicator:CDTReplicator) {
        print("PUSH Replicator completed.")
        CloudantSyncClientTests.xctExpectation?.fulfill()
    }
    
    /**
     * Called when a state transition to ERROR is completed.
     */
    override func replicatorDidError(replicator:CDTReplicator, info:NSError) {
        print("Replicator ERROR: \(info)")
        XCTFail()
    }
}


