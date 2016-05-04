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
import SwiftyJSON
import BluemixObjectStore

/**
* This method should read the user document and kick off asynchronously an OpenWhisk action
* and then return immediately. This method is not going to wait
* for the outcome of the OpenWhisk sequence/actions. Once the OpenWhisk sequence
* completes execution, the sequence should invoke the /push endpoint to generate
* a push notification for the iOS client.
*/
func process(image: NSData, withImageId imageId: String, withUserId userId: String) {
  // TODO
  // TODO Read user document from cloudant to obtain language and units of measure...
  Log.verbose("process() not implemented yet...")
  Log.verbose("imageId: \(imageId), userId: \(userId)")
}

func parseImages(document: JSON) throws -> JSON {
  guard let rows = document["rows"].array else {
    throw ProcessingError.Image("Invalid images document returned from Cloudant!")
  }

  var images: [JSON] = []
  var index = 1
  while index <= (rows.count) {
    var imageRecord = rows[index]["doc"]
    imageRecord["user"] = rows[index-1]["doc"]
    massageImageRecord(containerName: imageRecord["user"]["_id"].stringValue, record: &imageRecord)
    images.append(imageRecord)
    index = index + 2
  }

  Log.verbose("About to create JSON object from: \(images)")
  return constructDocument(records: images)
}

func parseImages(forUserId userId: String, usingDocument document: JSON) throws -> JSON {
  guard let rows = document["rows"].array else {
    throw ProcessingError.Image("Invalid images document returned from Cloudant!")
  }

  let images: [JSON] = rows.map({row in
    var record = row["value"]
    massageImageRecord(containerName: userId, record: &record)
    return record
  })

  return constructDocument(records: images)
}

func parseUsers(document: JSON) throws -> JSON {
  let users = try parseRecords(document: document)
  return constructDocument(records: users)
}

func getImageJSON(fromRequest request: RouterRequest) throws -> JSON {
  guard let displayName = request.params["displayName"],
  let fileName = request.params["fileName"],
  let userId = request.params["userId"],
  let lat = request.params["latitude"],
  let long = request.params["longitude"],
  let location = request.params["location"],
  let latitude = Float(lat),
  let longitude = Float(long) else {
    throw ProcessingError.Image("Invalid image document!")
  }

  guard let contentType = ContentType.sharedInstance.contentTypeForFile(fileName) else {
    throw ProcessingError.Image("Invalid image document!")
  }

  // Massage fields
  #if os(Linux)
  let dateStr = NSDate().descriptionWithLocale(nil).bridge()
  let uploadedTs = dateStr.substringToIndex(10) + "T" + dateStr.substringWithRange(NSMakeRange(11, 8))
  let imageName = displayName.stringByReplacingOccurrencesOfString("%20", withString: " ")
  let locationName = location.stringByReplacingOccurrencesOfString("%20", withString: " ")
  #else
  let dateStr = NSDate().description.bridge()
  let uploadedTs = dateStr.substring(to: 10) + "T" + dateStr.substring(with:NSMakeRange(11, 8))
  let imageName = displayName.replacingOccurrences(of: "%20", with: " ")
  let locationName = location.replacingOccurrences(of: "%20", with: " ")
  #endif

  let whereabouts: JSONDictionary = ["latitude": latitude, "longitude": longitude, "name": locationName]
  let imageDocument: JSONDictionary = ["location": whereabouts, "contentType": contentType, "fileName": fileName, "userId": userId, "displayName": imageName, "uploadedTs": uploadedTs, "type": "image"]
  return JSON(imageDocument)
}

func generateInternalError() -> NSError {
  return NSError(domain: BluePic.Domain, code: BluePic.Error.Internal.rawValue, userInfo: [NSLocalizedDescriptionKey: String(BluePic.Error.Internal)])
}

// func generateUrl(forImageId imageId: String, forAttachmentName attachmentName: String) -> String {
//   //let url = "http://\(database.connProperties.host):\(database.connProperties.port)/\(database.name)/\(imageId)/\(attachmentName)"
//   // let imageURL = "\(publicURL)/\(containerName)/\(imageName)"
//   let url = "\(config.appEnv.url)/images/\(imageId)/\(attachmentName)"
//   return url
// }

