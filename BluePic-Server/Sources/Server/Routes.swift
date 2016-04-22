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
      response.error = NSError(domain: BluePic.Domain, code: BluePic.Error.Internal.rawValue, userInfo: [NSLocalizedDescriptionKey: String(BluePic.Error.Internal)])
    }
    next()
  }

  // Test endpoint
  router.get("/hello", handler: closure)

  // Get all images
  router.get("/images") { _, response, next in
    database.queryByView("images", ofDesign: "main_design", usingParameters: [.Descending(true), .IncludeDocs(true)]) { (document, error) in
      if let document = document where error == nil {
        do {
          try response.status(HttpStatusCode.OK).sendJson(document).end()
        }
        catch {
          Log.error("Failed to send response to client.")
        }
      } else {
        response.error = NSError(domain: BluePic.Domain, code: BluePic.Error.Internal.rawValue, userInfo: [NSLocalizedDescriptionKey: String(BluePic.Error.Internal)])
      }
      next()
    }
  }

  // Get all users
  router.get("/users") { _, response, next in
    database.queryByView("users", ofDesign: "main_design", usingParameters: [.Descending(true), .IncludeDocs(true)]) { (document, error) in
      if let document = document where error == nil {
        do {
          try response.status(HttpStatusCode.OK).sendJson(document).end()
        }
        catch {
          Log.error("Failed to send response to client.")
        }
      } else {
        response.error = NSError(domain: BluePic.Domain, code: BluePic.Error.Internal.rawValue, userInfo: [NSLocalizedDescriptionKey: String(BluePic.Error.Internal)])
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
        response.error = NSError(domain: BluePic.Domain, code: BluePic.Error.Internal.rawValue, userInfo: [NSLocalizedDescriptionKey: String(BluePic.Error.Internal)])
      }
      next()
    })
  }

  // Upload a new picture for a given user
  router.post("/users/:userId/images/:fileName/:displayName") { request, response, next in
    do {
      // As of now, we don't have a multi-form request parser...
      // Because of this we are using the RENT endpoint definition as the mechanism
      // to send the metadata about the image, while the body of the request only
      // contains the binary data for the image.
      var imageDocument = try getImageDocument(request)
      guard let contentType = imageDocument["contentType"] as? String else {
        throw ProcessingError.Image("Invalid image document!")
      }

      let image = try BodyParser.readBodyData(request)
      database.create(JSON(imageDocument)) { (id, revision, doc, error) in
        if let fileName = request.params["fileName"], let _ = doc, let id = id, let revision = revision where error == nil {
          database.createAttachment(id, docRevison: revision, attachmentName: fileName, attachmentData: image, contentType: contentType) { (rev, photoDoc, error) in
            if let _ = photoDoc where error == nil {
              imageDocument["url"] = "http://\(database.connProperties.hostName):\(database.connProperties.port)/\(database.name)/\(id)/\(fileName)"
              imageDocument["_id"] = id
              imageDocument["_rev"] = revision
              response.status(HttpStatusCode.OK).sendJson(JSON(imageDocument))
            } else {
              response.error = error ?? NSError(domain: BluePic.Domain, code: BluePic.Error.Internal.rawValue, userInfo: [NSLocalizedDescriptionKey: String(BluePic.Error.Internal)])
            }
            next()
          }
        } else {
          response.error = NSError(domain: BluePic.Domain, code: BluePic.Error.Internal.rawValue, userInfo: [NSLocalizedDescriptionKey: String(BluePic.Error.Internal)])
          next()
        }
      }
    } catch {
      Log.error("Failed to send response to client.")
      response.error = NSError(domain: BluePic.Domain, code: BluePic.Error.Internal.rawValue, userInfo: [NSLocalizedDescriptionKey: String(BluePic.Error.Internal)])
      next()
    }
  }

  // Get all pictures for a given user
  router.get("/users/:userId/images", handler: closure)

  //////

  router.all("/photos/*", middleware: BodyParser())

  router.post("/photos/:title/:photoname", middleware: credentials)

  ///

  router.get("/photos") { _, response, next in
    database.queryByView("sortedByDate", ofDesign: "photos", usingParameters: [.Descending(true)]) { (document, error) in
      if let document = document where error == nil {
        do {
          try response.status(HttpStatusCode.OK).sendJson(parsePhotosList(document)).end()
        }
        catch {
          Log.error("Failed to send response to client.")
        }
      } else {
        response.error = error ?? NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey: "View not found"])
      }
      next()
    }
  }

/*
  router.get("/photos/:docid/:photoid") { request, response, next in
    guard let docId = request.params["docid"],
    let attachmentName = request.params["photoid"] else {
      response.error = NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey: "Photo not found"])
      next()
      return
    }

    database.retrieveAttachment(docId, attachmentName: attachmentName) { (photo, error, contentType) in
      if let photo = photo where error == nil {
        if let contentType = contentType {
          response.setHeader("Content-Type", value: contentType)
        }
        response.status(HttpStatusCode.OK).sendData(photo)
      } else {
        response.error = error ?? NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey: "Photo not found"])
      }
      next()
    }
  }*/

  /*
  router.post("/photos/:title/:photoname") { request, response, next in
    let (doc, docType) = createPhotoDocument(request)
    guard let document = doc, let contentType = docType else {
      response.error = NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid photo"])
      next()
      return
    }

    do {
      let image = try BodyParser.readBodyData(request)
      database.create(JSON(document)) { (id, revision, doc, error) in
        if let photoName = request.params["photoname"], let _ = doc, let id = id, let revision = revision where error == nil {
          database.createAttachment(id, docRevison: revision, attachmentName: photoName, attachmentData: image, contentType: contentType) { (rev, photoDoc, error) in
            if let _ = photoDoc where error == nil {
              let reply = createUploadReply(fromDocument: document, id: id, photoName: photoName)
              response.status(HttpStatusCode.OK).sendJson(reply)
            } else {
              response.error = error  ??  NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey: "Internal error"])
            }
            next()
          }
        } else {
          response.error = error ?? NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey: "Internal error"])
          next()
        }
      }
    } catch {
      response.error = NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey:"Invalid photo"])
      next()
      return
    }
  }*/
}
