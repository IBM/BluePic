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
    case DocDoesNotExist
    case UserDoesNotExist
    case ConnectionFailure
}

enum BluemixDataManagerNotification : String {
    case GetAllImagesStarted = "GetAllImagesStarted"
    case ImagesRefreshed = "ImagesRefreshed"
    case ImageUploadBegan = "ImageUploadBegan"
    case ImageUploadSuccess = "ImageUploadSuccess"
    case ImageUploadFailure = "ImageUploadFailure"
    case PopularTagsReceived = "PopularTagsReceived"
}


class BluemixDataManager: NSObject {
    
    static let SharedInstance: BluemixDataManager = {
        
        var manager = BluemixDataManager()
        
        return manager
        
    }()
    
    //Data Variables
    var images = [Image]()
    
    var searchResultImages = [Image]()
    
    var currentUserImages : [Image] {
        get {
            if let currentUserFbId = CurrentUser.facebookUserId {
                return images.filter({ $0.user?.facebookID == currentUserFbId})
            }
            else{
                return []
            }
        }
    }
    
    /// photos that were taken during this app session
    var imagesTakenDuringAppSessionById = [String : UIImage]()
    
 
    var imagesCurrentlyUploading : [Image] = []
    var imagesThatFailuredToUpload : [Image] = []
    
    var tags = [String]()
    
    let bluemixConfig = BluemixConfiguration()
    
    //End Points
    private let kImagesEndPoint = "images"
    private let kUsersEndPoint = "users"
    private let kTagsEndPoint = "tags"
    
    //State Variables
    var hasReceievedInitialImages = false
    
    func initilizeBluemixAppRoute(){
        
        BMSClient.sharedInstance
            .initializeWithBluemixAppRoute(bluemixConfig.appRoute,
                                           bluemixAppGUID: bluemixConfig.appGUID,
                                           bluemixRegion: bluemixConfig.appRegion)
        
    }
    
    func getBluemixBaseRequestURL() -> String {
        
        if bluemixConfig.isLocal {
            return bluemixConfig.localBaseRequestURL
        }
        else{
            return bluemixConfig.remoteBaseRequestURL
        }
    }
    
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

