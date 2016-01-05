//
//  DataController.swift
//  BluePic
//
//  Created by Ira Rosen on 29/12/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import Foundation

import Alamofire


class PhotosDataManager {
    
    static var host = "localhost"
    static var port = 8090
    
    static var localPictures = [Picture]()
    static var dbPictures = [Picture]()
    
    
    class func getPictureObjects() -> [Picture] {
        return localPictures + dbPictures
    }
    
    
    class func getFeedData (owner: String = "", callback: ([Picture]?, String?) -> ()) {
        let nsURL = NSURL(string: "http://\(PhotosDataManager.host):\(PhotosDataManager.port)/photos")!
        let mutableURLRequest = NSMutableURLRequest(URL: nsURL)
        mutableURLRequest.HTTPMethod = "GET"
        
        Alamofire.request(mutableURLRequest).responseJSON {response in
            switch response.result {
            case .Success(let JSON):
                print("Success with JSON: \(JSON)")
                if let photos = JSON as? [[String:String]] {
                    var pictureObjects = [Picture]()
                    for photo in photos {
                        if (owner == "" || photo["owner"] == owner) {
                            let newPicture = Picture()
                            newPicture.url = photo["picturePath"]
                            newPicture.displayName = photo["title"]
                            newPicture.timeStamp = createTimeStamp(photo["date"]!)
                            newPicture.ownerName = photo["owner"]
                            pictureObjects.append(newPicture)
                        }
                    }
                    dbPictures = pictureObjects
                    callback(pictureObjects, nil)                    
                }
                else {
                    callback(nil, "Failed to read response Json body")
                }
                
            case .Failure(let error):
                print("Request failed with error: \(error)")
                callback(nil, error.description)
            }
        }
    }
    
    
    class private func createTimeStamp(dateString: String) -> Double {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = dateFormatter.dateFromString(dateString) {
            return date.timeIntervalSinceReferenceDate
        }
        else {
            return 0
        }        
    }
    
    
    class func getPicture (url: String, onSuccess: (pic: NSData) -> Void, onFailure: (error: String) -> Void) {
        if let nsURL = NSURL(string: "http://\(host):\(port)/photos/\(url)") {
            print("Bringing picture from db - TODO: caching?")
            let mutableURLRequest = NSMutableURLRequest(URL: nsURL)
            mutableURLRequest.HTTPMethod = "GET"
            
            Alamofire.request(mutableURLRequest).responseData{response in
                switch response.result {
                case .Success(let data):
                    print("Success with data")
                    onSuccess(pic: data)
                    
                case .Failure(let error):
                    print("Request failed with error: \(error)")
                    onFailure(error: error.description)
                }
                
            }
        }
    }
    
    
    class func uploadPicture(owner: String, picture: Picture, onSuccess:  () -> Void, onFailure: (error: String) -> Void) {
        var title = "Untitled"
        if let displayName = picture.displayName where displayName.characters.count != 0 {
            title = displayName
            print ("title: \(title) displayName: \(picture.displayName!)")
        }
        
        print ("title: \(title)")
        
        let imageData = UIImageJPEGRepresentation(picture.image!, 1.0)
        let nsURL = NSURL(string: "http://\(PhotosDataManager.host):\(PhotosDataManager.port)/photos/\(FacebookDataManager.SharedInstance.fbUniqueUserID!)/\(title)/\(picture.fileName!)")!
        let mutableURLRequest = NSMutableURLRequest(URL: nsURL)
        mutableURLRequest.HTTPMethod = "POST"
        mutableURLRequest.addValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.HTTPBody = imageData
        
        
        print("uploading photo: \(nsURL)")
        
        Alamofire.request(mutableURLRequest).responseJSON {response in
            switch response.result {
            case .Success(let JSON):
                print("upload: Success with JSON: \(JSON)")
                if let photo = JSON as? [String:String] {
                    let newPicture = Picture()
                    newPicture.url = photo["picturePath"]
                    newPicture.displayName = photo["title"]
                    newPicture.timeStamp = createTimeStamp(photo["date"]!)
                    newPicture.ownerName = photo["owner"]
                    dbPictures.append(newPicture)
                    onSuccess()
                }
                else {
                    onFailure(error: "upload: Failed to read response Json body")
                }
                
            case .Failure(let error):
                print("Request failed with error: \(error)")
                onFailure(error: error.description)
            }
        }
    }
 }