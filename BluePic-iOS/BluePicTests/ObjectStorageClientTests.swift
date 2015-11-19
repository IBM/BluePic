//
//  ObjectStorageClientTests.swift
//  BluePic
//
//  Created by Ricardo Olivieri on 11/17/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import XCTest
@testable import BluePic

class ObjectStorageClientTests: XCTestCase {
    
    var objectStorageClient: ObjectStorageClient!
    var xctExpectation:XCTestExpectation?
    let containerName = "test-container"
    let publicURL = "https://dal.objectstorage.open.softlayer.com/v1/AUTH_dd1ceb19680948119774a6d2f08057c2"
    
    override func setUp() {
        super.setUp()
        
        // Set up connection properties for Object Storage service on Bluemix
        let password = "wqQ^0=MEs.0=2Yuk"
        let userId = "f7de00fe33404786857f90c1c73d255d"
        let projectId = "dd1ceb19680948119774a6d2f08057c2"
        let authURL = "https://identity.open.softlayer.com/v3/auth/tokens"
        
        // Init variables for test execution
        objectStorageClient = ObjectStorageClient(userId: userId, password: password, projectId: projectId, authURL: authURL, publicURL: publicURL)
        xctExpectation = self.expectationWithDescription("Asynchronous request about to occur...")
    }
    
    override func tearDown() {
        super.tearDown()
        objectStorageClient = nil
        xctExpectation = nil
    }
    
    func testAuthenticate() {
        let testName = "testAuthenticate"
        authenticate(testName, onSuccess: {
            print("\(testName) succeeded.")
            self.xctExpectation?.fulfill()
        })
        self.waitForExpectationsWithTimeout(20.0, handler:nil)
    }
    
    func testCreateContainer() {
        let testName = "testCreateContainer"
        authenticate(testName, onSuccess: {
            self.objectStorageClient.createContainer(self.containerName, onSuccess: { (name: String) in
                print("\(testName) succeeded.")
                XCTAssertNotNil(name)
                XCTAssertEqual(name, self.containerName)
                self.xctExpectation?.fulfill()
                }, onFailure: { (error) in
                    print("\(testName) failed!")
                    print("error: \(error)")
                    XCTFail(error)
                    self.xctExpectation?.fulfill()
            })
        })
        self.waitForExpectationsWithTimeout(50.0, handler:nil)
    }
    
    func testUploadImage() {
        let testName = "testUploadImage"
        authenticate(testName, onSuccess: {
            let imageName = "ibm-icon.jpeg"
            let image = UIImage(named : "ibm-icon")
            XCTAssertNotNil(image)
            self.objectStorageClient.uploadImage(self.containerName, imageName: imageName, image: image!,
                onSuccess: { (imageURL: String) in
                    print("\(testName) succeeded.")
                    XCTAssertNotNil(imageURL)
                    print("imageURL: \(imageURL)")
                    XCTAssertEqual("\(self.publicURL)/\(self.containerName)/\(imageName)",imageURL)
                    self.xctExpectation?.fulfill()
                }, onFailure: { (error) in
                    print("\(testName) failed!")
                    print("error: \(error)")
                    XCTFail(error)
                    self.xctExpectation?.fulfill()
            })
        })
        self.waitForExpectationsWithTimeout(50.0, handler:nil)    }
    
    /**
     * Convenience method for authenticating.
     */
    func authenticate(testName: String, onSuccess: () -> Void) {
        objectStorageClient.authenticate({() in
            onSuccess()
            }, onFailure: {(error) in
                print("\(testName) failed!")
                print("error: \(error)")
                XCTFail(error)
                self.xctExpectation?.fulfill()
        })
    }
    
}
