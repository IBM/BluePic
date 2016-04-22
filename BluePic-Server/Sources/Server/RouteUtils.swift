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
*/

import Foundation
import CouchDB
import Kitura
import KituraNet
import LoggerAPI
import Credentials
import SwiftyJSON

func parsePhotosList(list: JSON) -> JSON {
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

func getImageDocument(request: RouterRequest) throws -> JSONDictionary {
  guard let displayName = request.params["displayName"],
    let fileName = request.params["fileName"],
    let userId = request.params["userId"] else {
      throw ProcessingError.Image("Invalid image document!")
  }

  #if os(Linux)
    let ext = fileName.componentsSeparatedByString(".")[1].lowercased()
  #else
    let ext = fileName.componentsSeparated(by: ".")[1].lowercased()
  #endif

  guard let contentType = ContentType.contentTypeForExtension(ext) else {
    throw ProcessingError.Image("Invalid image document!")
  }

  #if os(Linux)
    let dateStr = NSDate().descriptionWithLocale(nil).bridge()
    let uploadedTs = dateStr.substringToIndex(10) + "T" + dateStr.substringWithRange(NSMakeRange(11, 8))
    let imageName = displayName.stringByReplacingOccurrencesOfString("%20", withString: " ")
  #else
    let dateStr = NSDate().description(withLocale: nil).bridge()
    let uploadedTs = dateStr.substring(to: 10) + "T" + dateStr.substring(with:NSMakeRange(11, 8))
    let imageName = displayName.replacingOccurrences(of: "%20", with: " ")
  #endif

  let imageDocument: JSONDictionary = ["contentType": contentType, "fileName": fileName, "userId": userId, "displayName": imageName, "uploadedTs": uploadedTs, "type": "image"]
  return imageDocument
}

func generateInternalError() -> NSError {
  return NSError(domain: BluePic.Domain, code: BluePic.Error.Internal.rawValue, userInfo: [NSLocalizedDescriptionKey: String(BluePic.Error.Internal)])
}

func getDesign() -> (String?, JSON?) {
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
