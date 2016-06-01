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
import Kitura
import KituraNet
import CouchDB
import LoggerAPI
import SwiftyJSON
import KituraSys
import BluemixPushNotifications
import MobileClientAccessKituraCredentialsPlugin
import MobileClientAccess
import Credentials

/**
* Function for setting up the different routes for this app.
*/
func defineRoutes() {
  // Credentials, database, and PushNotifications client...
  let credentials = Credentials()
  credentials.register(plugin: MobileClientAccessKituraCredentialsPlugin())
  let pushNotificationsClient =
  PushNotifications(bluemixRegion: PushNotifications.Region.US_SOUTH, bluemixAppGuid: mobileClientAccessProps.clientId, bluemixAppSecret: ibmPushProps.secret)

  // Assign middleware instance (for securing endpoints)
  router.get("/users", middleware: credentials)
  router.post("/users", middleware: credentials)
  router.post("/push", middleware: credentials)

  // Hello closure
  let closure = { (request: RouterRequest, response: RouterResponse, next: () -> Void) -> Void in
    response.headers.append("Content-Type", value: "text/plain; charset=utf-8")
    response.status(HTTPStatusCode.OK).send("Hello World, from BluePic-Server! Original URL: \(request.originalUrl)")
    next()
  }

  // Hello endpoint
  router.get("/hello", handler: closure)

  // This code will be moved to the OpenWhisk actions/sequence Andy is working on
  // Just keeping it here for testing purposes
  router.get("/token") { request, response, next in
    // Define error response just in case...
    var errorResponse = JSON([:])
    errorResponse["error"].stringValue = "Failed to retrieve MCA token."

    let baseStr = "\(mobileClientAccessProps.clientId):\(mobileClientAccessProps.secret)"
    print("baseStr: \(baseStr)")
    let utf8BaseStr = baseStr.data(using: NSUTF8StringEncoding)
    guard let authHeader = utf8BaseStr?.base64EncodedString(NSDataBase64EncodingOptions(rawValue: 0)) else {
      print("Could not generate authHeader...")
      response.status(HTTPStatusCode.internalServerError).send(json: errorResponse)
      next()
      return
    }
    //let authHeader="NzVlZWY1MmMtMmVkMS00NTE4LTk1ODctY2U1NWNjNjY0NzlkOmtCTFRXWTF2Uk8yZzVnRmRSYnBWOFE="
    //let appGuid="75eef52c-2ed1-4518-9587-ce55cc66479d"
    let appGuid = mobileClientAccessProps.clientId
    print("authHeader: \(authHeader)")
    print("appGuid: \(appGuid)")

    // Request options
    var requestOptions = [ClientRequestOptions]()
    requestOptions.append(.method("POST"))
    requestOptions.append(.schema("http://"))
    requestOptions.append(.hostname("imf-authserver.ng.bluemix.net"))
    requestOptions.append(.port(80))
    requestOptions.append(.path("/imf-authserver/authorization/v1/apps/\(appGuid)/token"))
    var headers = [String:String]()
    headers["Accept"] = "application/json"
    headers["Content-Type"] = "application/x-www-form-urlencoded; charset=utf-8"
    headers["Authorization"] = "Basic \(authHeader)"
    requestOptions.append(.headers(headers))

    // Body required for getting MCA token
    let requestBody = "grant_type=client_credentials"

    // Make REST call
    let req = HTTP.request(requestOptions) { resp in
      if let resp = resp where resp.statusCode == HTTPStatusCode.OK {
        do {
          let body = NSMutableData()
          try resp.readAllData(into: body)
          let jsonResponse = JSON(data: body)
          //let accessToken = json["accessToken"].stringValue
          print("MCA response: \(jsonResponse)")
          response.status(HTTPStatusCode.OK).send(json: jsonResponse)
        } catch {
          Log.error("Bad JSON document received from MCA server.")
          response.status(resp.statusCode).send(json: errorResponse)
        }
      } else {
        Log.error("Status error code or nil reponse received from MCA server.")
        if let resp = resp {
          Log.error("Status code: \(resp.statusCode)")
          if let rawUserData = try? BodyParser.readBodyData(with: resp) {
            let str = NSString(data: rawUserData, encoding: NSUTF8StringEncoding)
            print("Response from MCA server: \(str)")
          }
        }
        response.status(HTTPStatusCode.internalServerError).send(json: errorResponse)
      }
      next()
    }
    req.end(requestBody)
  }

  /**
  * Route for getting the top 10 most popular tags. The following URLs are kept
  * here as reference:
  * http://www.ramblingincode.com/building-a-couchdb-reduce-function/
  * http://docs.couchdb.org/en/1.6.1/couchapp/ddocs.html#reduce-and-rereduce-functions
  * http://guide.couchdb.org/draft/cookbook.html#aggregate
  * http://www.slideshare.net/okurow/couchdb-mapreduce-13321353
  * https://qnalist.com/questions/2434952/sorting-by-reduce-value
  * https://gist.github.com/doppler/807315
  * http://guide.couchdb.org/draft/transforming.html
  */
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
        } catch {
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
    if var tag = request.queryParams["tag"] {
      // Get images by tag
      // let _ = tag.characters.split(separator: ",").map(String.init)
      tag = StringUtils.decodeWhiteSpace(inString: tag)
      let queryParams: [Database.QueryParameters] =
      [.descending(true), .includeDocs(true), .reduce(false), .endKey([tag, "0", "0", 0]), .startKey([tag, NSObject()])]
      database.queryByView("images_by_tags", ofDesign: "main_design", usingParameters: queryParams) { (document, error) in
        if let document = document where error == nil {
          do {
            let images = try parseImages(document: document)
            response.status(HTTPStatusCode.OK).send(json: images)
          } catch {
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
          } catch {
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

    readImage(database: database, imageId: imageId, callback: { (jsonData) in
      if let jsonData = jsonData {
        response.status(HTTPStatusCode.OK).send(json: jsonData)
      } else {
        response.error = generateInternalError()
      }
      next()
    })
  }

  /**
  * Route for sending push notification (this uses the Push server SDK).
  */
  router.post("/push/images/:imageId") { request, response, next in
    // Define response body
    var responseBody = JSON([:])
    responseBody["status"].boolValue = false

    guard let imageId = request.params["imageId"] else {
      //response.error = generateInternalError()
      response.status(HTTPStatusCode.badRequest)
      response.send(json: responseBody)
      next()
      return
    }

    readImage(database: database, imageId: imageId) { (jsonImage) in
      if let jsonImage = jsonImage {
        let apnsSettings = Notification.Settings.Apns(badge: nil, category: "imageProcessed", iosActionKey: nil, sound: nil, type: ApnsType.DEFAULT, payload: jsonImage.dictionaryObject)
        let settings = Notification.Settings(apns: apnsSettings, gcm: nil)
        let target = Notification.Target(deviceIds: [jsonImage["deviceId"].stringValue], platforms: [TargetPlatform.Apple], tagNames: nil, userIds: nil)
        let message = Notification.Message(alert: "Your image was processed; check it out!", url: nil)
        let notification = Notification(message: message, target: target, settings: settings)
        pushNotificationsClient.send(notification: notification) { (error) in
          if let error = error {
            Log.error("Failed to send push notification: \(error)")
            //response.error = generateInternalError()
            response.status(HTTPStatusCode.internalServerError)
          } else {
            response.status(HTTPStatusCode.OK)
            responseBody["status"].boolValue = true
          }
          response.send(json: responseBody)
          next()
        }
      } else {
        //response.error = generateInternalError()
        response.status(HTTPStatusCode.internalServerError)
        response.send(json: responseBody)
        next()
      }
    }
  }

  /**
  * Route for getting all user documents.
  */
  router.get("/users") { request, response, next in
    database.queryByView("users", ofDesign: "main_design", usingParameters: [.descending(true), .includeDocs(false)]) { (document, error) in
      if let document = document where error == nil {
        do {
          let users = try parseUsers(document: document)
          response.status(HTTPStatusCode.OK).send(json: users)
        } catch {
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
  router.get("/users/:userId") { request, response, next in
    guard let userId = request.params["userId"] else {
      response.status(HTTPStatusCode.badRequest)
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
            throw ProcessingError.User("User not found!")
          }
        } catch {
          response.status(HTTPStatusCode.notFound)
          Log.error("User with id \(userId) was not found.")
          response.error = generateInternalError()
        }
      } else {
        response.status(HTTPStatusCode.internalServerError)
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
  router.post("/users/:userId/images/:fileName/:caption/:width/:height/:latitude/:longitude/:location") { request, response, next in
    do {
      var imageJSON = try getImageJSON(fromRequest: request)

      // Determine facebook ID from MCA; verify that provided userId in URL matches facebook ID.
      let userId = imageJSON["userId"].stringValue
      guard let authContext = request.userInfo["mcaAuthContext"] as? AuthorizationContext,
      userIdentity = authContext.userIdentity?.id where userId == userIdentity else {
        Log.error("User is not authorized to post image.")
        response.error = generateInternalError()
        next()
        return
      }

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
            processImage(withId: id)
            // Return image document to caller
            // Update JSON image document with _id, and _rev
            imageJSON["_id"].stringValue = id
            imageJSON["_rev"].stringValue = revision
            response.status(HTTPStatusCode.OK).send(json: imageJSON)
            next()
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

  /**
  * Route for getting all image documents for a given user.
  */
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
        } catch {
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
  router.post("/users") { request, response, next in
    do {
      let rawUserData = try BodyParser.readBodyData(with: request)
      var userJson = JSON(data: rawUserData)

      // Verify JSON has required fields
      guard let _ = userJson["name"].string,
      let userId = userJson["_id"].string else {
        throw ProcessingError.User("Invalid user document!")
      }
      // Add type field
      userJson["type"] = "user"

      // Keep only those keys that are valid for the user document
      let validKeys = ["_id", "name", "type"]
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
}