    func getImages(){
        
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
    
    func getImagesByTags(tags: [String], callback : (images : [Image]?)->()) {
        
        var requestURL = getBluemixBaseRequestURL() + "/" + kImagesEndPoint + "?tag="
        for (index, tag) in tags.enumerate() {
            if index == 0 {
                requestURL.appendContentsOf(tag.lowercaseString)
            } else {
                requestURL.appendContentsOf(",\(tag.lowercaseString)")
            }
        }
        let request = Request(url: requestURL, method: HttpMethod.GET)
        
        self.getImages(request) { images in
            callback(images: images)
            
//            if let images = images {
//                self.searchResultImages = images
//                self.hasReceievedInitialImages = true
//                NSNotificationCenter.defaultCenter().postNotificationName(BluemixDataManagerNotification.ImagesRefreshed.rawValue, object: nil)
//            }
        }
        
    }
    
    func getImages(request: Request, result : (images : [Image]?)-> ()){

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
    
    func getImagesByUserId(userId : String, usersName : String, result : (images : [Image]?)-> ()){
        
        let requestURL = getBluemixBaseRequestURL() + "/" + kUsersEndPoint + "/" + userId + "/" + kImagesEndPoint
        let request = Request(url: requestURL, method: HttpMethod.GET)
        
        request.sendWithCompletionHandler { (response, error) -> Void in
            if let error = error {
                //result(images: nil)
                print ("Error :: \(error)")
            } else {
                
                let images = self.parseGetImagesResponse(response, userId: userId, usersName: usersName)
                result(images: images)
                
                let response = Utils.convertResponseToDictionary(response)
                print(response)
            }
        }
        
    }
    
    private func parseGetImagesResponse(response : Response?, userId : String?, usersName : String?) -> [Image]{
        var images = [Image]()
        
        if let dict = Utils.convertResponseToDictionary(response),
            let records = dict["records"] as? [[String:AnyObject]]{
            
            for var record in records {
                
                if let userId = userId, let usersName = usersName {
                    
                    var user = [String : AnyObject]()
                    user["name"] = usersName
                    user["_id"] = userId
                    record["user"] = user

                }
                
                
                if let image = Image(record){
                    images.append(image)
                }
            }
  
        }
        
        return images
    }
    
    
    func getUsers(){
        
        let requestURL = getBluemixBaseRequestURL() + "/" + kUsersEndPoint
        
        let request = Request(url: requestURL, method: HttpMethod.GET)
        
        request.sendWithCompletionHandler { (response, error) -> Void in
            if let error = error {
                print ("Error :: \(error)")
            } else {
                print ("Success :: \(response?.responseText)")
            }
        }
        
    }
    
    func getUserById(userId : String, result: (user : User?, error : BlueMixDataManagerError?) -> ()){
        
        let requestURL = getBluemixBaseRequestURL() + "/" + kUsersEndPoint + "/" + userId
        
        let request = Request(url: requestURL, method: HttpMethod.GET)
        
        request.sendWithCompletionHandler { (response, error) -> Void in
            if(error != nil){
                 if let response = response,
                    let statusCode = response.statusCode {
                    
                    //user does not exist
                    if(statusCode == 404){
                        result(user: nil, error: BlueMixDataManagerError.UserDoesNotExist)
                    }
                    //any other error code means that it was a connection failure
                    else{
                        result(user: nil, error: BlueMixDataManagerError.ConnectionFailure)
                    }
                    
                }
            //connection failure
                else{
                    result(user: nil, error: BlueMixDataManagerError.ConnectionFailure)
                }
            }
             else {
                if let user = User(response) {
                    result(user: user, error: nil)
                    print ("Success :: \(response?.responseText)")
                } else {
                    result(user: nil, error: BlueMixDataManagerError.ConnectionFailure)
                }
            }
        }
    }

    
    
    private func createNewUser(userId : String, name : String, language : String, unitsOfMeasurement : String, result : ((user : User?) -> ())){
        
        let requestURL = getBluemixBaseRequestURL() + "/" + kUsersEndPoint
        
        let request = Request(url: requestURL, method: HttpMethod.POST)
         
        let json = ["_id": userId, "name": name, "language" : language, "unitsOfMeasurement" : unitsOfMeasurement]

        do{
            let jsonData = try NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
            
            request.sendData(jsonData, completionHandler: { (response, error) -> Void in
                if let error = error {
                    result(user: nil)
                    print ("Error  Creating New User :: \(error)")
                } else {
                    if let user = User(response) {
                        result(user: user)
                        print ("Success :: \(response?.responseText)")
                    } else {
                        result(user: nil)
                        print("Response didn't contain all the necessary values")
                    }
                }
            })
            
        } catch {
            result(user: nil)
            
        }
        
    }
    
    
    func checkIfUserAlreadyExistsIfNotCreateNewUser(userId : String, name : String, language: String, unitsOfMeasurement : String, callback : ((success : Bool) -> ())){

        getUserById(userId, result: { (user, error) in
            
            if let error = error {
                
                //user does not exist so create new user
                if(error == BlueMixDataManagerError.UserDoesNotExist){
                    self.createNewUser(userId, name: name, language: language, unitsOfMeasurement: unitsOfMeasurement, result: { user in
                        
                        if(user != nil){
                            callback(success: true)
                        }
                        else{
                            callback(success: false)
                        }
                
                    })
                }
                else if(error == BlueMixDataManagerError.ConnectionFailure){
                    callback(success: false)
                }
            }
            else {
                callback(success: true)
            }

        })
    }
    

    
    func postNewImage(image : Image){
        
        addImageToImagesCurrentlyUploading(image)
        
        NSNotificationCenter.defaultCenter().postNotificationName(BluemixDataManagerNotification.ImageUploadBegan.rawValue, object: nil)
        
        let cityStateString = image.location!.city! + ", " + image.location!.state!
     
        let tempURL = getBluemixBaseRequestURL() + "/" + kUsersEndPoint + "/" + CurrentUser.facebookUserId! + "/" + kImagesEndPoint + "/" + image.fileName! + "/" + image.caption! + "/" + "\(image.width!)" + "/" + "\(image.height!)" + "/" + image.location!.latitude! + "/" + image.location!.longitude! + "/" + cityStateString
        
        let requestURL = tempURL.stringByAddingPercentEncodingWithAllowedCharacters( NSCharacterSet.URLQueryAllowedCharacterSet())!

        let request = Request(url: requestURL, method: HttpMethod.POST)
  
        request.headers = ["Content-Type" : "image/png"]
        
        print("beginning upload)")
        
        request.sendData(UIImagePNGRepresentation(image.image!)!, completionHandler: { (response, error) -> Void in
            
            //failure
            if(error != nil){
          
                print(requestURL)
                print(error)
                
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


//UPLOADING IMAGES
extension BluemixDataManager {

    func retryUploadingImagesThatFailedToUpload(){
        
        for image in imagesThatFailuredToUpload {
            removeImageFromImagesThatFailedToUpload(image)
            postNewImage(image)
   
        }
 
    }
    
    func cancelUploadingImagesThatFailedToUpload(){
        
        for image in imagesThatFailuredToUpload {
            removeImageFromImagesThatFailedToUpload(image) 
        }
        
    }
 
    
    private func addImageToImagesThatFailedToUpload(image : Image){
        
        imagesThatFailuredToUpload.append(image)
        
    }
    
    private func removeImageFromImagesThatFailedToUpload(image : Image){
        
        imagesThatFailuredToUpload = imagesThatFailuredToUpload.filter({ $0 !== image})
        
    }
    
    private func addImageToImagesCurrentlyUploading(image : Image){
        
        imagesCurrentlyUploading.append(image)
        
    }
    

    private func removeImageFromImagesCurrentlyUploading(image: Image){
        
        imagesCurrentlyUploading = imagesCurrentlyUploading.filter({ $0 !== image})
        
    }
    
    
    private func uploadImagesIfThereAreAnyLeftInTheQueue(){
        
        if(imagesCurrentlyUploading.count > 0){
            postNewImage(imagesCurrentlyUploading[0])
        }
    }
    
    /**
     Method adds the photo to the picturesTakenDuringAppSessionById cache to display the photo in the image feed while we wait for the photo to upload to.
     */
    private func addImageToImageTakenDuringAppSessionByIdDictionary(image : Image){
        
        if let fileName = image.fileName, let userID = CurrentUser.facebookUserId {
            
            let id = fileName + userID
            imagesTakenDuringAppSessionById[id] = image.image
            
        }
    }
    
}

