/**
 * Copyright IBM Corporation 2016
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

import UIKit
import BMSCore

enum BlueMixDataManagerError: ErrorType {
    //error when the user does not exist when we attempt to get the user by id
    case UserDoesNotExist

    //error when there is a connection failure when doing a REST call
    case ConnectionFailure
}

enum BluemixDataManagerNotification: String {
    //Notification to notify the app that the REST call to get all images has started
    case GetAllImagesStarted = "GetAllImagesStarted"

    //Notification to notify the app that repulling for images has completed, the images have been refreshed
    case ImagesRefreshed = "ImagesRefreshed"

    //Notification to notify the app that uploading an image has began
    case ImageUploadBegan = "ImageUploadBegan"

    //Notification to nofify the app that Image upload was successfull
    case ImageUploadSuccess = "ImageUploadSuccess"

    //Notification to notify the app that image upload failed
    case ImageUploadFailure = "ImageUploadFailure"

    //Notification to notify the app that the popular tags were receieved
    case PopularTagsReceived = "PopularTagsReceived"
}

class BluemixDataManager: NSObject {

    //Make BluemixDataManager a singlton
    static let SharedInstance: BluemixDataManager = {

        var manager = BluemixDataManager()

        return manager

    }()

    //holds all images for the app
    var images = [Image]()

    //filters images variable to only images taken by the user
    var currentUserImages: [Image] {
        get {
            if let currentUserFbId = CurrentUser.facebookUserId {
                return images.filter({ $0.user.facebookID == currentUserFbId})
            } else {
                return []
            }
        }
    }

    /// photos that were taken during this app session
    var imagesTakenDuringAppSessionById = [String : UIImage]()

    //array that stores all the images currently being uploaded. This is used to show the images currently posting on the feed
    var imagesCurrentlyUploading: [Image] = []

    //array that stores all the images that failed to upload. This is used so users can rety try uploading images that failed.
    var imagesThatFailedToUpload: [Image] = []

    //stores the most popular tags
    var tags = [String]()

    //stores all the bluemix configuration setup
    let bluemixConfig = BluemixConfiguration()

    //End Points
    private let kImagesEndPoint = "images"
    private let kUsersEndPoint = "users"
    private let kTagsEndPoint = "tags"

    //used to help the feed view model decide to show the loading animaiton on the feed vc
    var hasReceievedInitialImages = false

    /**
     Method initilizes the BMSClient
     */
    func initilizeBluemixAppRoute() {

        BMSClient.sharedInstance
            .initializeWithBluemixAppRoute(bluemixConfig.remoteBaseRequestURL,
                                           bluemixAppGUID: bluemixConfig.appGUID,
                                           bluemixRegion: bluemixConfig.appRegion)

    }

    /**
     Method gets the Bluemix base request URL depending on if the isLocal key is set in the plist or not

     - returns: String
     */
    func getBluemixBaseRequestURL() -> String {

        if bluemixConfig.isLocal {
            return bluemixConfig.localBaseRequestURL
        } else {
            return bluemixConfig.remoteBaseRequestURL
        }
    }

}

// MARK: - Methods related to getting/creating users
extension BluemixDataManager {

    /**
     Method gets user by id and will return the parsed response in the result callback

     - parameter userId: String
     - parameter result: (user : User?, error : BlueMixDataManagerError?) -> ()
     */
    func getUserById(userId: String, result: (user: User?, error: BlueMixDataManagerError?) -> ()) {

        let requestURL = getBluemixBaseRequestURL() + "/" + kUsersEndPoint + "/" + userId

        let request = Request(url: requestURL, method: HttpMethod.GET)

        request.sendWithCompletionHandler { (response, error) -> Void in
            //error
            if error != nil {
                if let response = response,
                    let statusCode = response.statusCode {

                    //user does not exist
                    if statusCode == 404 {
                        result(user: nil, error: BlueMixDataManagerError.UserDoesNotExist)
                    }
                        //any other error code means that it was a connection failure
                    else {
                        result(user: nil, error: BlueMixDataManagerError.ConnectionFailure)
                    }

                }
                    //connection failure
                else {
                    result(user: nil, error: BlueMixDataManagerError.ConnectionFailure)
                }
            }
                //No error
            else {
                //success
                if let user = User(response) {
                    result(user: user, error: nil)
                }
                    //can't parse response - error
                else {
                    result(user: nil, error: BlueMixDataManagerError.ConnectionFailure)
                }
            }
        }
    }


    /**
     Method creates a new user and returns the parsed response in the result callback

     - parameter userId: String
     - parameter name:   String
     - parameter result: ((user : User?) -> ())
     */
    private func createNewUser(userId: String, name: String, result : ((user: User?) -> ())) {

        let requestURL = getBluemixBaseRequestURL() + "/" + kUsersEndPoint

        let request = Request(url: requestURL, method: HttpMethod.POST)

        let json = ["_id": userId, "name": name]

        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)

