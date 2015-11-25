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
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testCreateProfileLocally() {
        CloudantSyncClient.SharedInstance.createProfileDoc("1234", name: "Rolando Asmat")
        let exists = CloudantSyncClient.SharedInstance.doesExist("1234")
        XCTAssertEqual(exists, true)
        let doc = CloudantSyncClient.SharedInstance.getDoc("1234")
        let name:String = doc.body["profile_name"]! as! String
        XCTAssertEqual(name, "Rolando Asmat")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
