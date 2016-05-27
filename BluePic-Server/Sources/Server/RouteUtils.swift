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
import BluemixObjectStorage
import MobileClientAccess

/**
 This method should kick off asynchronously an OpenWhisk sequence and then return immediately. This method is not going to wait for the outcome of the OpenWhisk sequence/actions. Once the OpenWhisk sequence completes execution, the sequence should invoke the '/push' endpoint to generate a push notification for the iOS client.
 
 - parameter imageId: image ID to send off to OpenWhisk
 - parameter userId:  user ID associated with imageId, for reference
 */
func processImage(withId imageId: String, forUser userId: String) {
  // TODO OpenWhisk reads user document from cloudant to obtain language and units of measure...
  Log.verbose("imageId: \(imageId), userId: \(userId)")
  
  let hostName = "openwhisk.ng.bluemix.net"
  let path = "/api/v1/namespaces/cmjaun%40us.ibm.com_cmjaun%40us.ibm.com/actions/bluepic/processImage?blocking=true"
  let authToken = "NmFhZWE3OGQtOTk3ZC00NjAxLTgwZWMtNjU2MDgzNmRiZmNjOkJaMXE5alpqeVRKalpkNXVlMHBDTUFRekFyMWE1WVlqSVZBbXg5aTB6b2FRVUJrV0RVYUJSOHJ2UXU5Y0l1UEk="
  
  var requestOptions = [ClientRequestOptions]()
  requestOptions.append(.method("POST"))
  requestOptions.append(.schema("https://"))
  requestOptions.append(.hostname(hostName))
  requestOptions.append(.port(443))
  requestOptions.append(.path(path))
  var headers = [String:String]()
  headers["Content-Type"] = "application/json"
  headers["Authorization"] = "Basic \(authToken)"
  requestOptions.append(.headers(headers))

  guard let requestBody = JSON(["imageId":imageId]).rawString() else {
    Log.error("Failed to create json string with imageId")
    return
  }
  
  // Make REST call
  let req = HTTP.request(requestOptions) { resp in
    if let resp = resp where resp.statusCode == HTTPStatusCode.OK {
      do {
        let body = NSMutableData()
        try resp.readAllData(into: body)
        let jsonResponse = JSON(data: body)
        print("OpenWhisk response: \(jsonResponse)")
      } catch {
        Log.error("Bad JSON document received from OpenWhisk.")
      }
    } else {
      Log.error("Status error code or nil reponse received from OpenWhisk.")
      if let resp = resp {
        Log.error("Status code: \(resp.statusCode)")
        if let rawUserData = try? BodyParser.readBodyData(with: resp) {
          let str = NSString(data: rawUserData, encoding: NSUTF8StringEncoding)
          print("Response from OpenWhisk: \(str)")
        }
      }
    }
  }
  req.end(requestBody)
}

/**
* Gets a specific image document from the Cloudant database.
*
* - parameter database: Database instance
* - parameter imageId:  String id of the image document to retrieve.
* - parameter callback: Callback to use within async method.
*/
func readImage(database: Database, imageId: String, callback: ((jsonData: JSON?) -> ())) {
  let queryParams: [Database.QueryParameters] =
  [.descending(true), .includeDocs(true), .endKey([imageId, 0]), .startKey([imageId, NSObject()])]
  database.queryByView("images_by_id", ofDesign: "main_design", usingParameters: queryParams) { (document, error) in
    if let document = document where error == nil {
      do {
        let json = try parseImages(document: document)
        let images = json["records"].arrayValue
        if images.count == 1 {
          callback(jsonData: images[0])
        } else {
          throw ProcessingError.Image("Image not found!")
        }
      } catch {
        Log.error("Failed to get specific image document.")
        callback(jsonData: nil)
      }
    } else {
      Log.error("Failed to get specific image document.")
      callback(jsonData: nil)
    }
  }
}

/**
 Method to parse a document to get image data out of it
 
 - parameter document: json document with raw data
 
 - throws: processing error if can't parse document properly
 
 - returns: valid Json with just image data
 */
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

  return constructDocument(records: images)
}

/**
 Method to parse a document to get image data for a specific user out of it
 
 - parameter userId:   ID of user to get images for
 - parameter document: json document with raw data
 
 - throws: processing error if can't parse document properly
 
 - returns: valid Json with just image data
 */
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

/**
 Method to parse a document to get all user data
 
 - parameter document: json document with raw data
 
 - throws: parsing error if necessary
 
 - returns: valid json with all users data
 */
func parseUsers(document: JSON) throws -> JSON {
  let users = try parseRecords(document: document)
  return constructDocument(records: users)
}

/**
 Converts a RouterRequest object to a more consumable JSON object
 
 - parameter request: router request with all the data
 
 - throws: parsing error if request has invalid info
 
 - returns: valid Json with image data
 */
