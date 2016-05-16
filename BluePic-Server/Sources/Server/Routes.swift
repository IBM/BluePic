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
      try response.status(HTTPStatusCode.OK).send("Hello World, from BluePic-Server! Original URL: \(request.originalUrl)").end()
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

  // http://www.ramblingincode.com/building-a-couchdb-reduce-function/
  // http://docs.couchdb.org/en/1.6.1/couchapp/ddocs.html#reduce-and-rereduce-functions
  // http://guide.couchdb.org/draft/cookbook.html#aggregate
  // http://www.slideshare.net/okurow/couchdb-mapreduce-13321353
  // https://qnalist.com/questions/2434952/sorting-by-reduce-value
  // https://gist.github.com/doppler/807315
  // http://guide.couchdb.org/draft/transforming.html
  router.get("/tags") { request, response, next in
    let queryParams: [Database.QueryParameters] = [.group(true), .groupLevel(1)]
    database.queryByView("tags", ofDesign: "main_design", usingParameters: queryParams) { (document, error) in
      if let document = document where error == nil {
        do {
          // Get tags (rows from JSON result document)
          guard var tags = document["rows"].array else {
            throw ProcessingError.Image("Tags could not be retrieved from database!")
          }

          // Sort tags in descending order
          tags.sort {
            let tag1: JSON = $0
            let tag2: JSON = $1
            return tag1["value"].intValue > tag2["value"].intValue
          }

          // Send sorted tags to client
          var tagsDocument = JSON([:])
          tagsDocument["records"] = JSON(tags)
          tagsDocument["number_of_records"].int = tags.count
          try response.status(HTTPStatusCode.OK).send(json: tagsDocument).end()
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

  // Get all image documents
  router.get("/images") { request, response, next in

    // if getting images by tag
    if let tag = request.queryParams["tag"] {
        let _ = tag.characters.split(separator: ",").map(String.init)

        // placeholder cloudant call that gets 2 images
        let queryParams: [Database.QueryParameters] =
        [.descending(true), .includeDocs(true), .endKey([NSString(string: "0026258080e68113b6da1b6713996faa")]), .startKey([NSString(string: "135464b130774f928d572eb9b5ad9c95"), NSObject()])]
        database.queryByView("images_by_id", ofDesign: "main_design", usingParameters: queryParams) { (document, error) in
          if let document = document where error == nil {
              do {
                  let images = try parseImages(document: document)
                  try response.status(HTTPStatusCode.OK).send(json: images).end()
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
    } else {

        database.queryByView("images", ofDesign: "main_design", usingParameters: [.descending(true), .includeDocs(true)]) { (document, error) in
          if let document = document where error == nil {
            do {
              let images = try parseImages(document: document)
              try response.status(HTTPStatusCode.OK).send(json: images).end()
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
  }

  // Get specific image document
  router.get("/images/:imageId") { request, response, next in
    print("imageID \(request.params)")
    guard let imageId = request.params["imageId"] else {
      response.error = generateInternalError()
      next()
      return
    }

    let queryParams: [Database.QueryParameters] =
    [.descending(true), .includeDocs(true), .endKey([imageId, 0]), .startKey([imageId, NSObject()])]
    database.queryByView("images_by_id", ofDesign: "main_design", usingParameters: queryParams) { (document, error) in
      if let document = document where error == nil {
        do {
          let json = try parseImages(document: document)
          let images = json["records"].arrayValue
          if images.count == 1 {
            try response.status(HTTPStatusCode.OK).send(json: images[0]).end()
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
    database.queryByView("users", ofDesign: "main_design", usingParameters: [.descending(true), .includeDocs(false)]) { (document, error) in
      if let document = document where error == nil {
        do {
          let users = try parseUsers(document: document)
          try response.status(HTTPStatusCode.OK).send(json: users).end()
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
    database.queryByView("users", ofDesign: "main_design", usingParameters: [ .descending(true), .includeDocs(false), .keys([userId]) ]) { (document, error) in
      if let document = document where error == nil {
        do {
          let json = try parseUsers(document: document)
          let users = json["records"].arrayValue
          if users.count == 1 {
            try response.status(HTTPStatusCode.OK).send(json: users[0]).end()
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
              Log.error("Failed to create image record in Cloudant database.")
              if let error = error {
                Log.error("Error domain: \(error._domain); error code: \(error._code).")
              }
              response.error = generateInternalError()
              next()
              return
            }

            // Contine processing of request (async request for OpenWhisk)
            processImage(withId: id, forUser: imageJSON["userId"].stringValue)

            // Return image document to caller
            // Update JSON image document with _id, and _rev
            imageJSON["_id"].stringValue = id
            imageJSON["_rev"].stringValue = revision
            response.status(HTTPStatusCode.OK).send(json: imageJSON)
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

    let queryParams: [Database.QueryParameters] = [.descending(true), .endKey([userId, "0"]), .startKey([userId, NSObject()])]
    database.queryByView("images_per_user", ofDesign: "main_design", usingParameters: queryParams) { (document, error) in
      if let document = document where error == nil {
        do {
          let images = try parseImages(forUserId: userId, usingDocument: document)
          try response.status(HTTPStatusCode.OK).send(json: images).end()
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
                try response.status(HTTPStatusCode.OK).send(json: userJson).end()
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
  //       response.status(HTTPStatusCode.OK).send(data: image)
  //     }
  //     else {
  //       response.error = error ?? generateInternalError()
  //     }
  //     next()
  //   }
  // }

}
