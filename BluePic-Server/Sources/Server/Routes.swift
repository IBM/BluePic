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
import KituraSys
import MobileClientAccessKituraCredentialsPlugin
import MobileClientAccess
import Credentials
import BluemixPushNotifications

/**
* Function for setting up the different routes for this app.
*/
func defineRoutes() {

  let credentials = Credentials()
  credentials.register(plugin: MobileClientAccessKituraCredentialsPlugin())

  let pushNotificationsClient = PushNotifications(bluemixRegion: PushNotifications.Region.US_SOUTH, bluemixAppGuid: "75eef52c-2ed1-4518-9587-ce55cc66479d", bluemixAppSecret: "ef28c8e7-6f7e-41d5-ace1-bdf56a81aceb")

  let dbClient = CouchDBClient(connectionProperties: couchDBConnProps)
  let database = dbClient.database("bluepic_db")

  // Test closure
  let closure = { (request: RouterRequest, response: RouterResponse, next: () -> Void) -> Void in
    response.headers.append("Content-Type", value: "text/plain; charset=utf-8")
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
          guard var tags: [JSON] = document["rows"].array else {
            throw ProcessingError.Image("Tags could not be retrieved from database!")
          }
          // Sort tags in descending order
          tags.sort {
            let tag1: JSON = $0
            let tag2: JSON = $1
            return tag1["value"].intValue > tag2["value"].intValue
          }
          // Slice tags array (max number of items is 10)
          if tags.count > 10 {
            tags = Array(tags[0...9])
          }

          // Send sorted tags to client
          var tagsDocument = JSON([:])
          tagsDocument["records"] = JSON(tags)
          tagsDocument["number_of_records"].int = tags.count
          response.status(HTTPStatusCode.OK).send(json: tagsDocument)
        }
        catch {
          Log.error("Failed to obtain tags from database.")
          response.error = generateInternalError()
        }
      } else {
        Log.error("Failed to obtain tags from database.")
        response.error = generateInternalError()
      }
      next()
    }
  }

  /**
  * Route for getting all image documents or all images that match a given tag.
  * As of now, searching on multiple tags is not supported in this app.
  * To search using multiple tags, additional logic is required.
  * See following URLs for further details:
  * https://issues.apache.org/jira/browse/COUCHDB-523
  * http://stackoverflow.com/questions/1468684/multiple-key-ranges-as-parameters-to-a-couchdb-view
  */
  router.get("/images") { request, response, next in
    if let tag = request.queryParams["tag"] {
      // Get images by tag
      //let _ = tag.characters.split(separator: ",").map(String.init)
      let queryParams: [Database.QueryParameters] =
      [.descending(true), .includeDocs(true), .reduce(false), .endKey([tag, "0", "0", 0]), .startKey([tag, NSObject()])]
      database.queryByView("images_by_tags", ofDesign: "main_design", usingParameters: queryParams) { (document, error) in
        if let document = document where error == nil {
          do {
            let images = try parseImages(document: document)
            response.status(HTTPStatusCode.OK).send(json: images)
          }
          catch {
            Log.error("Failed to find images by tag.")
            response.error = generateInternalError()
          }
        } else {
          Log.error("Failed to find images by tag.")
          response.error = generateInternalError()
        }
        next()
      }
    } else {
      // Get all images
      database.queryByView("images", ofDesign: "main_design", usingParameters: [.descending(true), .includeDocs(true)]) { (document, error) in
        if let document = document where error == nil {
          do {
            let images = try parseImages(document: document)
            response.status(HTTPStatusCode.OK).send(json: images)
          }
          catch {
            Log.error("Failed to retrieve all images.")
            response.error = generateInternalError()
          }
        } else {
          Log.error("Failed to retrieve all images.")
          response.error = generateInternalError()
        }
        next()
      }
    }
  }

  /**
  * Route for getting a specific image document.
  */
  router.get("/images/:imageId") { request, response, next in
    guard let imageId = request.params["imageId"] else {
      response.error = generateInternalError()
      next()
      return
    }

    getImageBy(database: database, imageId: imageId, callback: { (jsonData) in
      print("data: \(jsonData)")
      if let jsonData = jsonData {
        response.status(HTTPStatusCode.OK).send(json: jsonData)
      } else {
        Log.error("Could not get image data")
        response.error = generateInternalError()
      }
      next()
    })
  }

  // Endpoint for sending push notification (this will use the server Push SDK)
  router.post("/push/images/:imageId") { request, response, next in
    guard let imageId = request.params["imageId"] else {
      response.error = generateInternalError()
      next()
      return
    }

    getImageBy(database: database, imageId: imageId, callback: { (jsonData) in
      print("data: \(jsonData)")
      if let imageData = jsonData {

        // TODO: Get user ID off of imageData object once task #121 is complete
        let apnsSettings = Notification.Settings.Apns(badge: nil, category: "imageProcessed", iosActionKey: nil, sound: nil, type: ApnsType.DEFAULT, payload: imageData.dictionaryObject)
        let settings = Notification.Settings(apns: apnsSettings, gcm: nil)
        let target = Notification.Target(deviceIds: nil, platforms: [TargetPlatform.Apple], tagNames: nil, userIds: ["<userID>"])
        let message = Notification.Message(alert: "Your image has finished processing and is ready to view!", url: nil)
        let notification = Notification(message: message, target: target, settings: settings)
        
        pushNotificationsClient.send(notification: notification) { (error) in
          if error != nil {
            print("Failed to send push notification. Error: \(error!)")
          }
        }

      } else {
        Log.error("Could not get image data")
        response.error = generateInternalError()
      }
    })

  }

  /**
  * Route for getting all user documents.
  */
  router.get("/users", middleware: credentials)
  router.get("/users") { request, response, next in
    database.queryByView("users", ofDesign: "main_design", usingParameters: [.descending(true), .includeDocs(false)]) { (document, error) in
      if let document = document where error == nil {
        do {
          let users = try parseUsers(document: document)
          response.status(HTTPStatusCode.OK).send(json: users)
        }
        catch {
          Log.error("Failed to read users from database.")
          response.error = generateInternalError()
        }
      } else {
        Log.error("Failed to read users from database.")
        response.error = generateInternalError()
      }
      next()
    }
  }

  /**
  * Route for getting a specific user document.
  */
  router.get("/users/:userId", middleware: credentials)
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
            response.status(HTTPStatusCode.OK).send(json: users[0])
          } else {
            throw ProcessingError.Image("User not found!")
          }
        } catch {
          Log.error("Failed to read requested user document.")
          response.error = generateInternalError()
        }
      } else {
        Log.error("Failed to read requested user document.")
        response.error = generateInternalError()
      }
      next()
    }
  }

  /**
  * Route for uploading a new picture for a given user.
  * As of now, we don't have a multi-form request parser in Kitura.
  * Therefore, we are using the REST endpoint definition as the mechanism
  * to send the image metadata, while the body of the request only
  * contains the binary data for the image. I know, yuck...
  */
  router.post("/users/:userId/images/:fileName/:caption/:width/:height/:latitude/:longitude/:location", middleware: credentials)
  router.post("/users/:userId/images/:fileName/:caption/:width/:height/:latitude/:longitude/:location") { request, response, next in
    do {
      var imageJSON = try getImageJSON(fromRequest: request)

      // Determine facebook ID from MCA and passed in userId match
      /*let userId = imageJSON["userId"].stringValue
      guard let authContext = request.userInfo["mcaAuthContext"] as? AuthorizationContext,
      userIdentity = authContext.userIdentity?.id where userId == userIdentity else {
      Log.error("User is not authorized to post image")
      response.error = generateInternalError()
      next()
      return
    }
    print("fbID: \(userId) and \(userIdentity)")*/

    // Determine facebook ID from MCA and passed in userId match
    let userId = imageJSON["userId"].stringValue
    guard let authContext = request.userInfo["mcaAuthContext"] as? AuthorizationContext,
    userIdentity = authContext.userIdentity?.id where userId == userIdentity else {
      Log.error("User is not authorized to post image")
      response.error = generateInternalError()
      next()
      return
    }
    print("fbID: \(userId) and \(userIdentity)")

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
          // Contine processing of image (async request for OpenWhisk)
          processImage(withId: id, forUser: imageJSON["userId"].stringValue)
          // Return image document to caller
          // Update JSON image document with _id, and _rev
          imageJSON["_id"].stringValue = id
          imageJSON["_rev"].stringValue = revision
          response.status(HTTPStatusCode.OK).send(json: imageJSON)
        }
      } else {
        Log.error("Failed to create image record in Cloudant database.")
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
        response.status(HTTPStatusCode.OK).send(json: images)
      }
      catch {
        Log.error("Failed to get images for \(userId).")
        response.error = generateInternalError()
      }
    } else {
      Log.error("Failed to get images for \(userId).")
      response.error = generateInternalError()
    }
    next()
  }
}

/**
* Route for creating a new user document in the database.
*/
router.post("/users", middleware: credentials)
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
