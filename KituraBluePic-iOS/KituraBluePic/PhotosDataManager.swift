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

import Foundation

import Alamofire


class PhotosDataManager {

    var serverUrl = ""
    
    static let SharedInstance:PhotosDataManager = {
        return PhotosDataManager()
    }()
    
    func connect (serverUrl: String, callback: (String?) -> ()) {
        self.serverUrl = serverUrl
        if let nsURL = NSURL(string: "http://\(serverUrl)/connect") {
            let mutableURLRequest = NSMutableURLRequest(URL: nsURL)
            mutableURLRequest.HTTPMethod = "GET"
            
            Alamofire.request(mutableURLRequest).responseJSON {response in
                // Get http response status code
                var statusCode:Int = 0
                if let httpResponse = response.response {
                    statusCode = httpResponse.statusCode
                }
                if (statusCode == 200) {
                    callback(nil)
                }
                else {
                    callback("Bad response from the server")
                }
            }
        }
        else {
            callback("Bad server URL")
        }
    }
    
    func getFeedData (ownerId: String = "", callback: ([Picture]?, String?) -> ()) {
        if let nsURL = NSURL(string: "http://\(serverUrl)/photos") {
            let mutableURLRequest = NSMutableURLRequest(URL: nsURL)
            mutableURLRequest.HTTPMethod = "GET"
            
            Alamofire.request(mutableURLRequest).responseJSON {response in
                switch response.result {
                case .Success(let JSON):
                    print("Success with JSON: \(JSON)")
                    if let photos = JSON as? [[String:String]] {
                        var pictureObjects = [Picture]()
                        for photo in photos {
                            if (ownerId == "" || photo["ownerId"] == ownerId) {
                                let newPicture = Picture()
                                newPicture.url = photo["picturePath"]
                                newPicture.displayName = photo["title"]
                                newPicture.timeStamp = self.createTimeStamp(photo["date"]!)
                                newPicture.ownerName = photo["ownerName"]
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
        else {
            callback(nil, "Bad server URL")
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
            let mutableURLRequest = NSMutableURLRequest(URL: nsURL)
            mutableURLRequest.HTTPMethod = "GET"
            
            Alamofire.request(mutableURLRequest).responseData{response in
                switch response.result {
                case .Success(let data):
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
        }
        title = Utils.escapeUrl(title)
               
        let imageData = UIImageJPEGRepresentation(picture.image!, 1.0)
        let url = "http://\(serverUrl)/photos/\(title)/\(picture.fileName!)"

        if let nsURL = NSURL(string: url) {
            let mutableURLRequest = NSMutableURLRequest(URL: nsURL)
            mutableURLRequest.HTTPMethod = "POST"
            mutableURLRequest.addValue("image/jpeg", forHTTPHeaderField: "Content-Type")
            mutableURLRequest.HTTPBody = imageData
            
            mutableURLRequest.addValue(FBSDKAccessToken.currentAccessToken().tokenString, forHTTPHeaderField: "access_token")
            mutableURLRequest.addValue("facebook", forHTTPHeaderField: "X-token-type")            
            
            Alamofire.request(mutableURLRequest).responseJSON {response in
                switch response.result {
                case .Success(let JSON):
                    if let photo = JSON as? [String:String] {
                        let newPicture = Picture()
                        newPicture.url = photo["picturePath"]
                        newPicture.displayName = photo["title"]
                        newPicture.timeStamp = self.createTimeStamp(photo["date"]!)
                        newPicture.ownerName = photo["ownerName"]
                        newPicture.ownerId = photo["ownerId"]
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
        else {
            print("Bad URL: ", url)
        }
    }
}
