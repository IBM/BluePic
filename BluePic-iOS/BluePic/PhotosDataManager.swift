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
    
//    private let host = "irar-mac.haifa.ibm.com"
//    private let port = 8090
    
    var serverUrl = ""
    
    static let SharedInstance:PhotosDataManager = {
        return PhotosDataManager()
    }()
    
    func connect (serverUrl: String, callback: (String?) -> ()) {
        print("IN CONNECT to ", serverUrl)
        self.serverUrl = serverUrl
        let nsURL = NSURL(string: "http://\(serverUrl)/connect")!
        let mutableURLRequest = NSMutableURLRequest(URL: nsURL)
        mutableURLRequest.HTTPMethod = "GET"
        
        Alamofire.request(mutableURLRequest).responseJSON {response in
            // Get http response status code
            var statusCode:Int = 0
            if let httpResponse = response.response {
                statusCode = httpResponse.statusCode
            }
            print("statusCode = \(statusCode)")
            // For a production app, we would need to verify if the auth token has expired;
            // if so, then the code should re-authenticate and retry the current operation
            // For this demo app, we did not get to implement this logic.
            
            if (statusCode == 200) {
                callback(nil)
            }
            else {
                callback("Bad response from the server")
            }
        }
    }
    
    func getFeedData (owner: String = "", callback: ([Picture]?, String?) -> ()) {
        let nsURL = NSURL(string: "http://\(serverUrl)/photos")!
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
                            newPicture.timeStamp = self.createTimeStamp(photo["date"]!)
                            newPicture.ownerName = photo["owner"]
                            pictureObjects.append(newPicture)
                        }
                    }
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
    
    
    private func createTimeStamp(dateString: String) -> Double {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = dateFormatter.dateFromString(dateString) {
            return date.timeIntervalSinceReferenceDate
        }
        else {
            return 0
        }
    }
    
    
    func getPicture (url: String, onSuccess: (pic: NSData) -> Void, onFailure: (error: String) -> Void) {
        if let nsURL = NSURL(string: "http://\(serverUrl)/photos/\(url)") {
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
    
    
    func uploadPicture(owner: String, picture: Picture, onSuccess:  () -> Void, onFailure: (error: String) -> Void) {
        var title = "Untitled"
        if let displayName = picture.displayName where displayName.characters.count != 0 {
            title = displayName
            print ("title: \(title) displayName: \(picture.displayName!)")
        }
        
        print ("title: \(title)")
        
        let imageData = UIImageJPEGRepresentation(picture.image!, 1.0)
        let nsURL = NSURL(string: "http://\(serverUrl)/photos/\(FacebookDataManager.SharedInstance.fbUniqueUserID!)/\(title)/\(picture.fileName!)")!
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
                    newPicture.timeStamp = self.createTimeStamp(photo["date"]!)
                    newPicture.ownerName = photo["owner"]
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