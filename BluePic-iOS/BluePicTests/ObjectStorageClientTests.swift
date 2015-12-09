//
//  ObjectStorageClientTests.swift
//  BluePic
//
//  For more infor on how to write test methods that test async functionality, please see the following URLs:
//     http://nshipster.com/xctestcase/
//     https://www.bignerdranch.com/blog/asynchronous-testing-with-xcode-6/
//
//  Created by Ricardo Olivieri on 11/17/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import XCTest
@testable import BluePic

/**
 * Test class for the ObjectStorageClient class.
 */
class ObjectStorageClientTests: XCTestCase {
    
    var objectStorageClient: ObjectStorageClient!
    var xctExpectation:XCTestExpectation?
    let containerName = "test-container"
    let publicURL = Utils.getKeyFromPlist("keys", key: "obj_stg_public_url")
    
    override func setUp() {
        super.setUp()
        
        // Set up connection properties for Object Storage service on Bluemix
        let password = Utils.getKeyFromPlist("keys", key: "obj_stg_password")
        let userId = Utils.getKeyFromPlist("keys", key: "obj_stg_user_id")
        let projectId = Utils.getKeyFromPlist("keys", key: "obj_stg_project_id")
        let authURL = Utils.getKeyFromPlist("keys", key: "obj_stg_auth_url")
        
        // Init variables for test execution
        objectStorageClient = ObjectStorageClient(userId: userId, password: password, projectId: projectId, authURL: authURL, publicURL: publicURL)
        xctExpectation = self.expectationWithDescription("Asynchronous request about to occur...")
    }
    
    override func tearDown() {
        super.tearDown()
        objectStorageClient = nil
        xctExpectation = nil
    }
    
    /**
     * Tests authentication against the Object Storage service. 
     * If the credentials used are invalid, authentication will fail and, as a consequence, this test method will also fail.
     */
    func testAuthenticate() {
        let testName = "testAuthenticate"
        authenticate(testName, onSuccess: {
            print("\(testName) succeeded.")
            self.xctExpectation?.fulfill()
        })
        self.waitForExpectationsWithTimeout(20.0, handler:nil)
    }
    
    /**
     * Tests the creation of a container on the Object Storage service.
     * If the credentials used are invalid, authentication will fail and, as a consequence, this test method will also fail.
     */
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
    
    /**
     * Tests uploading an image to the Object Storage service.
     * If the credentials used are invalid, authentication will fail and, as a consequence, this test method will also fail.
     */
    func testUploadImage() {
        let testName = "testUploadImage"
        authenticate(testName, onSuccess: {
            let imageName = "puppy.png"
            let image = UIImage(named : "puppy")
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
        self.waitForExpectationsWithTimeout(50.0, handler:nil)
    }
    
    /**
     * Tests uploading an image to the Object Storage service.
     * If the credentials used are invalid, authentication will fail and, as a consequence, this test method will also fail.
     */
    func testUploadImageToInvalidContainer() {
        let testName = "testUploadImageToInvalidContainer"
        authenticate(testName, onSuccess: {
            let imageName = "puppy.png"
            let image = UIImage(named : "puppy")
            XCTAssertNotNil(image)
            self.objectStorageClient.uploadImage("invalid-container-name", imageName: imageName, image: image!,
                onSuccess: { (imageURL: String) in
                    print("\(testName) failed! Somehow you uploaded an image to a container that does not exist!")
                    self.xctExpectation?.fulfill()
                }, onFailure: { (error) in
                    print("\(testName) succeeded.")
                    self.xctExpectation?.fulfill()
            })
        })
        self.waitForExpectationsWithTimeout(50.0, handler:nil)
    }
    
    /**
     * Tests that without an authenticaed user, no action can be performed.
     */
    func testNonAuthenticated() {
        XCTAssertFalse(self.objectStorageClient.isAuthenticated())
        self.objectStorageClient.createContainer(self.containerName,
            onSuccess: {(containerName: String) in
                XCTFail("Somehow the client was able to complete the call though it was not authenticated...")
                self.xctExpectation?.fulfill()
            },
            onFailure: {(error: String) in
                XCTAssertNotNil(error)
                self.xctExpectation?.fulfill()
        })
        self.waitForExpectationsWithTimeout(50.0, handler:nil)
    }
    
    /**
     * Convenience method for authenticating. This method is leveraged by each one of the test methods.
     */
    func authenticate(testName: String, onSuccess: () -> Void) {
        objectStorageClient.authenticate({() in
            XCTAssertTrue(self.objectStorageClient.isAuthenticated())
            onSuccess()
            }, onFailure: {(error) in
                print("\(testName) failed!")
                print("error: \(error)")
                XCTFail(error)
                self.xctExpectation?.fulfill()
        })
    }
    
}
