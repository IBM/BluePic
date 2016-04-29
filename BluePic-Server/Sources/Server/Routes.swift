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

  let closure = { (request: RouterRequest, response: RouterResponse, next: () -> Void) -> Void in
    response.setHeader("Content-Type", value: "text/plain; charset=utf-8")
    do {
      print("Request: \(request)")
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
          //try response.status(HttpStatusCode.OK).sendJson(document).end()
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
      response.error = NSError(domain: BluePic.Domain, code: BluePic.Error.Internal.rawValue, userInfo: [NSLocalizedDescriptionKey: String(BluePic.Error.Internal)])
      next()
      return
    }

    // Retrieve JSON document for user
    database.retrieve(userId, callback: { (document: JSON?, error: NSError?) in
      if let document = document where error == nil {
        do {
          try response.status(HttpStatusCode.OK).send(json: document).end()
        }
        catch {
          Log.error("Failed to send response to client.")
        }
      } else {
        response.error = generateInternalError()
      }
      next()
    })
  }

  // Upload a new picture for a given user
  router.post("/users/:userId/images/:fileName/:displayName") { request, response, next in
    do {
      // As of now, we don't have a multi-form request parser...
      // Because of this we are using the REST endpoint definition as the mechanism
      // to send the metadata about the image, while the body of the request only
      // contains the binary data for the image. I know, yuck...
      var imageDocument = try getImageDocument(request: request)
      guard let contentType = imageDocument["contentType"] as? String else {
        throw ProcessingError.Image("Invalid image document!")
      }

      let image = try BodyParser.readBodyData(with: request)
      database.create(JSON(imageDocument)) { (id, revision, doc, error) in
        if let fileName = request.params["fileName"],
        let _ = doc, let id = id, let revision = revision where error == nil {
          database.createAttachment(id, docRevison: revision, attachmentName: fileName, attachmentData: image, contentType: contentType) { (rev, imageDoc, error) in
            if let _ = imageDoc where error == nil {
              imageDocument["url"] = generateImageUrl(imageId: id, attachmentName: fileName)
              imageDocument["_id"] = id
              imageDocument["_rev"] = revision
              invokeOpenWhisk(image: image)
              response.status(HttpStatusCode.OK).send(json: JSON(imageDocument))
            } else {
              response.error = error ?? generateInternalError()
            }
            next()
          }
        } else {
          response.error = generateInternalError()
          next()
        }
      }
    } catch {
      Log.error("Failed to send response to client.")
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

    database.queryByView("images_per_user", ofDesign: "main_design", usingParameters: [.Descending(true), .Keys([NSString(string: userId)])]) { (document, error) in
      if let document = document where error == nil {
        do {
          let images = try parseImagesForUser(document: document)
          try response.status(HttpStatusCode.OK).send(json: images).end()
          //try response.status(HttpStatusCode.OK).sendJson(document).end()
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
      let _ = userJson["_id"].string else {
        throw ProcessingError.User("Invalid user document!")
      }

      userJson["type"] = "user"

      // Keep only those keys that are valid for the user document
      let validKeys = ["_id", "name", "type"]
      for (key, _) in userJson {
        if validKeys.index(of: key) == nil {
          userJson.dictionaryObject?.removeValue(forKey: key)
        }
      }

      // Persist user document
      database.create(userJson) { (id, revision, document, error) in
        if let document = document where error == nil {
          do {
            // Return user document back to caller
            // Add revision number to it
            userJson["_rev"] = document["rev"]
            try response.status(HttpStatusCode.OK).send(json: userJson).end()
          } catch {
            Log.error("Failed to send response to client.")
            response.error = generateInternalError()
          }
        } else {
          response.error = error ?? generateInternalError()
        }
        next()
      }
    } catch let error {
      Log.error("Failed to create new user document.")
      Log.error("Error domain: \(error._domain); error code: \(error._code).")
      response.error = generateInternalError()
      next()
    }
  }

  // Get image binary.
  // It does not seem technically possible to server attachments from Cloudant
  // without requiring authentication. Hence, the need for this proxy method.
  router.get("/images/:imageId/:attachmentName") { request, response, next in
    guard let imageId = request.params["imageId"],
    let attachmentName = request.params["attachmentName"] else {
      response.error = generateInternalError()
      next()
      return
    }

    database.retrieveAttachment(imageId, attachmentName: attachmentName) { (image, error, contentType) in
      if  let image = image where error == nil  {
        if let contentType = contentType {
          response.setHeader("Content-Type", value: contentType)
        }
        response.status(HttpStatusCode.OK).send(data: image)
      }
      else {
        response.error = error ?? generateInternalError()
      }
      next()
    }
  }

  //////////////////////////////////////////////////////////////
  //TODO: Validate need for these middleware

  //What is this doing?
  router.all("/photos/*", middleware: BodyParser())

  /////////////////////////////////////////////////////////////

}
