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
        // Put setup code here. This method is called before the invocation of each test method in the class.
        CloudantSyncClient.SharedInstance!.dbName = Utils.getKeyFromPlist("keys", key: "cdt_db_name")
        //imagename : Caption from asset directory
        self.imageNames = [
            "photo1": "Mountains",
            "photo2": "Fog",
            "photo3": "Island"]
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    
    // Run this test to upload an image to object storage, create the picture document locally, and push that document to cloudant.
    func testPrePopulate() {
        
        
        xctExpectation = self.expectationWithDescription("Asynchronous request about to occur...")
        // Create fake user
        let id = "1234"
        let name = "Mobile Innovation Lab"
        do {
            try CloudantSyncClient.SharedInstance!.createProfileDoc(id, name: name)
        } catch {
            print("testPrePopulate ERROR: \(error)")
        }
        
        // Authenticate
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
            try CloudantSyncClient.SharedInstance!.pushToRemoteDatabase()
        } catch {
            print("testPrePopulate ERROR: \(error)")
        }
        self.waitForExpectationsWithTimeout(100.0, handler:nil)
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
                    try CloudantSyncClient.SharedInstance!.createPictureDoc(caption, fileName: imageName, url: imageURL, ownerID: FBUserID, width: "\(image.size.width)", height: "\(image.size.height)", orientation: "\(image.imageOrientation.rawValue)")
                } catch {
                    print(error)
                }
                
                imageCount-- //decrement number of images to upload remaining
                //check if test is done (all photos uploaded)
                if (imageCount == 0) {
                    try CloudantSyncClient.SharedInstance!.pushToRemoteDatabase()
                    self.xctExpectation?.fulfill() //test is done if all images added
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
