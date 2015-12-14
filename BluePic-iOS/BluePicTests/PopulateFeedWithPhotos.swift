//
//  PopulateFeedWithPhotos.swift
//  BluePic
//
//  Created by Nathan Hekman on 12/7/15.
//  Copyright © 2015 MIL. All rights reserved.
//

@testable import BluePic
import XCTest

class PopulateFeedWithPhotos: XCTestCase {
    
    var xctExpectation:XCTestExpectation?
    
    var imageNames: [String: String]!
    
    override func setUp() {
        super.setUp()
        // TODO: why are we setting the dbName here when it's already set?
        CloudantSyncDataManager.SharedInstance!.dbName = Utils.getKeyFromPlist("keys", key: "cdt_db_name")
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
                        try CloudantSyncDataManager.SharedInstance!.createPictureDoc(caption, fileName: imageName, url: imageURL, ownerID: FBUserID, width: "\(image.size.width)", height: "\(image.size.height)", orientation: "\(image.imageOrientation.rawValue)")
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