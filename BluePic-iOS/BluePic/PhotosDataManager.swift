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
    static var port = 7000//8090
    
    class func getFeedData (callback: ([Picture]?, String?) -> ()) {
        sendRequest(
            onSuccess: { (photos) in
                var pictureObjects = [Picture]()
                for photo in photos {
                   let newPicture = Picture()
                    newPicture.url = photo["picturePath"]
                    newPicture.displayName = photo["title"]
                    newPicture.timeStamp = createTimeStamp(photo["date"]!)
                    newPicture.ownerName = photo["owner"]
                    pictureObjects.append(newPicture)
                }
                callback(pictureObjects, nil)
        },
            onFailure: { (error) in
                callback(nil, error)
        })
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
    
    private class func sendRequest(onSuccess onSuccess: (body: [[String:String]]) -> Void, onFailure: (error: String) -> Void) {
        let nsURL = NSURL(string: "http://\(PhotosDataManager.host):\(PhotosDataManager.port)/photos")!
        let mutableURLRequest = NSMutableURLRequest(URL: nsURL)
        mutableURLRequest.HTTPMethod = "GET"

        Alamofire.request(mutableURLRequest).responseJSON {response in
            switch response.result {
            case .Success(let JSON):
                print("Success with JSON: \(JSON)")
                if let body = JSON as? [[String:String]] {
                    onSuccess(body: body)
                }
                else {
                    onFailure(error: "Failed to read response Json body")
                }
                
            case .Failure(let error):
                print("Request failed with error: \(error)")
                onFailure(error: error.description)
            }
        }
    }
    
    class func uploadPicture(owner: String, picture: Picture, onSuccess:  (imageURL: String) -> Void, onFailure: (error: String) -> Void) {
        var title = ""
        if let displayName = picture.displayName {
            title = displayName
        }

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
                print("Success with JSON: \(JSON)")
                if let body = JSON as? [String:String] {
                    onSuccess(imageURL: body["picturePath"]!)
                }
                else {
                    onFailure(error: "Failed to read response Json body")
                }
                
            case .Failure(let error):
                print("Request failed with error: \(error)")
                onFailure(error: error.description)
            }
        }
        
        
        
    }


//    private func executeCall(mutableURLRequest: NSMutableURLRequest, successCodes: [Int],
//        onSuccess: (body: [[String:String]]) -> Void, onFailure: (error: String) -> Void) {
//            // Fire off HTTP request
//            Alamofire.request(mutableURLRequest).responseJSON {response in
//                switch response.result {
//                case .Success(let JSON):
//                    print("Success with JSON: \(JSON)")
//                    if let body = JSON as? [[String:String]] {
//                        onSuccess(body: body)
//                    }
//                    else {
//                        onFailure(error: "Failed to read response Json body")
//                    }
//                    
//                case .Failure(let error):
//                    print("Request failed with error: \(error)")
//                    onFailure(error: error.description)
//                }
//                
////                // Get http response status code
////                var statusCode:Int = 0
////                if let httpResponse = response.response {
////                    statusCode = httpResponse.statusCode
////                }
////                print("statusCode = \(statusCode)")
////                // For a production app, we would need to verify if the auth token has expired;
////                // if so, then the code should re-authenticate and retry the current operation
////                // For this demo app, we did not get to implement this logic.
////                
////                let statusCodeIndex = successCodes.indexOf(statusCode)
////                if (statusCodeIndex != nil) {
////                    var headers:[NSObject : AnyObject]? = nil
////                    if let httpResponse = response.response {
////                        headers = httpResponse.allHeaderFields
////                    }
////                    response.
////                    onSuccess(headers: headers)
////                    return
////                }
////                
////                // If this code is getting executed, then an error occurred...
////                var errorMsg = "[No error info available]"
////                if let error = response.result.error {
////                    errorMsg = error.localizedDescription
////                }
////                print("REST method invocation failure: \(errorMsg)")
////                onFailure(error: errorMsg)
//            }
//    }
//    private class func executeCall2(mutableURLRequest: NSMutableURLRequest, successCodes: [Int],
//        onSuccess: (body: NSData) -> Void, onFailure: (error: String) -> Void) {
//            // Fire off HTTP request
//            Alamofire.request(mutableURLRequest).responseData{response in
//                switch response.result {
//                case .Success(let data):
//                    print("Success with data")
//                    onSuccess(body: data)
//                    
//                case .Failure(let error):
//                    print("Request failed with error: \(error)")
//                    onFailure(error: error.description)
//                }
//                
//            }
//    }
//    
//
}