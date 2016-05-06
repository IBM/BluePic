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
import Kitura
import KituraNet
import CouchDB
import LoggerAPI
import SwiftyJSON

// Setup the handlers for the Photo APIs
func defineRoutes() {

  let dbClient = CouchDBClient(connectionProperties: couchDBConnProps)
  let database = dbClient.database("bluepic_db")

  // Test closure
  let closure = { (request: RouterRequest, response: RouterResponse, next: () -> Void) -> Void in
    response.setHeader("Content-Type", value: "text/plain; charset=utf-8")
    do {
      try response.status(HttpStatusCode.OK).send("Hello World, from BluePic-Server! Original URL: \(request.originalUrl)").end()
    }
    catch {
      Log.error("Failed to send response to client.")
      response.error = generateInternalError()
    }
    next()
  }

  // Test endpoint
  router.get("/hello", handler: closure)

  // Endpoint for sending push notification (this will use the new Push SDK)
  router.post("/push", handler: closure)

  // Get all image documents
  router.get("/images") { _, response, next in
    database.queryByView("images", ofDesign: "main_design", usingParameters: [.Descending(true), .IncludeDocs(true)]) { (document, error) in
      if let document = document where error == nil {
        do {
          let images = try parseImages(document: document)
          try response.status(HttpStatusCode.OK).send(json: images).end()
        }
        catch {
          Log.error("Failed to send response to client.")
          response.error = generateInternalError()
        }
      } else {
        response.error = generateInternalError()
      }
      next()
    }
  }

  // Get specific image document
  router.get("/images/:imageId") { request, response, next in
    guard let imageId = request.params["imageId"] else {
      response.error = generateInternalError()
      next()
      return
    }

    let queryParams: [Database.QueryParameters] =
    [.Descending(true), .IncludeDocs(true), .EndKey([NSString(string: imageId), NSInteger(0)]), .StartKey([NSString(string: imageId), NSObject()])]
    database.queryByView("images_by_id", ofDesign: "main_design", usingParameters: queryParams) { (document, error) in
      if let document = document where error == nil {
        do {
          let json = try parseImages(document: document)
          let images = json["records"].arrayValue
          if images.count == 1 {
            try response.status(HttpStatusCode.OK).send(json: images[0]).end()
          } else {
            throw ProcessingError.Image("Image not found!")
          }
        }
        catch {
          Log.error("Failed to send response to client.")
          response.error = generateInternalError()
        }
      } else {
        response.error = generateInternalError()
      }
      next()
    }
  }

  // Get all user documents
  router.get("/users") { _, response, next in
    database.queryByView("users", ofDesign: "main_design", usingParameters: [.Descending(true), .IncludeDocs(false)]) { (document, error) in
      if let document = document where error == nil {
        do {
          let users = try parseUsers(document: document)
          try response.status(HttpStatusCode.OK).send(json: users).end()
        }
        catch {
          Log.error("Failed to send response to client.")
          response.error = generateInternalError()
        }
      } else {
        response.error = generateInternalError()
      }
      next()
    }
  }

  // Get a specific user document
  router.get("/users/:userId") { request, response, next in
    guard let userId = request.params["userId"] else {
      response.error = generateInternalError()
      next()
      return
    }

    // Retrieve JSON document for user
    database.queryByView("users", ofDesign: "main_design", usingParameters: [.Descending(true), .IncludeDocs(false), .Keys([userId])]) { (document, error) in
      if let document = document where error == nil {
        do {
          let json = try parseUsers(document: document)
          let users = json["records"].arrayValue
          if users.count == 1 {
            try response.status(HttpStatusCode.OK).send(json: users[0]).end()
          } else {
            throw ProcessingError.Image("User not found!")
          }
        }
        catch {
          Log.error("Failed to send response to client.")
          response.error = generateInternalError()
        }
      } else {
        response.error = generateInternalError()
      }
      next()
    }
  }

  // Upload a new picture for a given user
  router.post("/users/:userId/images/:fileName/:caption/:width/:height/:latitude/:longitude/:location") { request, response, next in
    do {
      // As of now, we don't have a multi-form request parser...
      // Because of this we are using the REST endpoint definition as the mechanism
      // to send the image metadata, while the body of the request only
      // contains the binary data for the image. I know, yuck...
      var imageJSON = try getImageJSON(fromRequest: request)
      //Log.verbose("The following is the imageJSON document generated: \(imageJSON)")

      // Get image binary from request body
      let image = try BodyParser.readBodyData(with: request)

      // Create closure
      let completionHandler = { (success: Bool) -> Void in
        if success {
          // Add image record to database
          database.create(imageJSON) { (id, revision, doc, error) in
            guard let id = id, revision = revision where error == nil else {
              response.error = generateInternalError()
              next()
              return
            }

            // Contine processing of request (async request for OpenWhisk)
            let imageURL = generateUrl(forContainer: imageJSON["userId"].stringValue, forImage: imageJSON["fileName"].stringValue)
            process(imageURL: imageURL, withImageId: id, withUserId: imageJSON["userId"].stringValue)

            // Return image document to caller
            // Update JSON image document with url, _id, and _rev
            imageJSON["url"].stringValue = imageURL
            imageJSON["_id"].stringValue = id
            imageJSON["_rev"].stringValue = revision
            response.status(HttpStatusCode.OK).send(json: imageJSON)
          }
        } else {
          response.error = generateInternalError()
        }
        next()
      }

      // Create container for user before creating image record in database
      store(image: image, withName: imageJSON["fileName"].stringValue, inContainer: imageJSON["userId"].stringValue, completionHandler: completionHandler)
    } catch {
      Log.error("Failed to add image record.")
      response.error = generateInternalError()
      next()
    }
  }

  // Get all picture documents for a given user
  router.get("/users/:userId/images") { request, response, next in
    guard let userId = request.params["userId"] else {
      response.error = generateInternalError()
      next()
      return
    }

    let queryParams: [Database.QueryParameters] = [.Descending(true), .EndKey([NSString(string: userId), NSString(string: "0")]), .StartKey([NSString(string: userId), NSObject()])]
    database.queryByView("images_per_user", ofDesign: "main_design", usingParameters: queryParams) { (document, error) in
      if let document = document where error == nil {
        do {
          let images = try parseImages(forUserId: userId, usingDocument: document)
          try response.status(HttpStatusCode.OK).send(json: images).end()
        }
        catch {
          Log.error("Failed to get images for \(userId).")
          response.error = generateInternalError()
        }
      } else {
        response.error = generateInternalError()
      }
      next()
    }
  }

  // Create a new user in the database
  router.post("/users") { request, response, next in
    do {
      let rawUserData = try BodyParser.readBodyData(with: request)
      var userJson = JSON(data: rawUserData)

      // Verify JSON has required fields
      guard let _ = userJson["name"].string,
      let userId = userJson["_id"].string else {
        throw ProcessingError.User("Invalid user document!")
      }
      userJson["type"] = "user"

      // Keep only those keys that are valid for the user document
      let validKeys = ["_id", "name", "type", "language", "unitsOfMeasurement"]
      for (key, _) in userJson {
        if validKeys.index(of: key) == nil {
          userJson.dictionaryObject?.removeValue(forKey: key)
        }
      }

      // Create completion handler closure
      let completionHandler = { (success: Bool) -> Void in
        if success {
          // Persist user document to database
          database.create(userJson) { (id, revision, document, error) in
            do {
              if let document = document where error == nil {
                // Add revision number response document
                userJson["_rev"] = document["rev"]
                // Return user document back to caller
                try response.status(HttpStatusCode.OK).send(json: userJson).end()
                next()
              } else {
                Log.error("Failed to add user to the system of records.")
                response.error = error ?? generateInternalError()
                next()
              }
            } catch {
              Log.error("Failed to add user to the system of records.")
              response.error = generateInternalError()
              next()
            }
          }
        } else {
          Log.error("Failed to add user to the system of records.")
          response.error = generateInternalError()
          next()
        }
      }

      // Create container for user before adding record to database
      createContainer(withName: userId, completionHandler: completionHandler)
    } catch let error {
      Log.error("Failed to create new user document.")
      Log.error("Error domain: \(error._domain); error code: \(error._code).")
      response.error = generateInternalError()
      next()
    }
  }

  // Get image binary. Note that it is not technically possible to serve attachments from Cloudant
  // without requiring authentication (unless the authentication settings for the entire database
  // are changed). Hence, the need for this proxy method.
  // router.get("/images/:imageId/:attachmentName") { request, response, next in
  //   guard let imageId = request.params["imageId"],
  //   let attachmentName = request.params["attachmentName"] else {
  //     response.error = generateInternalError()
  //     next()
  //     return
  //   }
  //
  //   database.retrieveAttachment(imageId, attachmentName: attachmentName) { (image, error, contentType) in
  //     if let image = image where error == nil {
  //       // Add content type to response header
  //       if let contentType = contentType {
  //         response.setHeader("Content-Type", value: contentType)
  //       }
  //       response.status(HttpStatusCode.OK).send(data: image)
  //     }
  //     else {
  //       response.error = error ?? generateInternalError()
  //     }
  //     next()
  //   }
  // }

}
