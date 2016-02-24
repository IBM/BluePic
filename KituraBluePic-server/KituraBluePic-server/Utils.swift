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

import CouchDB

import KituraRouter
import KituraNet
import KituraSys

import LoggerAPI

import SwiftyJSON

import Foundation


///
/// Because bridging is not complete in Linux, we must use Any objects for dictionaries
/// instead of AnyObject. The main branch SwiftyJSON takes as input AnyObject, however
/// our patched version for Linux accepts Any.
///
#if os(OSX)
    typealias JSONDictionary = [String: AnyObject]
#else
    typealias JSONDictionary = [String: Any]
#endif


func parsePhotosList (list: JSON) -> JSON {
    var photos = [JSON]()
    let listLength = Int(list["total_rows"].number!)
    if listLength == 0 {
        let empty = [[String:String]]()
        return JSON(empty)
    }
    for index in 0...(listLength - 1) {
        let photoId = list["rows"][index]["id"].stringValue
        let date = list["rows"][index]["key"].stringValue
        let data = list["rows"][index]["value"].dictionaryValue
        let title = data["title"]!.stringValue
        let ownerId = data["ownerId"]!.stringValue
        let ownerName = data["ownerName"]!.stringValue
        let attachments = data["attachments"]!.dictionaryValue
        let attachmentName = ([String](attachments.keys))[0]
            
        let photo = JSON(["title": title,  "date": date, "ownerId": ownerId, "ownerName": ownerName, "picturePath": "\(photoId)/\(attachmentName)"])
        photos.append(photo)
        
    }
    return JSON(photos)
}

func createPhotoDocument (request: RouterRequest) -> (JSONDictionary?, String?) {
    let ownerId = request.params["ownerId"]
    var ownerName = request.params["ownerName"]
    var title = request.params["title"]
    let photoName = request.params["photoname"]
    
    if ownerId == nil || ownerName == nil || photoName == nil {
        return (nil, nil)
    }

    ownerName = ownerName!.stringByReplacingOccurrencesOfString("%20", withString: " ")
    title = title?.stringByReplacingOccurrencesOfString("%20", withString: " ") ?? ""
    
    let ext = photoName!.componentsSeparatedByString(".")[1].lowercaseString
    let contentType = ContentType.contentTypeForExtension(ext)

    let tempDateString = NSDate().descriptionWithLocale(nil).bridge()
    let dateString = tempDateString.substringToIndex(10) + "T" + tempDateString.substringWithRange(NSMakeRange(11, 8))
    
    let doc : JSONDictionary = ["ownerId": ownerId!, "ownerName": ownerName!, "title": title!, "date": dateString, "inFeed": true, "type": "photo"]
    
    return (doc, contentType)
}

func createUploadReply (fromDocument document: JSONDictionary, id: String, photoName: String) -> JSON {
    var result = [String:String]()
    result["picturePath"] = "\(id)/\(photoName)"
    result["ownerId"] = document["ownerId"] as? String
    result["ownerName"] = document["ownerName"] as? String
    result["date"] = document["date"] as? String
    result["title"] = document["title"] as? String
    return JSON(result)
}

func getConfiguration () -> (ConnectionProperties, String, String, Int32) {
    
// In order to be able to access CouchDB through external address, go to 127.0.0.1:5984/_utils/config.html, httpd section and change bind_address to 0.0.0.0, and restart couchdb.
    
// Requires export CONFIG_DIR = ...
//    if let configDir = NSString(UTF8String: getenv("CONFIG_DIR")) as? String,
//    let configData = NSData(contentsOfFile: configDir + "./config.json")
    
    if let configData = NSData(contentsOfFile: "./config.json") {
        let configJson = JSON(data:configData)
        if let ipAddress = configJson["couchDbIpAddress"].string,
            let port = configJson["couchDbPort"].number,
            let dbName = configJson["couchDbDbName"].string,
            let redisHost = configJson["redisIpAddress"].string,
            let redisPort = configJson["redisPort"].number {
                return (ConnectionProperties(hostName: ipAddress, port: Int16(port.integerValue), secured: false),
                    dbName,
                    redisHost, Int32(redisPort.integerValue))
        }
    }
    print("Failed to read the configuration file!")
    exit(1)
}

func getDesign () -> (String?, JSON?) {

    let designDoc = JSON(["_id" : "_design/photos",
        "views" : [
            "sortedByDate" : [
                "map" : "function(doc) {if (doc.type == 'photo' && doc.title && doc.date && doc.ownerId && doc.ownerName) { emit(doc.date, {title: doc.title, ownerId: doc.ownerId, ownerName: doc.ownerName, attachments: doc._attachments});}}"
            ]
        ]
        ])
    return ("photos", designDoc)
}