            request.sendData(jsonData, completionHandler: { (response, error) -> Void in
                if let error = error {
                    result(user: nil)
                    print ("Create New User Error: \(error)")
                } else {
                    if let user = User(response) {
                        result(user: user)
                    } else {
                        result(user: nil)
                        print("Create New User Error: Response didn't contain all the necessary values")
                    }
                }
            })

        } catch {
            result(user: nil)

        }

    }


    /**
     Method checks to see if a user already exists, if the user doesn't exist then it creates a new user. It will return the parsed response in the callback parameter

     - parameter userId:   String
     - parameter name:     String
     - parameter callback: ((success : Bool) -> ())
     */
    func checkIfUserAlreadyExistsIfNotCreateNewUser(userId: String, name: String, callback : ((success: Bool) -> ())) {

        getUserById(userId, result: { (user, error) in

            if let error = error {

                //user does not exist so create new user
                if error == BlueMixDataManagerError.UserDoesNotExist {
                    self.createNewUser(userId, name: name, result: { user in

                        if user != nil {
                            callback(success: true)
                        } else {
                            callback(success: false)
                        }

                    })
                } else if error == BlueMixDataManagerError.ConnectionFailure {
                    callback(success: false)
                }
            } else {
                callback(success: true)
            }

        })
    }

}

// MARK: - Methods related to gettings images
extension BluemixDataManager {

    /**
     Method gets all the images posted on BluePic. When this request begins, the GetAllImagesStarted BluemixDataManagerNotification is sent out to the app. When the images have been successfully received, the ImagesRefreshed BluemixDataManagerNotification will be sent out
     */
    func getImages() {

        NSNotificationCenter.defaultCenter().postNotificationName(BluemixDataManagerNotification.GetAllImagesStarted.rawValue, object: nil)

        let requestURL = getBluemixBaseRequestURL() + "/" + kImagesEndPoint
        let request = Request(url: requestURL, method: HttpMethod.GET)

        self.getImages(request) { images in

            if let images = images {
                self.images = images
                self.hasReceievedInitialImages = true
                NSNotificationCenter.defaultCenter().postNotificationName(BluemixDataManagerNotification.ImagesRefreshed.rawValue, object: nil)
            }
        }
    }

    /**
     Method gets all the images by the specified tags in the tags parameter. When a response is receieved, we pass back the images we receive in the callback parameter

     - parameter tags:     [String]
     - parameter callback: (images : [Image]?)->()
     */
    func getImagesByTags(tags: [String], callback : (images: [Image]?)->()) {

        var requestURL = getBluemixBaseRequestURL() + "/" + kImagesEndPoint + "?tag="
        for (index, tag) in tags.enumerate() {

            guard let encodedTag = tag.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) else {
                print("Failed to encode search tag")
                continue
            }

            if index == 0 {
                requestURL.appendContentsOf(encodedTag.lowercaseString)
            } else {
                requestURL.appendContentsOf(",\(encodedTag.lowercaseString)")
            }
        }
        let request = Request(url: requestURL, method: HttpMethod.GET)

        self.getImages(request) { images in
            callback(images: images)
        }

    }

    /**
     Helper method to getImages and getImagesByTags method. It makes the request and then parses the response into an image array, then passes back response in result parameter

     - parameter request: Request
     - parameter result:  (images : [Image]?)-> ()
     */
    func getImages(request: Request, result : (images: [Image]?)-> ()) {

        request.sendWithCompletionHandler { (response, error) -> Void in
            if let error = error {
                result(images: nil)
                print ("Error :: \(error)")
            } else {
                let images = self.parseGetImagesResponse(response, userId: nil, usersName: nil)
                result(images: images)
            }
        }

    }


    /**
     Method parses the getImages response and returns an array of images

     - parameter response:  Response?
     - parameter userId:    String?
     - parameter usersName: String?

     - returns: [Image]
     */
    private func parseGetImagesResponse(response: Response?, userId: String?, usersName: String?) -> [Image] {
        var images = [Image]()

        if let dict = Utils.convertResponseToDictionary(response),
            let records = dict["records"] as? [[String:AnyObject]] {

            for var record in records {

                if let userId = userId, let usersName = usersName {

                    var user = [String : AnyObject]()
                    user["name"] = usersName
                    user["_id"] = userId
                    record["user"] = user
                }

                if let image = Image(record) {
                    images.append(image)
                }
            }

        }
        return images
    }
}

// MARK: - Methods related to image uploading
extension BluemixDataManager {

