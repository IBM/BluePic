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
import Credentials
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

  // Get all images
  router.get("/images") { _, response, next in
    database.queryByView("images", ofDesign: "main_design", usingParameters: [.Descending(false), .IncludeDocs(true)]) { (document, error) in
      if let document = document where error == nil {
        do {
          let images = try parseImages(document)
          try response.status(HttpStatusCode.OK).sendJson(images).end()
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

  // Get all users
  router.get("/users") { _, response, next in
    database.queryByView("users", ofDesign: "main_design", usingParameters: [.Descending(true), .IncludeDocs(false)]) { (document, error) in
      if let document = document where error == nil {
        do {
          let users = try parseUsers(document)
          try response.status(HttpStatusCode.OK).sendJson(users).end()
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

  // Get a specific user
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
          try response.status(HttpStatusCode.OK).sendJson(document).end()
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
      var imageDocument = try getImageDocument(request)
      guard let contentType = imageDocument["contentType"] as? String else {
        throw ProcessingError.Image("Invalid image document!")
      }

      let image = try BodyParser.readBodyData(request)
      database.create(JSON(imageDocument)) { (id, revision, doc, error) in
        if let fileName = request.params["fileName"],
        let _ = doc, let id = id, let revision = revision where error == nil {
          database.createAttachment(id, docRevison: revision, attachmentName: fileName, attachmentData: image, contentType: contentType) { (rev, imageDoc, error) in
            if let _ = imageDoc where error == nil {
              imageDocument["url"] = "http://\(database.connProperties.hostName):\(database.connProperties.port)/\(database.name)/\(id)/\(fileName)"
              imageDocument["_id"] = id
              imageDocument["_rev"] = revision
              response.status(HttpStatusCode.OK).sendJson(JSON(imageDocument))
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
          let images = try parseImagesForUser(document)
          try response.status(HttpStatusCode.OK).sendJson(images).end()
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

  // Create a new user
  router.post("/users") { request, response, next in
    do {
      let rawUserData = try BodyParser.readBodyData(request)
      var userJson = JSON(data: rawUserData)

      // Verify JSON has required fields
      guard let _ = userJson["name"].string,
      let _ = userJson["_id"].string else {
        throw ProcessingError.Image("Invalid user document!")
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
            //TODO send just the _id
            try response.status(HttpStatusCode.OK).sendJson(document).end()
          } catch {
            Log.error("Failed to send response to client.")
            response.error = generateInternalError()
          }
        } else {
          response.error = error ?? generateInternalError()
        }
        next()
      }
    } catch {
      Log.error("Failed to create new user document.")
      response.error = generateInternalError()
      next()
    }
  }

  //////////////////////////////////////////////////////////////
  //TODO: Validate need for these middlewares

  //???
  router.all("/photos/*", middleware: BodyParser())

  // Needed for authentication
  router.post("/photos/:title/:photoname", middleware: credentials)

  /////////////////////////////////////////////////////////////

}
