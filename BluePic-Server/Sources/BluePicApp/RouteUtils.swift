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
import Dispatch

struct BluePicLocalizedError : LocalizedError {
    var errorDescription: String?
}

// Encapsulates helper functions that the endpoints use
extension ServerController {

  /**
   This method kicks off asynchronously an OpenWhisk sequence and returns immediately.
   This method should not wait for the outcome of the OpenWhisk sequence/actions.
   Once the OpenWhisk sequence completes execution, the sequence should invoke the
   '/push' endpoint to generate a push notification for the iOS client.

   - parameter imageId: The image ID of the JSON image document in Cloudant.

   */
  func processImage(withId imageId: String) {
    Log.verbose("imageId: \(imageId)")
    var requestOptions: [ClientRequest.Options] = []
    requestOptions.append(.method("POST"))
    requestOptions.append(.schema("https://"))
    requestOptions.append(.hostname(openWhiskProps.hostName))
    requestOptions.append(.port(443))
    requestOptions.append(.path(openWhiskProps.urlPath))
    var headers = [String:String]()
    headers["Content-Type"] = "application/json"
    headers["Authorization"] = "Basic \(openWhiskProps.authToken)"
    requestOptions.append(.headers(headers))

    guard let requestBody = JSON(["imageId":imageId]).rawString() else {
      Log.error("Failed to create JSON string with imageId.")
      return
    }

    // Make REST call
    let req = HTTP.request(requestOptions) { resp in
      if let resp = resp, resp.statusCode == HTTPStatusCode.OK || resp.statusCode == HTTPStatusCode.accepted {
        do {
          var body = Data() //NSMutableData()
          try resp.readAllData(into: &body)
          let jsonResponse = JSON(data: body)
          print("OpenWhisk response: \(jsonResponse)")
        } catch {
          Log.error("Bad JSON document received from OpenWhisk.")
        }
      } else {
          Log.error("Status error code or nil reponse received from OpenWhisk.")
          if let resp = resp {
              Log.error("Status code: \(resp.statusCode)")
              var rawUserData = Data()
              do {
                  let _ = try resp.read(into: &rawUserData)
                  let str = String(data: rawUserData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
                  print("Error response from OpenWhisk: \(str)")
              }
              catch {
                  
              }
          }
        }
      }
    
    // Kitura does not yet execute certain functionality asynchronously,
    // hence the need for this block.
    DispatchQueue.global().async {
        req.end(requestBody)
    }
  }

  /**
  * Gets a specific image document from the Cloudant database.
  *
  * - parameter database: Database instance
  * - parameter imageId:  String id of the image document to retrieve.
  * - parameter callback: Callback to use within async method.
  */
  func readImage(database: Database, imageId: String, callback: @escaping (_ jsonData: JSON?) -> ()) {
    let queryParams: [Database.QueryParameters] =
    [.descending(true),
     .includeDocs(true),
     .endKey([NSString(string: imageId), NSNumber(integerLiteral: 0)]),
     .startKey([NSString(string: imageId), NSObject()])]
    database.queryByView("images_by_id", ofDesign: "main_design", usingParameters: queryParams) { document, error in
      if let document = document, error == nil {
        do {
          let json = try self.parseImages(document: document)
          let images = json["records"].arrayValue
          if images.count == 1 {
            callback(images[0])
          } else {
            throw ProcessingError.Image("Image not found!")
          }
        } catch {
          Log.error("Failed to get specific image document.")
          callback(nil)
        }
      } else {
        Log.error("Failed to get specific image document.")
        callback(nil)
      }
    }
  }

  /**
   Method to parse a document to get image data out of it.

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
   Method to parse a document to get image data for a specific user out of it.

   - parameter userId:   ID of user to get images for
   - parameter document: json document with raw data

   - throws: processing error if can't parse document properly

   - returns: valid Json with just image data
   */
  func parseImages(forUserId userId: String, usingDocument document: JSON) throws -> JSON {
    guard let rows = document["rows"].array else {
      throw ProcessingError.Image("Invalid images document returned from Cloudant!")
    }

    let images: [JSON] = rows.map { row in
      var record = row["value"]
      massageImageRecord(containerName: userId, record: &record)
      return record
    }

    return constructDocument(records: images)
  }

  /**
   Method to parse a document to get all user data.

   - parameter document: json document with raw data

   - throws: parsing error if necessary

   - returns: valid json with all users data
   */
  func parseUsers(document: JSON) throws -> JSON {
    let users = try parseRecords(document: document)
    return constructDocument(records: users)
  }

  /**
   Method to parse out multipart data. We expect json about an image and image data binary

   - parameter request: router request with all the data

   - throws: parsing error if necessary

   - returns: valid json image data and image binary in an NSData object
   */
  func parseMultipart(fromRequest request: RouterRequest) throws -> (JSON, Data) {
    guard let requestBody: ParsedBody = request.body else {
      throw ProcessingError.Image("No request body present.")
    }
    var imageJson: JSON?
    var imageData: Data?
    switch (requestBody) {
    case .multipart(let parts):
      for part in parts {
        if part.name == "imageJson" {
          switch (part.body) {
          case .text(let stringJson):
            let encoding = String.Encoding.utf8
            if let dataJson = stringJson.data(using: encoding, allowLossyConversion: false) {
              imageJson = JSON(data: dataJson)
            }
          default:
            Log.warning("Couldn't process image Json from multi-part form.")
          }
        } else if part.name == "imageBinary" {
          switch (part.body) {
          case .raw(let data):
            imageData = data
          default:
            Log.warning("Couldn't process image binary from multi-part form.")
          }
        }
      }
    default:
      throw ProcessingError.Image("Failed to parse request body: \(requestBody)")
    }

    guard let json = imageJson, let data = imageData else {
      throw ProcessingError.Image("Failed to parse multipart form data in request body.")
    }
    return (json, data)
  }

  /**
   Converts a RouterRequest object to a more consumable JSON object.

   - parameter json: json object containing details about an image
   - parameter request: router request with all the data

   - throws: parsing error if request has invalid info

   - returns: valid Json with image data
   */
  func updateImageJSON(json: JSON, withRequest request: RouterRequest) throws -> JSON {
    var updatedJson = json
    guard let authContext = request.userInfo["mcaAuthContext"] as? AuthorizationContext, 
              let contentType = ContentType.sharedInstance.getContentType(forFileName: updatedJson["fileName"].stringValue) else {
      throw ProcessingError.Image("Invalid image document!")
    }

    let userId = authContext.userIdentity?.id ?? "anonymous"
    Log.verbose("Image will be uploaded under the following userId: '\(userId)'.")
    let uploadedTs = StringUtils.currentTimestamp()
    let imageURL = generateUrl(forContainer: userId, forImage: updatedJson["fileName"].stringValue)
    let deviceId = authContext.deviceIdentity.id

    updatedJson["contentType"].stringValue = contentType
    updatedJson["url"].stringValue = imageURL
    updatedJson["userId"].stringValue = userId
    updatedJson["deviceId"].stringValue = deviceId
    updatedJson["uploadedTs"].stringValue = uploadedTs
    updatedJson["type"].stringValue = "image"

    return updatedJson
  }

  /**
   Convenience method to create a URL for a container.

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
   Method that actually creates a container with the Object Storage service.

   - parameter name: name of the container to create
   - parameter completionHandler: callback to use on success or failure
   */
   func createContainer(withName name: String, completionHandler: @escaping (_ success: Bool) -> Void) {
     // Cofigure container for public access and web hosting
     let configureContainer = { (container: ObjectStorageContainer) -> Void in
       let metadata:Dictionary<String, String> = ["X-Container-Meta-Web-Listings" : "true", "X-Container-Read" : ".r:*,.rlistings"]
       container.updateMetadata(metadata: metadata) { error in
         if let _ = error {
           Log.error("Could not configure container named '\(name)' for public access and web hosting.")
           completionHandler(false)
         } else {
           Log.verbose("Configured successfully container named '\(name)' for public access and web hosting.")
           completionHandler(true)
         }
       }
     }

     // Create container
     let createContainer = { (objStorage: ObjectStorage?) -> Void in
       if let objStorage = objStorage {
         objStorage.createContainer(name: name) { error, container in
           if let container = container, error == nil {
             configureContainer(container)
           } else {
             Log.error("Could not create container named '\(name)'.")
             completionHandler(false)
           }
         }
       } else {
         Log.verbose("Created successfully container named '\(name)'.")
         completionHandler(false)
       }
     }

     // Create, and configure container
     objectStorageConn.getObjectStorage(completionHandler: createContainer)
   }

  /**
   Method to store image binary in a container if it exsists.

   - parameter image:             image binary data
   - parameter name:              file name to store image as
   - parameter containerName:     name of container to use
   - parameter completionHandler: callback to use on success or failure
   */
   func store(image: Data, withName name: String, inContainer containerName: String, completionHandler: @escaping (_ success: Bool) -> Void) {
     // Store image in container
     let storeImage = { (container: ObjectStorageContainer) -> Void in
       container.storeObject(name: name, data: image) { error, object in
         if let _ = error {
           Log.error("Could not save image named '\(name)' in container.")
           completionHandler(false)
         } else {
           Log.verbose("Stored successfully image '\(name)' in container.")
           completionHandler(true)
         }
       }
     }

     // Get reference to container
     let retrieveContainer = { (objStorage: ObjectStorage?) -> Void in
       if let objStorage = objStorage {
         objStorage.retrieveContainer(name: containerName) { error, container in
           if let container = container, error == nil {
             storeImage(container)
           } else {
             Log.error("Could not find container named '\(containerName)'.")
             completionHandler(false)
           }
         }
       } else {
         completionHandler(false)
       }
     }

     // Create, and configure container
     objectStorageConn.getObjectStorage(completionHandler: retrieveContainer)
   }

  /**
   Method to convert JSON data to a more usable format, adding and removing values as necessary.

   - parameter containerName: container to use
   - parameter record:        Json data to massage/modify
   */
  private func massageImageRecord(containerName: String, record: inout JSON) {
    //let id = record["_id"].stringValue
    //record["length"].int = record["_attachments"][fileName]["length"].int
    let fileName = record["fileName"].stringValue
    record["url"].stringValue = generateUrl(forContainer: containerName, forImage: fileName)
    let _ = record.dictionaryObject?.removeValue(forKey: "userId")
    let _ = record.dictionaryObject?.removeValue(forKey: "_attachments")
  }

  /**
   Method to simply get cleanly formatted values from a JSON document.

   - parameter document: JSON document with raw data

   - throws: parsing error if user JSON is invalid

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
   Helper method to wrap parsed data up nicely in a JSON object.

   - parameter records: array of JSON data to wrap up

   - returns: JSON object containg data and number of items
   */
  private func constructDocument(records: [JSON]) -> JSON {
    var jsonDocument = JSON([:])
    jsonDocument["number_of_records"].int = records.count
    jsonDocument["records"] = JSON(records)
    return jsonDocument
  }
}