func generateUrl(forContainer containerName: String, forImage imageName: String) -> String {
  //let url = "http://\(database.connProperties.host):\(database.connProperties.port)/\(database.name)/\(imageId)/\(attachmentName)"
  //let url = "\(config.appEnv.url)/images/\(imageId)/\(attachmentName)"
  let url = "\(objStoreConnProperties.publicURL)/\(containerName)/\(imageName)"
  return url
}

func createContainer(withName name: String, completionHandler: (success: Bool) -> Void) {
  // Cofigure container for public access and web hosting
  let configureContainer = { (container: ObjectStoreContainer) -> Void in
    let metadata:Dictionary<String, String> = ["X-Container-Meta-Web-Listings" : "true", "X-Container-Read" : ".r:*,.rlistings"]
    container.updateMetadata(metadata: metadata) { (error) in
      if let _ = error {
        Log.error("Could not configure container named '\(name)' for public access and web hosting.")
        completionHandler(success: false)
      } else {
        Log.verbose("Configured successfully container named '\(name)' for public access and web hosting.")
        completionHandler(success: true)
      }
    }
  }

  // Create container
  let createContainer = { (objStore: ObjectStore?) -> Void in
    if let objStore = objStore {
      objStore.createContainer(name: name) { (error, container) in
        if let container = container where error == nil {
          configureContainer(container)
        } else {
          Log.error("Could not create container named '\(name)'.")
          completionHandler(success: false)
        }
      }
    } else {
      Log.verbose("Created successfully container named '\(name)'.")
      completionHandler(success: false)
    }
  }

  // Connect, create, and configure container
  connectToObjectStore(completionHandler: createContainer)
}

func store(image: NSData, withName name: String, inContainer containerName: String, completionHandler: (success: Bool) -> Void) {
  // Store image in container
  let storeImage = { (container: ObjectStoreContainer) -> Void in
    container.storeObject(name: name, data: image) { (error, object) in
      if let _ = error {
        Log.error("Could not save image named '\(name)' in container.")
        completionHandler(success: false)
      } else {
        Log.verbose("Stored successfully image '\(name)' in container.")
        completionHandler(success: true)
      }
    }
  }

  // Get reference to container
  let retrieveContainer = { (objStore: ObjectStore?) -> Void in
    if let objStore = objStore {
      objStore.retrieveContainer(name: containerName) { (error, container) in
        if let container = container where error == nil {
          storeImage(container)
        } else {
          Log.error("Could not find container named '\(containerName)'.")
          completionHandler(success: false)
        }
      }
    } else {
      completionHandler(success: false)
    }
  }

  // Connect, create, and configure container
  connectToObjectStore(completionHandler: retrieveContainer)
}

private func massageImageRecord(containerName: String, record: inout JSON) {
  //let id = record["_id"].stringValue
  let fileName = record["fileName"].stringValue
  record["url"].stringValue = generateUrl(forContainer: containerName, forImage: fileName)
  record["length"].int = record["_attachments"][fileName]["length"].int
  record.dictionaryObject?.removeValue(forKey: "userId")
  record.dictionaryObject?.removeValue(forKey: "_attachments")
}

private func parseRecords(document: JSON) throws -> [JSON] {
  guard let rows = document["rows"].array else {
    throw ProcessingError.User("Invalid document returned from Cloudant!")
  }

  let records: [JSON] = rows.map({row in
    row["value"]
  })
  return records
}

private func constructDocument(records: [JSON]) -> JSON {
  var jsonDocument = JSON([:])
  jsonDocument["number_of_records"].int = records.count
  jsonDocument["records"] = JSON(records)
  return jsonDocument
}

private func connectToObjectStore(completionHandler: (objStore: ObjectStore?) -> Void) {
  // Create object store instance and connect
  let objStore = ObjectStore(projectId: objStoreConnProperties.projectId)
  objStore.connect(userId: objStoreConnProperties.userId, password: objStoreConnProperties.password, region: ObjectStore.REGION_DALLAS) { (error) in
    if let error = error {
      let errorMsg = "Could not connect to Object Storage."
      Log.error("\(errorMsg) Error was: '\(error)'.")
      completionHandler(objStore: nil)
    } else {
      completionHandler(objStore: objStore)
    }
  }
}
