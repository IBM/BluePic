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
        CloudantSyncClient.SharedInstance.dbName = "tests_db"
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreateProfileLocally() {
        // Create User
        let id = "4876"
        let name = "Ellen Harrison"
        
        let created = CloudantSyncClient.SharedInstance.createProfileDoc(id, name: name)
        XCTAssertNotNil(created)
        // Check if doc with provided id exists
        let exists = CloudantSyncClient.SharedInstance.doesExist(id)
        XCTAssertEqual(exists, true)
        let doc = CloudantSyncClient.SharedInstance.getDoc(id)
        XCTAssertNotNil(doc)
        // Make sure that profile names are the same
        let docName:String = CloudantSyncClient.SharedInstance.getProfileName(id)
        XCTAssertEqual(docName, name)
        // Delete doc
        CloudantSyncClient.SharedInstance.deleteDoc(id)
    }
    
    func testDeleteProfileLocally() {
        // Create User to delete
        let id = "1039"
        let name = "Brad Tyler"
        CloudantSyncClient.SharedInstance.createProfileDoc(id, name: name)
        // Make sure doc exists
        var exists = CloudantSyncClient.SharedInstance.doesExist(id)
        XCTAssertEqual(exists, true)
        // Delete User
        CloudantSyncClient.SharedInstance.deleteDoc(id)
        // Make sure doc does not exist
        exists = CloudantSyncClient.SharedInstance.doesExist(id)
        XCTAssertEqual(exists, false)
    }
    
    // Tests creation of pictures, assigning them to a specific user, iterating through a user's pictures and finally deleting them.
    func testUserPictures() {
        // Create User
        let id = "7532"
        let name = "Kenny Reid"
        let created = CloudantSyncClient.SharedInstance.createProfileDoc(id, name: name)
        XCTAssertNotNil(created)
        
        // Create 3 pictures and set their owner id
        let displayNames = ["Keys", "Big Bend", "Yosemite"]
        let fileNames = ["keys.jpg", "bigbend.jpg", "yosemite.jpg"]
        // Picture 1
        let picture1URL = "http://www.tenayalodge.com/img/Carousel-DiscoverYosemite_img3.jpg"
        var picDoc = CloudantSyncClient.SharedInstance.createPictureDoc(displayNames[2], fileName: fileNames[2], url: picture1URL, ownerID: id, width:"400", height:"100", orientation:"0")
        XCTAssertNotNil(picDoc)
        // Picture 2
        let picture2URL = "http://media-cdn.tripadvisor.com/media/photo-s/02/92/12/75/sierra-del-carmen-sunset.jpg"
        picDoc = CloudantSyncClient.SharedInstance.createPictureDoc(displayNames[1], fileName: fileNames[1], url: picture2URL, ownerID: id, width:"200", height:"300", orientation:"0")
        XCTAssertNotNil(picDoc)
        // Picture 3
        let picture3URL = "https://www.flmnh.ufl.edu/fish/SouthFlorida/images/bocachita.JPG"
        picDoc = CloudantSyncClient.SharedInstance.createPictureDoc(displayNames[0], fileName: fileNames[0], url: picture3URL, ownerID: id, width:"500", height:"150", orientation:"0")
        XCTAssertNotNil(picDoc)
        
        // Run Query to get pictures corresponding to specified user id
        let result = CloudantSyncClient.SharedInstance.getPicturesOfOwnerId(id)
        
        // Go through set of returned docs and print fields.
        result.enumerateObjectsUsingBlock({ (rev, idx, stop) -> Void in
            print("Index: "+idx.description)
            print(rev.body["URL"]!)
            print(rev.body["display_name"]!)
            print(rev.body["ts"]!)
            print(rev.body["width"]!)
            print(rev.body["height"]!)
            // Assert order of display names
            XCTAssertEqual(rev.body["display_name"]! as? String, displayNames[Int(idx)])
        })
        
        // Delete created user and their pictures
        CloudantSyncClient.SharedInstance.deletePicturesOfUser(id)
        CloudantSyncClient.SharedInstance.deleteDoc(id)
        let exists = CloudantSyncClient.SharedInstance.doesExist(id)
        XCTAssertEqual(exists, false)
    }
    
    // Tests retrieval of ALL pictures of BluePic
    func testGetAllPictures() {
        // Create Users
        let id1 = "1837"
        let name1 = "Earl Fleming"
        CloudantSyncClient.SharedInstance.createProfileDoc(id1, name: name1)
        
        let id2 = "2948"
        let name2 = "Johnnie Willis"
        CloudantSyncClient.SharedInstance.createProfileDoc(id2, name: name2)
        
        let id3 = "1087"
        let name3 = "Marsha Cobb"
        CloudantSyncClient.SharedInstance.createProfileDoc(id3, name: name3)
        
        // Create 3 pictures and set their owner id
        let displayNames = ["Keys", "Big Bend", "Yosemite"]
        let fileNames = ["keys.jpg", "bigbend.jpg", "yosemite.jpg"]
        // Picture 1
        let picture1URL = "http://www.tenayalodge.com/img/Carousel-DiscoverYosemite_img3.jpg"
        CloudantSyncClient.SharedInstance.createPictureDoc(displayNames[2], fileName: fileNames[2], url: picture1URL, ownerID: id1, width:"100", height:"500", orientation:"0")
        // Picture 2
        let picture2URL = "http://media-cdn.tripadvisor.com/media/photo-s/02/92/12/75/sierra-del-carmen-sunset.jpg"
        CloudantSyncClient.SharedInstance.createPictureDoc(displayNames[1], fileName: fileNames[1], url: picture2URL, ownerID: id2, width:"100", height:"500", orientation:"0")
        // Picture 3
        let picture3URL = "https://www.flmnh.ufl.edu/fish/SouthFlorida/images/bocachita.JPG"
        CloudantSyncClient.SharedInstance.createPictureDoc(displayNames[0], fileName: fileNames[0], url: picture3URL, ownerID: id3, width:"100", height:"500", orientation:"0")
        
        // Run Query to get ALL pictures in BluePic
        let result = CloudantSyncClient.SharedInstance.getAllPictureDocs()
        
        // Go through set of returned docs and print fields.
        result.enumerateObjectsUsingBlock({ (rev, idx, stop) -> Void in
            print("Index: "+idx.description)
            print(rev.body["URL"]!)
            print(rev.body["display_name"]!)
            print(rev.body["ts"]!)
            print(rev.body["ownerName"]!)
        })
        
        // Delete created users'pictures
        CloudantSyncClient.SharedInstance.deletePicturesOfUser(id1)
        CloudantSyncClient.SharedInstance.deletePicturesOfUser(id2)
        CloudantSyncClient.SharedInstance.deletePicturesOfUser(id3)
        
        // Delete created users
        CloudantSyncClient.SharedInstance.deleteDoc(id1)
        CloudantSyncClient.SharedInstance.deleteDoc(id2)
        CloudantSyncClient.SharedInstance.deleteDoc(id3)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    

    
}
