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

@testable import BluePic
import XCTest

class PopulateFeedWithPhotos: XCTestCase {
    
    var xctExpectation:XCTestExpectation?
    
    /// Names and captions of pre-populated images
    var imageNames: [String: String]!
    
    override func setUp() {
        super.setUp()
        //imagename : Caption from asset directory
        self.imageNames = [
            "photo1": "Mountains",
            "photo2": "Fog",
            "photo3": "Island"]
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    /**
     * Run this test to prepopulate the databases with 3 pictures and 1 user.
     */
    func testPrePopulate() {
        // Create fake user
        let id = "mskf8d7C-9F39-4558-9EBA-6E5474219jgr"
        let name = "Mobile Innovation Lab"
        
        // Only create user if it does NOT exist
        if ( !(CloudantSyncDataManager.SharedInstance!.doesExist(id)) ) {
            do {
                try CloudantSyncDataManager.SharedInstance!.createProfileDoc(id, name: name)
            } catch {
                print("testPrePopulate ERROR: \(error)")
                XCTFail()
            }
        }
        
        // Only prepopulate if user doesn't have any pictures
        let result = CloudantSyncDataManager.SharedInstance!.getPictureObjects(id)
        let num = result.count
        if (num == 0) {
            // User does NOT have any pictures, create images.
            // Authenticate
            xctExpectation = self.expectationWithDescription("Asynchronous request about to occur...")
            ObjectStorageDataManager.SharedInstance.objectStorageClient.authenticate({() in
                print("success authenticating with object storage!")
                // Create Container
                ObjectStorageDataManager.SharedInstance.objectStorageClient.createContainer(id,
                    onSuccess: { (name: String) in
                        print("CONTAINER CREATED")
                        print(name)
                        XCTAssertNotNil(name)
                        self.postPhotoForTests(name)
                    }, onFailure: { (error) in
                        print("error creating container: \(error)")
                        XCTFail(error)
                })
                }, onFailure: {(error) in
                    print("error authenticating with object storage: \(error)")
            })
            // Push document to remote Cloudant database
            do {
                let xctExpectation1 = self.expectationWithDescription("Asynchronous request about to occur...")
                CloudantSyncDataManager.SharedInstance!.pushDelegate = TestPushDelegate(xctExpectation: xctExpectation1)
                try CloudantSyncDataManager.SharedInstance!.pushToRemoteDatabase()
                self.waitForExpectationsWithTimeout(100.0,handler: nil)
            } catch {
                print("testPrePopulate ERROR: \(error)")
                XCTFail()
            }
        } else {
            // User has pictures, do nothing.
        }
    }
    
    /**
     For test method for pre-populating database with images
     */
    func postPhotoForTests(FBUserID: String!) {
        print("uploading photo to object storage...")
        var imageCount = self.imageNames.count //keep track of how many images left to upload
        
        for (picture_name, caption) in self.imageNames { //loop through all images
            let imageName = picture_name + ".JPG"
            let highResImage = UIImage(named : picture_name)
            print("original image width: \(highResImage!.size.width) height: \(highResImage!.size.height)")
            let image = UIImage.resizeImage(highResImage!, newWidth: 520)
            print("resized image width: \(image.size.width) height: \(image.size.height)")
            XCTAssertNotNil(image)
            
            // Upload Image
            //push to object storage, then on success push to cloudant sync
            ObjectStorageDataManager.SharedInstance.objectStorageClient.uploadImage(FBUserID, imageName: imageName, image: image,
                onSuccess: { (imageURL: String) in
                    XCTAssertNotNil(imageURL)
                    print("upload of \(imageName) to object storage succeeded.")
                    print("imageURL: \(imageURL)")
                    print("creating cloudant picture document...")
                    do {
                        try CloudantSyncDataManager.SharedInstance!.createPictureDoc(caption, fileName: imageName, url: imageURL, ownerID: FBUserID, width: "\(image.size.width)", height: "\(image.size.height)")
                    } catch {
                        print(error)
                        XCTFail("CreatePictureDoc() failed!")
                        self.xctExpectation?.fulfill()
                    }
                    imageCount-- //decrement number of images to upload remaining
                    //check if test is done (all photos uploaded)
                    if (imageCount == 0) {
                        do {
                            try CloudantSyncDataManager.SharedInstance!.pushToRemoteDatabase()
                            self.xctExpectation?.fulfill() //test is done if all images added
                        } catch {
                            print(error)
                            XCTFail("PushToRemoteDatabase() failed!")
                            self.xctExpectation?.fulfill()
                        }
                    }
                }, onFailure: { (error) in
                    print("upload to object storage failed!")
                    print("error: \(error)")
                    XCTFail(error)
                    self.xctExpectation?.fulfill()
            })
        }
    }
}