func getImageJSON(fromRequest request: RouterRequest) throws -> JSON {
  guard let caption = request.params["caption"],
  let fileName = request.params["fileName"],
  let userId = request.params["userId"],
  let lat = request.params["latitude"],
  let long = request.params["longitude"],
  let location = request.params["location"],
  let w = request.params["width"],
  let h = request.params["height"],
  let width = Float(w),
  let height = Float(h),
  let latitude = Float(lat),
  let longitude = Float(long), // else {
  let authContext = request.userInfo["mcaAuthContext"] as? AuthorizationContext else {
    throw ProcessingError.Image("Invalid image document!")
  }

  guard let contentType = ContentType.sharedInstance.contentTypeForFile(fileName) else {
    throw ProcessingError.Image("Invalid image document!")
  }

  let uploadedTs = StringUtils.currentTimestamp()
  let imageName = StringUtils.decodeWhiteSpace(inString: caption)
  let locationName = StringUtils.decodeWhiteSpace(inString: location)
  let imageURL = generateUrl(forContainer: userId, forImage: fileName)
  let deviceId = authContext.deviceIdentity.id
  // let deviceId = "3003"

  let whereabouts: JSONDictionary = ["latitude": latitude, "longitude": longitude, "name": locationName]
  let imageDocument: JSONDictionary = ["location": whereabouts, "contentType": contentType, "url": imageURL,
  "fileName": fileName, "userId": userId, "deviceId": deviceId, "caption": imageName, "uploadedTs": uploadedTs,
  "width": width, "height": height, "type": "image"]

  return JSON(imageDocument)
}

/**
 Convenience method to create consistently formatted error
 
 - returns: NSError object
 */
func generateInternalError() -> NSError {
  return NSError(domain: BluePic.Domain, code: BluePic.Error.Internal.rawValue, userInfo: [NSLocalizedDescriptionKey: String(BluePic.Error.Internal)])
}

/**
 Convenience method to create a URL for a container
 
 - parameter containerName: name of the container
 - parameter imageName:     name of corresponding image
 
 - returns: URL as a String
 */
func generateUrl(forContainer containerName: String, forImage imageName: String) -> String {
  //let url = "http://\(database.connProperties.host):\(database.connProperties.port)/\(database.name)/\(imageId)/\(attachmentName)"
  //let url = "\(config.appEnv.url)/images/\(imageId)/\(attachmentName)"
  let url = "\(objStorageConnProps.publicURL)/\(containerName)/\(imageName)"
  return url
}

/**
 Method that actually creates a container with the Object Storage service
 
 - parameter name:              name of the container to create
 - parameter completionHandler: callback to use on success or failure
 */
func createContainer(withName name: String, completionHandler: (success: Bool) -> Void) {
  // Cofigure container for public access and web hosting
  let configureContainer = { (container: ObjectStorageContainer) -> Void in
    let metadata: Dictionary<String, String> = ["X-Container-Meta-Web-Listings" : "true", "X-Container-Read" : ".r:*,.rlistings"]
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
  objStorage.createContainer(name: name) { (error, container) in
    if let container = container where error == nil {
      configureContainer(container)
    } else {
      Log.error("Could not create container named '\(name)'.")
      completionHandler(success: false)
    }
  }
}

/**
 Method to store image binary in a container if it exsists
 
 - parameter image:             image binary data
 - parameter name:              file name to store image as
 - parameter containerName:     name of container to use
 - parameter completionHandler: callback to use on success or failure
 */
func store(image: NSData, withName name: String, inContainer containerName: String, completionHandler: (success: Bool) -> Void) {
  // Store image in container
  let storeImage = { (container: ObjectStorageContainer) -> Void in
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
  objStorage.retrieveContainer(name: containerName) { (error, container) in
    if let container = container where error == nil {
      storeImage(container)
    } else {
      Log.error("Could not find container named '\(containerName)'.")
      completionHandler(success: false)
    }
  }
}

/**
 Method to convert Json data to a more usable format, adding and removing values as necessary
 
 - parameter containerName: container to use
 - parameter record:        Json data to massage/modify
 */
private func massageImageRecord(containerName: String, record: inout JSON) {
  //let id = record["_id"].stringValue
  //record["length"].int = record["_attachments"][fileName]["length"].int
  let fileName = record["fileName"].stringValue
  record["url"].stringValue = generateUrl(forContainer: containerName, forImage: fileName)
  record.dictionaryObject?.removeValue(forKey: "userId")
  record.dictionaryObject?.removeValue(forKey: "_attachments")
}

/**
 Method to simply get cleanly formatted values from a Json document
 
 - parameter document: json document with raw data
 
 - throws: parsing error if user json is invalid
 
 - returns: array of Json value objects
 */
private func parseRecords(document: JSON) throws -> [JSON] {
  guard let rows = document["rows"].array else {
    throw ProcessingError.User("Invalid document returned from Cloudant!")
  }

  let records: [JSON] = rows.map({row in
    row["value"]
  })
  return records
}

/**
 Helper method to wrap parsed data up nicely in a Json object
 
 - parameter records: array of Json data to wrap up
 
 - returns: Json object containg data and number of items
 */
private func constructDocument(records: [JSON]) -> JSON {
  var jsonDocument = JSON([:])
  jsonDocument["number_of_records"].int = records.count
  jsonDocument["records"] = JSON(records)
  return jsonDocument
}