    /**
     Method posts a new image. It will send the ImageUploadBegan notification when the image upload begins. It will send the ImageUploadSuccess notification when the image uploads successfully. For all other errors it will send out the ImageUploadFailure notification.

     - parameter image: Image
     */
    func postNewImage(image: Image) {

        addImageToImagesCurrentlyUploading(image)

        NSNotificationCenter.defaultCenter().postNotificationName(BluemixDataManagerNotification.ImageUploadBegan.rawValue, object: nil)

        guard let facebookId = CurrentUser.facebookUserId, uiImage = image.image, imageData = UIImagePNGRepresentation(uiImage) else {
            print("We don't have all the info necessary to post this image")
            NSNotificationCenter.defaultCenter().postNotificationName(BluemixDataManagerNotification.ImageUploadFailure.rawValue, object: nil)
            return
        }

        let tempURL = getBluemixBaseRequestURL() + "/" + kUsersEndPoint + "/" + facebookId + "/" + kImagesEndPoint + "/" + image.fileName + "/" + image.caption + "/" + "\(image.width)" + "/" + "\(image.height)" + "/" + "\(image.location.latitude)" + "/" + "\(image.location.longitude)" + "/" + image.location.name

        guard let requestURL = tempURL.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) else {
            print("Failed to encode request URL")
            NSNotificationCenter.defaultCenter().postNotificationName(BluemixDataManagerNotification.ImageUploadFailure.rawValue, object: nil)
            return
        }

        let request = Request(url: requestURL, method: HttpMethod.POST)

        request.headers = ["Content-Type" : "image/png"]

        request.sendData(imageData, completionHandler: { (response, error) -> Void in

            //failure
            if error != nil {

                self.removeImageFromImagesCurrentlyUploading(image)
                self.addImageToImagesThatFailedToUpload(image)

                NSNotificationCenter.defaultCenter().postNotificationName(BluemixDataManagerNotification.ImageUploadFailure.rawValue, object: nil)

            }
                //success
            else {

                self.addImageToImageTakenDuringAppSessionByIdDictionary(image)
                self.removeImageFromImagesCurrentlyUploading(image)

                NSNotificationCenter.defaultCenter().postNotificationName(BluemixDataManagerNotification.ImageUploadSuccess.rawValue, object: nil)

            }
        })

    }

}

// MARK: - Methods related to uploading images
extension BluemixDataManager {

    /**
     Method will retry to upload each image in the imagesThatFailedToUpload array
     */
    func retryUploadingImagesThatFailedToUpload() {

        for image in imagesThatFailedToUpload {
            removeImageFromImagesThatFailedToUpload(image)
            postNewImage(image)

        }

    }

    /**
     Method will remove each image in the imagesThatFailedToUpload array
     */
    func cancelUploadingImagesThatFailedToUpload() {

        for image in imagesThatFailedToUpload {
            removeImageFromImagesThatFailedToUpload(image)
        }

    }

    /**
     Method will add the image parameter to the imagesThatFailedToUpload array

     - parameter image: Image
     */
    private func addImageToImagesThatFailedToUpload(image: Image) {

        imagesThatFailedToUpload.append(image)

    }

    /**
     Method will remove the image parameter from the imagesThatFailedToUpload array

     - parameter image: Image
     */
    private func removeImageFromImagesThatFailedToUpload(image: Image) {

        imagesThatFailedToUpload = imagesThatFailedToUpload.filter({ $0 !== image})

    }

    /**
     Method will add the image parameter to the imagesCurrentlyUploading array

     - parameter image: Image
     */
    private func addImageToImagesCurrentlyUploading(image: Image) {

        imagesCurrentlyUploading.append(image)

    }

    /**
     Method will remove the image parameter from the imagesCurrentlyUploading array

     - parameter image: Image
     */
    private func removeImageFromImagesCurrentlyUploading(image: Image) {

        imagesCurrentlyUploading = imagesCurrentlyUploading.filter({ $0 !== image})

    }

    /**
     Method adds the photo to the imagesTakenDuringAppSessionById cache to display the photo in the image feed or profile feed while we wait for the photo to upload to.
     */
    private func addImageToImageTakenDuringAppSessionByIdDictionary(image: Image) {

        if let userID = CurrentUser.facebookUserId {

            let id = image.fileName + userID
            imagesTakenDuringAppSessionById[id] = image.image
        }
    }
}

// MARK: - Methods related to tags
extension BluemixDataManager {

    /**
     Method gets the most popular tags of BluePic. When tags receieved, it sends out the PopularTagsReceieved BluemixDataManagerNotification to the app
     */
    func getPopularTags() {

        let requestURL = getBluemixBaseRequestURL() + "/" + kTagsEndPoint
        let request = Request(url: requestURL, method: HttpMethod.GET)

        request.sendWithCompletionHandler { (response, error) -> Void in
            if let error = error {
                print ("Error :: \(error)")
            } else {
                if let text = response?.responseText, result = Utils.convertStringToDictionary(text), records = result["records"] as? [[String:AnyObject]] {
                    // Extract string tags from server results
                    self.tags = records.flatMap { value in
                        if let key = value["key"] as? String {
                            return key.uppercaseString
                        }
                        return nil
                    }
                    NSNotificationCenter.defaultCenter().postNotificationName(BluemixDataManagerNotification.PopularTagsReceived.rawValue, object: nil)
                }
            }
        }
    }
}
