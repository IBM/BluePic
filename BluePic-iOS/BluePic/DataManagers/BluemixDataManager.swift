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

enum BlueMixDataManagerError: Error {
    //error when the user does not exist when we attempt to get the user by id
    case userDoesNotExist

    //error when there is a connection failure when doing a REST call
    case connectionFailure
}

extension Notification.Name {
    //Notification to notify the app that the REST call to get all images has started
    static let getAllImagesStarted = Notification.Name("GetAllImagesStarted")

    //Notification to notify the app that repulling for images has completed, the images have been refreshed
    static let imagesRefreshed = Notification.Name("ImagesRefreshed")

    //Notification to notify the app that uploading an image has began
    static let imageUploadBegan = Notification.Name("ImageUploadBegan")

    //Notification to nofify the app that Image upload was successfull
    static let imageUploadSuccess = Notification.Name("ImageUploadSuccess")

    //Notification to notify the app that image upload failed
    static let imageUploadFailure = Notification.Name("ImageUploadFailure")

    //Notificaiton used when there was a server error getting all the images
    static let getAllImagesFailure = Notification.Name("GetAllImagesFailure")

    //Notification to notify the app that the popular tags were receieved
    static let popularTagsReceived = Notification.Name("PopularTagsReceived")
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
            return images.filter({ $0.user.facebookID == CurrentUser.facebookUserId})
        }
    }

    /// images that were taken during this app session (used to help make images appear faster in the image feed as we wait for the image to download from the url
    var imagesTakenDuringAppSessionById = [String : UIImage]()

    //array that stores all the images currently being uploaded. This is used to show the images currently posting on the feed
    var imagesCurrentlyUploading: [ImagePayload] = []

    //array that stores all the images that failed to upload. This is used so users can rety try uploading images that failed.
    var imagesThatFailedToUpload: [ImagePayload] = []

    //stores the most popular tags
    var tags = [String]()

    //stores all the bluemix configuration setup
    let bluemixConfig = BluemixConfiguration()

    //default timeout is 60 seconds
    fileprivate let kDefaultTimeOut: Double = 60

    //End Points
    fileprivate let kImagesEndPoint = "images"
    fileprivate let kUsersEndPoint = "users"
    fileprivate let kTagsEndPoint = "tags"
    fileprivate let kPingEndPoint = "ping"

    //used to help the feed view model decide to show the loading animaiton on the feed vc
    var hasReceievedInitialImages = false

    /**
     Method initilizes the BMSClient
     */
    func initilizeBluemixAppRoute() {

        BMSClient.sharedInstance.initialize(bluemixRegion: bluemixConfig.appRegion)
        BMSClient.sharedInstance.requestTimeout = 10.0

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
    func getUserById(_ userId: String, result: @escaping (_ user: User?, _ error: BlueMixDataManagerError?) -> ()) {

        let requestURL = getBluemixBaseRequestURL() + "/" + kUsersEndPoint + "/" + userId

        let request = Request(url: requestURL, method: HttpMethod.GET)

        request.timeout = kDefaultTimeOut

        request.send { response, error in
            //error
            if let error = error {
                if let response = response,
                    let statusCode = response.statusCode {

                    //user does not exist
                    if statusCode == 404 {

                        result(nil, BlueMixDataManagerError.userDoesNotExist)
                    }
                        //any other error code means that it was a connection failure
                    else {
                        print(NSLocalizedString("Get User By ID Error:", comment : "") + " \(error.localizedDescription)")
                        result(nil, BlueMixDataManagerError.connectionFailure)
                    }

                }
                    //connection failure
                else {
                    print(NSLocalizedString("Get User By ID Error:", comment : "") + " \(error.localizedDescription)")
                    result(nil, BlueMixDataManagerError.connectionFailure)
                }
            }
                //No error
            else {
                //success
                if let user = User(response) {
                    result(user, nil)
                }
                    //can't parse response - error
                else {
                    print(NSLocalizedString("Get User By ID Error: Invalid Response JSON)", comment: ""))
                    result(nil, BlueMixDataManagerError.connectionFailure)
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
    func createNewUser(_ userId: String, name: String, result : @escaping (_ user: User?) -> ()) {

        let requestURL = getBluemixBaseRequestURL() + "/" + kUsersEndPoint

        let request = Request(url: requestURL, method: HttpMethod.POST)

        request.timeout = kDefaultTimeOut

        let json = ["_id": userId, "name": name]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)

            request.send(requestBody: jsonData) { response, error in
                if let error = error {
                    result(nil)
                    print(NSLocalizedString("Create New User Error:)", comment: "") + " \(error.localizedDescription)")
                } else {
                    if let user = User(response) {
                        result(user)
                    } else {
                        result(nil)
                        print(NSLocalizedString("Create New User Error: Invalid Response JSON", comment: ""))
                    }
                }
            }

        } catch {
            print(NSLocalizedString("Create New User Error", comment: ""))
            result(nil)
        }

    }


    /**
     Method checks to see if a user already exists, if the user doesn't exist then it creates a new user. It will return the parsed response in the callback parameter

     - parameter userId:   String
     - parameter name:     String
     - parameter callback: ((success : Bool) -> ())
     */
    func checkIfUserAlreadyExistsIfNotCreateNewUser(_ userId: String, name: String, callback : @escaping ((_ success: Bool) -> ())) {

        getUserById(userId, result: { (user, error) in

            if let error = error {

                //user does not exist so create new user
                if error == BlueMixDataManagerError.userDoesNotExist {
                    self.createNewUser(userId, name: name, result: { user in

                        if user != nil {
                            callback(true)
                        } else {
                            callback(false)
                        }

                    })
                } else if error == BlueMixDataManagerError.connectionFailure {
                    print(NSLocalizedString("Check If User Already Exists Error: Connection Failure", comment: ""))
                    callback(false)
                }
            } else {
                callback(true)
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

        NotificationCenter.default.post(name: .getAllImagesStarted, object: nil)

        let requestURL = getBluemixBaseRequestURL() + "/" + kImagesEndPoint
        let request = Request(url: requestURL, method: HttpMethod.GET)

        self.getImages(request) { images in

            if let images = images {
                self.images = images
                self.hasReceievedInitialImages = true
                NotificationCenter.default.post(name: .imagesRefreshed, object: nil)
            } else {
                print(NSLocalizedString("Get Images Error: Connection Failure", comment: ""))
                self.hasReceievedInitialImages = true
                NotificationCenter.default.post(name: .getAllImagesFailure, object: nil)
            }
        }
    }

    /**
     Method gets all the images by the specified tags in the tags parameter. When a response is receieved, we pass back the images we receive in the callback parameter

     - parameter tags:     [String]
     - parameter callback: (images : [Image]?)->()
     */
    func getImagesByTags(_ tags: [String], callback : @escaping (_ images: [Image]?)->()) {

        var requestURL = getBluemixBaseRequestURL() + "/" + kImagesEndPoint + "?tag="
        for (index, tag) in tags.enumerated() {

            guard let encodedTag = tag.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
                print(NSLocalizedString("Get Images By Tags Error: Failed to encode search tag", comment: ""))
                continue
            }

            if index == 0 {
                requestURL.append(encodedTag.lowercased())
            } else {
                requestURL.append(",\(encodedTag.lowercased())")
            }
        }
        let request = Request(url: requestURL, method: HttpMethod.GET)

        self.getImages(request) { images in
            callback(images)
        }

    }

    /**
     Helper method to getImages and getImagesByTags method. It makes the request and then parses the response into an image array, then passes back response in result parameter

     - parameter request: Request
     - parameter result:  (images : [Image]?)-> ()
     */
    func getImages(_ request: Request, result : @escaping (_ images: [Image]?) -> ()) {

        request.timeout = kDefaultTimeOut

        request.send { response, error in
            if let error = error {
                print(NSLocalizedString("Get Images Error:", comment: "") + " \(error.localizedDescription)")
                result(nil)
            } else {
                let images = self.parseGetImagesResponse(response, userId: nil, usersName: nil)
                result(images)
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
    fileprivate func parseGetImagesResponse(_ response: Response?, userId: String?, usersName: String?) -> [Image] {
        var images = [Image]()

        if let dict = Utils.convertResponseToDictionary(response),
             let records = dict["records"] as? [[String: Any]] {

            for var record in records {

                if let userId = userId, let usersName = usersName {

                    var user = [String: String]()
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
     Method pings service and will be challanged if the app has MCA configured but the user hasn't signed in yet.

     - parameter callback: (response: Response?, error: Error?) -> Void
     */
    fileprivate func ping(_ callback : @escaping (_ response: Response?, _ error: Error?) -> Void) {

        let requestURL = getBluemixBaseRequestURL() + "/" + kPingEndPoint

        let request = Request(url: requestURL, method: HttpMethod.GET)

        request.timeout = kDefaultTimeOut

        request.send { response, error in
            callback(response, error)
        }

    }


    /**
     Method will first call the ping method, to force the user to login with Facebook (if MCA is configured). When we get a reponse, if we have the Facebook userIdentity, then this means the user succuessfully logged into Facebook (and MCA is configured). We will then try to create a new user and when this is succuessful we finally call the postNewImage method. If we don't have the Facebook user Identity, then this means MCA isn't configured and we will continue by calling the postNewImage method.

     - parameter image: Image
     */
    func tryToPostNewImage(_ image: ImagePayload) {

        addImageToImagesCurrentlyUploading(image)
        NotificationCenter.default.post(name: .imageUploadBegan, object: nil)

        //ping backend to trigger Facebook login if MCA is configured
        ping({ (response, error) -> Void in

            //either there was a network failure, user authentication with facebook failed, or user authentication with facebook was canceled by the user
            if let _ = error {
                print(NSLocalizedString("Try To Post New Image Error: Ping failed", comment: ""))
                self.handleImageUploadFailure(image)

            }
            //successfully pinged service
            else {
                //Check if User Authenticated with Facebook (aka is MCA configured)
                if let userIdentity = FacebookDataManager.SharedInstance.getFacebookUserIdentity(), let facebookUserId = userIdentity.ID, let facebookUserFullName = userIdentity.displayName {

                    //User is authenticated with Facebook, create new user record
                    self.createNewUser(facebookUserId, name: facebookUserFullName, result: { user in

                        if let _ = user {

                            CurrentUser.facebookUserId = facebookUserId
                            CurrentUser.fullName = facebookUserFullName
                            //User Authentication complete, ready to post image
                            self.postNewImage(image)

                        }
                        //Something went wrong creating new user
                        else {
                            print(NSLocalizedString("Try To Post New Image Error: Something went wrong calling create a new user", comment: ""))
                            self.handleImageUploadFailure(image)
                        }
                    })

                }
                //MCA is not configured
                else {
                    self.postNewImage(image)
                }
            }
        })

    }


    /**
     Method posts a new image. It will send the ImageUploadBegan notification when the image upload begins. It will send the ImageUploadSuccess notification when the image uploads successfully. For all other errors it will send out the ImageUploadFailure notification.

     - parameter image: Image
     */
    fileprivate func postNewImage(_ image: ImagePayload) {

        guard let uiImage = image.image, let imageData = UIImagePNGRepresentation(uiImage) else {
            print(NSLocalizedString("Post New Image Error: Could not process image data properly", comment: ""))
            NotificationCenter.default.post(name: .imageUploadFailure, object: nil)
            return
        }

        let requestURL = getBluemixBaseRequestURL() + "/" + kImagesEndPoint
        let imageDictionary = ["fileName": image.fileName, "caption" : image.caption, "width" : image.width, "height" : image.height, "location" : ["name" : image.location.name, "latitude" : image.location.latitude, "longitude" : image.location.longitude]] as [String : Any]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: imageDictionary, options: JSONSerialization.WritingOptions(rawValue: 0))
            let boundary = generateBoundaryString()
            let mimeType = ("application/json", "image/png")
            let request = Request(url: requestURL, method: HttpMethod.POST)
            request.headers = ["Content-Type" : "multipart/form-data; boundary=\(boundary)"]

            var body = Data()
            guard let boundaryStart = "--\(boundary)\r\n".data(using: String.Encoding.utf8),
                let dispositionEncoding = "Content-Disposition:form-data; name=\"imageJson\"\r\n".data(using: String.Encoding.utf8),
                let typeEncoding = "Content-Type: \(mimeType.0)\r\n\r\n".data(using: String.Encoding.utf8),
                let imageDispositionEncoding = "Content-Disposition:form-data; name=\"imageBinary\"; filename=\"\(image.fileName)\"\r\n".data(using: String.Encoding.utf8),
                let imageTypeEncoding = "Content-Type: \(mimeType.1)\r\n\r\n".data(using: String.Encoding.utf8),
                let imageEndEncoding = "\r\n".data(using: String.Encoding.utf8),
                let boundaryEnd = "--\(boundary)--\r\n".data(using: String.Encoding.utf8) else {
                    print("Post New Image Error: Could not encode all values for multipart data")
                    NotificationCenter.default.post(name: .imageUploadFailure, object: nil)
                    return
            }
            body.append(boundaryStart)
            body.append(dispositionEncoding)
            body.append(typeEncoding)
            body.append(jsonData)
            body.append(boundaryStart)
            body.append(imageDispositionEncoding)
            body.append(imageTypeEncoding)
            body.append(imageData)
            body.append(imageEndEncoding)
            body.append(boundaryEnd)

            request.timeout = kDefaultTimeOut

            request.send(requestBody: body) { response, error in

                //failure
                if let error = error {
                    print(NSLocalizedString("Post New Image Error:", comment: "") + " \(error.localizedDescription)")

                    self.handleImageUploadFailure(image)
                }
                //success
                else {
                    self.addImageToImageTakenDuringAppSessionByIdDictionary(image)
                    self.removeImageFromImagesCurrentlyUploading(image)

                    NotificationCenter.default.post(name: .imageUploadSuccess, object: nil)
                }
            }

        } catch {
            print("Error converting image dictionary to Json")
        }
    }

    func generateBoundaryString() -> String {
        return "Boundary-\(UUID().uuidString)"
    }


    /**
     Method handles when there is an image upload failure. It will remove the image that was uploading from the imagesCurrentlyUploading array, and then will add the image to the imagesThatFailedToUpload array. Finally it will notify the rest of the app with the BluemixDataManagerNotification.ImageUploadFailure notification

     - parameter image: Image
     */
    fileprivate func handleImageUploadFailure(_ image: ImagePayload) {

        self.removeImageFromImagesCurrentlyUploading(image)
        self.addImageToImagesThatFailedToUpload(image)

        NotificationCenter.default.post(name: .imageUploadFailure, object: nil)

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
            tryToPostNewImage(image)

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
    fileprivate func addImageToImagesThatFailedToUpload(_ image: ImagePayload) {

        imagesThatFailedToUpload.append(image)

    }

    /**
     Method will remove the image parameter from the imagesThatFailedToUpload array

     - parameter image: Image
     */
    fileprivate func removeImageFromImagesThatFailedToUpload(_ image: ImagePayload) {

        imagesThatFailedToUpload = imagesThatFailedToUpload.filter({ $0 != image})

    }

    /**
     Method will add the image parameter to the imagesCurrentlyUploading array

     - parameter image: Image
     */
    fileprivate func addImageToImagesCurrentlyUploading(_ image: ImagePayload) {

        imagesCurrentlyUploading.append(image)

    }

    /**
     Method will remove the image parameter from the imagesCurrentlyUploading array

     - parameter image: Image
     */
    fileprivate func removeImageFromImagesCurrentlyUploading(_ image: ImagePayload) {

        imagesCurrentlyUploading = imagesCurrentlyUploading.filter({ $0 != image})

    }

    /**
     Method adds the photo to the imagesTakenDuringAppSessionById cache to display the photo in the image feed or profile feed while we wait for the photo to upload to.
     */
    fileprivate func addImageToImageTakenDuringAppSessionByIdDictionary(_ image: ImagePayload) {

        let id = image.fileName + CurrentUser.facebookUserId
        imagesTakenDuringAppSessionById[id] = image.image

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

        request.timeout = kDefaultTimeOut

        request.send { response, error in
            if let error = error {
                print(NSLocalizedString("Get Popular Tags Error:", comment: "") + " \(error.localizedDescription)")
            } else {
                if let text = response?.responseText, let result = Utils.convertStringToDictionary(text), let records = result["records"] as? [[String: Any]] {
                    // Extract string tags from server results
                    self.tags = records.flatMap { value in
                        if let key = value["key"] as? String {
                            return key.uppercased()
                        }
                        return nil
                    }
                    NotificationCenter.default.post(name: .popularTagsReceived, object: nil)
                }
            }
        }
    }
}
