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
import CouchDB
import Kitura
import KituraNet
import KituraSys
import LoggerAPI
import Credentials
import SwiftyJSON

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
    var title = request.params["title"]
    let photoName = request.params["photoname"]

    if let profile = request.userProfile where photoName != nil {
        let ownerId = profile.id
        #if os(Linux)
            let ownerName = profile.displayName.stringByReplacingOccurrencesOfString("%20", withString: " ")
            let ext = photoName!.componentsSeparatedByString(".")[1].lowercased()
        #else
            let ownerName = profile.displayName.replacingOccurrences(of: "%20", with: " ")
            let ext = photoName!.componentsSeparated(by: ".")[1].lowercased()
        #endif
        if let contentType = ContentType.contentTypeForExtension(ext) {
            #if os(Linux)
                let tempDateString = NSDate().descriptionWithLocale(nil).bridge()
                let dateString = tempDateString.substringToIndex(10) + "T" + tempDateString.substringWithRange(NSMakeRange(11, 8))
                title = title?.stringByReplacingOccurrencesOfString("%20", withString: " ") ?? ""
            #else
                let tempDateString = NSDate().description(withLocale: nil).bridge()
                let dateString = tempDateString.substring(to: 10) + "T" + tempDateString.substring(with:NSMakeRange(11, 8))
                title = title?.replacingOccurrences(of: "%20", with: " ") ?? ""
            #endif
            let doc : JSONDictionary = ["ownerId": ownerId, "ownerName": ownerName, "title": title!, "date": dateString, "inFeed": true, "type": "photo"]

            return (doc, contentType)
        }
    }

    return (nil, nil)
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

func getConfiguration () -> (ConnectionProperties, String) {

    // In order to be able to access CouchDB through external address, go to 127.0.0.1:5984/_utils/config.html, httpd section and change bind_address to 0.0.0.0, and restart couchdb.

    // Requires export CONFIG_DIR = ...
    //    if let configDir = NSString(UTF8String: getenv("CONFIG_DIR")) as? String,
    //    let configData = NSData(contentsOfFile: configDir + "./config.json")

    if let configData = NSData(contentsOfFile: "./config.json") {
        let configJson = JSON(data:configData)
        if let ipAddress = configJson["couchDbIpAddress"].string,
            let port = configJson["couchDbPort"].number,
            let dbName = configJson["couchDbDbName"].string {
              let connProperties = ConnectionProperties(hostName: ipAddress, port: Int16(port.integerValue), secured: false)
              return (connProperties, dbName)
        }
    }
    print("Failed to read the configuration file!")
    exit(1)
}

func getDesign () -> (String?, JSON?) {
    let designDoc : JSONDictionary =
        ["_id" : "_design/photos",
         "views" : [
            "sortedByDate" : [
                "map" : "function(doc) {if (doc.type == 'photo' && doc.title && doc.date && doc.ownerId && doc.ownerName) { emit(doc.date, {title: doc.title, ownerId: doc.ownerId, ownerName: doc.ownerName, attachments: doc._attachments});}}"
                ]
            ]
        ]

    return ("photos", JSON(designDoc))
}
