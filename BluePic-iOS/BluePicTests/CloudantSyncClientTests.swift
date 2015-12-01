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
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreateProfileLocally() {
        CloudantSyncClient.SharedInstance.createProfileDoc("1234", name: "Rolando Asmat")
        let exists = CloudantSyncClient.SharedInstance.doesExist("1234")
        XCTAssertEqual(exists, true)
        let doc = CloudantSyncClient.SharedInstance.getDoc("1234")
        let name:String = doc.body["profile_name"]! as! String
        XCTAssertEqual(name, "Rolando Asmat")
        CloudantSyncClient.SharedInstance.deleteProfileDoc("1234")
    }
    
    func testDeleteProfileLocally() {
        CloudantSyncClient.SharedInstance.createProfileDoc("1234", name: "Rolando Asmat")
        CloudantSyncClient.SharedInstance.deleteProfileDoc("1234")
        let exists = CloudantSyncClient.SharedInstance.doesExist("1234")
        XCTAssertEqual(exists, false)
    }
    
    func testGetPictures() {
        
        // Create 3 pictures and set owner id to 1234
        let id = "1234"
        let picture1URL = "http://www.tenayalodge.com/img/Carousel-DiscoverYosemite_img3.jpg"
        CloudantSyncClient.SharedInstance.createPictureDoc("Yosemite", fileName: "yosemite.jpg", url: picture1URL, ownerID: id)
        let picture2URL = "http://media-cdn.tripadvisor.com/media/photo-s/02/92/12/75/sierra-del-carmen-sunset.jpg"
        CloudantSyncClient.SharedInstance.createPictureDoc("Big Bend", fileName: "bigbend.jpg", url: picture2URL, ownerID: id)
        let picture3URL = "https://www.flmnh.ufl.edu/fish/SouthFlorida/images/bocachita.JPG"
        CloudantSyncClient.SharedInstance.createPictureDoc("Keys", fileName: "keys.jpg", url: picture3URL, ownerID: id)
        
        let result = CloudantSyncClient.SharedInstance.getPicturesOfOwnerId("1234")
        
        result.enumerateObjectsUsingBlock({ (rev, idx, stop) -> Void in
            print("Index: "+idx.description)
            print(rev.body["URL"]!)
            print(rev.body["display_name"]!)
            print(rev.body["ts"]!)
        })
    }

    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
