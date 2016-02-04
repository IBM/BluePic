/**
 * Copyright IBM Corporation 2015
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/


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
