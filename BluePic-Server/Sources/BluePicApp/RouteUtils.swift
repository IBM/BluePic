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
import LoggerAPI
import SwiftyJSON
import BluemixObjectStorage
import Dispatch
import KituraContracts
import SwiftyRequest

// Encapsulates helper functions that the endpoints use
extension ServerController {
  
  /**
   This method kicks off asynchronously an CloudFunctions sequence and returns immediately.
   This method should not wait for the outcome of the CloudFunctions sequence/actions.
   Once the CloudFunctions sequence completes execution, the sequence should invoke the
   '/push' endpoint to generate a push notification for the iOS client.
   
   - parameter imageId: The image ID of the JSON image document in Cloudant.
   
   */
  func processImage(withId imageId: String) {
    Log.verbose("imageId: \(imageId)")
    
    let headers = [
      "Content-Type": "application/json",
      "Authorization": "Basic \(cloudFunctionsProps.authToken)"
    ]
    
    guard let requestBody = try? JSON(["imageId": imageId]).rawData() else {
      Log.error("Failed to create JSON string with imageId.")
      return
    }
    
    // Make REST call
    let url = "https://" + cloudFunctionsProps.hostName + cloudFunctionsProps.urlPath
    let req = RestRequest(method: .post, url: url)
    req.headerParameters = headers
    req.messageBody = requestBody

    // Kitura does not yet execute certain functionality asynchronously,
    // hence the need for this block.
    DispatchQueue.global().async {
      req.responseData { response in
        switch response.result {
          case .success(let body):
            guard let jsonResponse = try? JSON(data: body) else {
              Log.warning("Failed to parse JSON response")
              return
            }
            Log.debug("CloudFunctions response: \(jsonResponse)")
          case .failure(let err):
            Log.error("Error response from CloudFunctions: \(String(describing: err))")
        }
      }
    }
  }
  
  /**
   * Gets a specific image document from the Cloudant database.
   *
   * - parameter database: Database instance
   * - parameter imageId:  String id of the image document to retrieve.
   * - parameter callback: Callback to use within async method.
   */
  func readImage(database: Database, imageId: String, callback: @escaping (Image?, RequestError?) -> Void) {
    let anyImageId = imageId as Database.KeyType
    let queryParams: [Database.QueryParameters] = [
      .includeDocs(true),
      .endKey([anyImageId, NSNumber(integerLiteral: 0)]),
      .startKey([anyImageId, NSObject()])
    ]
    readByView(View.images_by_id, params: queryParams, type: Image.self, database: database) { images, error in
      guard let images = images, let image = images.first, error == nil else {
        callback(nil, .notFound)
        return
      }
      callback(image, nil)
    }
  }
  
  /**
   * Database Query Builder
   *
   * - parameter params: Database.QueryParameters
   * - parameter types: Type of the object being returned
   * - parameter database: Database instance
   * - parameter callback: Callback to use within async method.
   */
  func readByView<T: JSONConvertible>(_ view: View,
                                      params: [Database.QueryParameters] = [],
                                      type: T.Type,
                                      database: Database,
                                      callback: @escaping ([T]?, RequestError?) -> Void) {
    
    var queryParams: [Database.QueryParameters] = [.descending(true)]
    queryParams.append(contentsOf: params)
    
    let exists = params.contains {
      switch $0 {
      case .includeDocs(let x): return x == true
      default: return false
      }
    }
    
    database.queryByView(view.rawValue, ofDesign: "main_design", usingParameters: queryParams) { document, error in
      do {
        guard error == nil, let document = document else {
          throw BluePicLocalizedError.readDocumentFailed
        }
        
        let objects: [T] = try T.convert(document: document, hasDocs: exists, decoder: self.decoder)
        
        callback(objects, nil)
        
      } catch {
        Log.error("\(error)")
        callback(nil, .internalServerError)
      }
    }
  }
  
  /**
   * Database Create Query Builder. Adds the object to the db and updates in revision number
   *
   * - parameter object: JSONConvertible/Codable object
   * - parameter database: Database instance
   * - parameter callback: Callback to use within async method.
   */
  func createObject<T: JSONConvertible>(object: T, database: Database, callback: @escaping (T?, RequestError?) -> Void) {
    do {
      let data = try self.encoder.encode(object)
      let json = SwiftyJSON.JSON(data: data)
      
      database.create(json) { id, revision, _, error in
        
        guard error == nil, let revision = revision else {
          Log.error("Failed to add user to the system of records.")
          callback(nil, .internalServerError)
          return
        }
        
        var object = object
        object.rev = revision
        
        callback(object, nil)
      }
    } catch {
      
    }
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
    let baseURL = "https://dal.objectstorage.open.softlayer.com/v1/AUTH_\(objStorageConnProps.projectID)"
    let url = "\(baseURL)/\(containerName)/\(imageName)"
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
      let metadata: Dictionary = [
        "X-Container-Meta-Web-Listings": "true",
        "X-Container-Read": ".r:*,.rlistings"
      ]
      container.updateMetadata(metadata: metadata) { error in
        if error != nil {
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
      guard let objStorage = objStorage  else {
        Log.verbose("Created successfully container named '\(name)'.")
        completionHandler(false)
        return
      }

      objStorage.createContainer(name: name) { error, container in
        if let container = container, error == nil {
          configureContainer(container)
        } else {
          Log.error("Could not create container named '\(name)'.")
          completionHandler(false)
        }
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
  func store(image: Image, completionHandler: @escaping (_ success: Bool) -> Void) throws {
    guard let imageData = image.image else {
      Log.error("No image found")
      completionHandler(false)
      return
    }

    let storeImage = { (container: ObjectStorageContainer) -> Void in
      container.storeObject(name: image.fileName, data: imageData) { error, _ in
        if let error = error {
          Log.error("\(error)")
          Log.error("Could not save image named '\(image.fileName)' in container.")
          completionHandler(false)
        } else {
          Log.verbose("Stored successfully image '\(image.fileName)' in container.")
          completionHandler(true)
        }
      }
    }
    
    // Get reference to container
    let retrieveContainer = { (objStorage: ObjectStorage?) -> Void in
      guard let objStorage = objStorage else {
        completionHandler(false)
        return
      }

      Log.debug("retrieving container: \(image.userId)")
      objStorage.retrieveContainer(name: image.userId) { error, container in
        if let container = container, error == nil {
          storeImage(container)
        } else {
          Log.error("Could not find container named '\(image.fileName)'.")
          completionHandler(false)
        }
      }
    }
    
    // Create, and configure container
    objectStorageConn.getObjectStorage(completionHandler: retrieveContainer)
  }
}
