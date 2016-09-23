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
import BluemixPushNotifications
import MobileClientAccessKituraCredentialsPlugin
import MobileClientAccess
import Credentials

///
/// Because bridging is not complete in Linux, we must use Any objects for dictionaries
/// instead of AnyObject. The main branch SwiftyJSON takes as input AnyObject, however
/// our patched version for Linux accepts Any.
///
#if os(OSX)
typealias JSONDictionary = [String: AnyObject]
#else
typealias JSONDictionary = [String: Any]
#endif

public class ServerController {

	let couchDBConnProps: ConnectionProperties
	let objStorageConnProps: ObjectStorageConnProps
	let mobileClientAccessProps: MobileClientAccessProps
	let ibmPushProps: IbmPushProps
	let openWhiskProps: OpenWhiskProps
	let database: Database
	var objectStorageConn: ObjectStorageConn
  let pushNotificationsClient: PushNotifications
    
  public let router = Router()
    
  public init() throws {
    // Create configuration objects
	  let config = try Configuration()
	  couchDBConnProps = try config.getCouchDBConnProps()
	  objStorageConnProps = try config.getObjectStorageConnProps()
	  mobileClientAccessProps = try config.getMobileClientAccessProps()
	  ibmPushProps = try config.getIbmPushProps()
	  openWhiskProps = try config.getOpenWhiskProps()

	  // Create cloudant access database object
	  let dbClient = CouchDBClient(connectionProperties: couchDBConnProps)
	  database = dbClient.database("bluepic_db")

	  // Create object storage connection object
	  objectStorageConn = ObjectStorageConn(objStorageConnProps: objStorageConnProps)
        
    let credentials = Credentials() // middleware for securing endpoints
    credentials.register(plugin: MobileClientAccessKituraCredentialsPlugin())
    pushNotificationsClient = PushNotifications(bluemixRegion: PushNotifications.Region.US_SOUTH, bluemixAppGuid: mobileClientAccessProps.clientId, bluemixAppSecret: ibmPushProps.secret)

    // Assign middleware instance
    router.get("/users", middleware: credentials)
    router.post("/users", middleware: credentials)
    router.post("/push", middleware: credentials)
    router.get("/ping", middleware: credentials)
    router.post("/images",  middleware: credentials)
    router.all("/images", middleware: BodyParser())
    
    Log.verbose("Defining routes for server...")
    router.get("/ping", handler: ping)
    router.get("/token", handler: token)
    router.get("/tags", handler: getPopularTags)
    router.get("/users", handler: getUsers)
    router.get("/users/:userId", handler: getUser)
    router.post("/users", handler: createUser)
    router.get("/images", handler: getImages)
    router.get("/images/:imageId", handler: getImage)
    router.post("/images", handler: postImage)
    router.get("/users/:userId/images", handler: getImagesForUser)
    router.post("/push/images/:imageId", handler: sendPushNotification)
  }
}

extension ServerController: ServerProtocol {

  public func ping(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    response.headers.append("Content-Type", value: "text/plain; charset=utf-8")
    response.status(HTTPStatusCode.OK).send("Hello World, from BluePic-Server! Original URL: \(request.originalURL)")
    next()
  }
  
  /// This route is only for testing purposes
  public func token(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

    // Define error response just in case...
    var errorResponse = JSON([:])
    errorResponse["error"].stringValue = "Failed to retrieve MCA token."
    
    let baseStr = "\(mobileClientAccessProps.clientId):\(mobileClientAccessProps.secret)"
    
    var tempAuthHeader: String?
    let utf8BaseStr = baseStr.data(using: String.Encoding.utf8)
    tempAuthHeader = utf8BaseStr?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
    
    guard let authHeader = tempAuthHeader else {
      print("Could not generate authHeader...")
      response.status(HTTPStatusCode.internalServerError).send(json: errorResponse)
      next()
      return
    }
    
    let appGuid = mobileClientAccessProps.clientId
    print("authHeader: \(authHeader)")
    print("appGuid: \(appGuid)")
    
    // Request options
    var requestOptions: [ClientRequest.Options] = []
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
    
    // Make REST call against MCA server
    let req = HTTP.request(requestOptions) { resp in
      if let resp = resp, resp.statusCode == HTTPStatusCode.OK {
        do {
          var body = Data()
          try resp.readAllData(into: &body)
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
          do {
            var body = Data()
            let _ = try resp.read(into: &body)
            let str = String(data: body, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
            print("Response from MCA server: \(str)")
            
          }catch {
            Log.error("Failed to read response body.")
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
  func getPopularTags(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    let queryParams: [Database.QueryParameters] = [.group(true), .groupLevel(1)]
    database.queryByView("tags", ofDesign: "main_design", usingParameters: queryParams) { document, error in
      if let document = document, error == nil {
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
          response.error = BluePicLocalizedError(errorDescription: "Failed to obtain tags from database.")
        }
      } else {
        Log.error("Failed to obtain tags from database.")
        response.error = BluePicLocalizedError(errorDescription: "Failed to obtain tags from database.")
      }
      next()
    }
  }
  
  
  /// Route for getting all user documents.
  func getUsers(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    database.queryByView("users", ofDesign: "main_design", usingParameters: [.descending(true), .includeDocs(false)]) { document, error in
      if let document = document, error == nil {
        do {
          let users = try self.parseUsers(document: document)
          response.status(HTTPStatusCode.OK).send(json: users)
        } catch {
          Log.error("Failed to read users from database.")
          response.error = BluePicLocalizedError(errorDescription: "Failed to read users from database.")
        }
      } else {
        Log.error("Failed to read users from database.")
        response.error = BluePicLocalizedError(errorDescription: "Failed to read users from database.")
      }
      next()
    }
  }
  
  /// Route for getting a specific user document.
  func getUser(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    guard let userId = request.parameters["userId"] else {
      response.status(HTTPStatusCode.badRequest)
      response.error = BluePicLocalizedError(errorDescription: "Failed to obtain userId.")
      next()
      return
    }
    
    // Retrieve JSON document for user
    database.queryByView("users", ofDesign: "main_design", usingParameters: [ .descending(true), .includeDocs(false), .keys([NSString(string:userId)]) ]) { document, error in
      if let document = document, error == nil {
        do {
          let json = try self.parseUsers(document: document)
          let users = json["records"].arrayValue
          if users.count == 1 {
            response.status(HTTPStatusCode.OK).send(json: users[0])
          } else {
            throw ProcessingError.User("User not found!")
          }
        } catch {
          response.status(HTTPStatusCode.notFound)
          Log.error("User with id \(userId) was not found.")
          response.error = BluePicLocalizedError(errorDescription: "User with id \(userId) was not found.")
        }
      } else {
        response.status(HTTPStatusCode.internalServerError)
        Log.error("Failed to read requested user document.")
        response.error = BluePicLocalizedError(errorDescription: "Failed to read requested user document.")
      }
      next()
    }
  }
  
  /// Route for creating a new user document in the database.
  func createUser(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
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
        let _ = userJson.dictionaryObject?.removeValue(forKey: key)
      }
    }
    // Closure for adding new user document to the database
    let createRecord = {
      // Persist user document to database
      Log.verbose("About to add new user record '\(userId)' to the database.")
      self.database.create(userJson) { id, revision, document, error in
        do {
          if let document = document, error == nil {
            // Add revision number response document
            userJson["_rev"] = document["rev"]
            // Return user document back to caller
            try response.status(HTTPStatusCode.OK).send(json: userJson).end()
            next()
          } else {
            Log.error("Failed to add user to the system of records.")
            response.error = error ?? BluePicLocalizedError(errorDescription: "Failed to add user to the system of records.")
            next()
          }
        } catch {
          Log.error("Failed to add user to the system of records.")
          response.error = BluePicLocalizedError(errorDescription: "Failed to add user to the system of records.")
          next()
        }
      }
    }
    // Closure for verifying if user exists and creating new record
    let addUser = {
      // Verify if user already exists
      self.database.queryByView("users", ofDesign: "main_design", usingParameters: [ .descending(true), .includeDocs(false), .keys([NSString(string: userId)]) ]) { document, error in
        if let document = document, error == nil {
          do {
            let json = try self.parseUsers(document: document)
            let users = json["records"].arrayValue
            if users.count == 1 {
              response.status(HTTPStatusCode.OK).send(json: users[0])
              next()
            } else {
              createRecord()
            }
          } catch {
            createRecord()
          }
        } else {
          response.status(HTTPStatusCode.internalServerError)
          Log.error("Failed to process user request.")
          response.error = BluePicLocalizedError(errorDescription: "Failed to process user request.")
          next()
        }
      }
    }
    // Create completion handler closure
    let completionHandler = { (success: Bool) -> Void in
      if success {
        addUser()
      } else {
        Log.error("Failed to add user to the system of records.")
        response.error = BluePicLocalizedError(errorDescription: "Failed to add user to the system of records.")
        next()
      }
    }
    // Create container for user before adding record to database
    createContainer(withName: userId, completionHandler: completionHandler)
  }
  
  /**
   * Route for getting all image documents or all images that match a given tag.
   * As of now, searching on multiple tags is not supported in this app.
   * To search using multiple tags, additional logic is required.
   * See following URLs for further details:
   * https://issues.apache.org/jira/browse/COUCHDB-523
   * http://stackoverflow.com/questions/1468684/multiple-key-ranges-as-parameters-to-a-couchdb-view
   */
  func getImages(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    if var tag = request.queryParameters["tag"] {
      // Get images by tag
      // let _ = tag.characters.split(separator: ",").map(String.init)
      tag = StringUtils.decodeWhiteSpace(inString: tag)
      let queryParams: [Database.QueryParameters] =
        [.descending(true),
         .includeDocs(true),
         .reduce(false),
         .endKey([NSString(string: tag), NSString(string:"0"), NSString(string:"0"), NSNumber(integerLiteral: 0)]),
         .startKey([NSString(string: tag), NSObject()])]
      database.queryByView("images_by_tags", ofDesign: "main_design", usingParameters: queryParams) { document, error in
        if let document = document, error == nil {
          do {
            let images = try self.parseImages(document: document)
            response.status(HTTPStatusCode.OK).send(json: images)
          } catch {
            Log.error("Failed to find images by tag.")
            response.error = BluePicLocalizedError(errorDescription: "Failed to find images by tag.")
          }
        } else {
          Log.error("Failed to find images by tag.")
          response.error = BluePicLocalizedError(errorDescription: "Failed to find images by tag.")
        }
        next()
      }
    } else {
      // Get all images
      database.queryByView("images", ofDesign: "main_design", usingParameters: [.descending(true), .includeDocs(true)]) { document, error in
        if let document = document, error == nil {
          do {
            let images = try self.parseImages(document: document)
            response.status(HTTPStatusCode.OK).send(json: images)
          } catch {
            Log.error("Failed to retrieve all images.")
            response.error = BluePicLocalizedError(errorDescription: "Failed to retrieve all images.")
          }
        } else {
          Log.error("Failed to retrieve all images.")
          response.error = BluePicLocalizedError(errorDescription: "Failed to retrieve all images.")
        }
        next()
      }
    }
  }
  
  /// Route for getting a specific image document.
  func getImage(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    guard let imageId = request.parameters["imageId"] else {
      response.error = BluePicLocalizedError(errorDescription: "Failed to obtain imageId.")
      next()
      return
    }
    
    readImage(database: database, imageId: imageId, callback: { jsonData in
      if let jsonData = jsonData {
        response.status(HTTPStatusCode.OK).send(json: jsonData)
      } else {
        response.error = BluePicLocalizedError(errorDescription: "Failed to obtain JSON data from database.")
      }
      next()
    })
  }
  
  /// Route for getting all image documents for a given user.
  func getImagesForUser(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    guard let userId = request.parameters["userId"] else {
      response.error = BluePicLocalizedError(errorDescription: "Failed to obtain userId.")
      next()
      return
    }
    
    let queryParams: [Database.QueryParameters] =
      [.descending(true),
       .endKey([NSString(string: userId), NSString(string: "0")]),
       .startKey([NSString(string: userId), NSObject()])]
    database.queryByView("images_per_user", ofDesign: "main_design", usingParameters: queryParams) { document, error in
      if let document = document, error == nil {
        do {
          let images = try self.parseImages(forUserId: userId, usingDocument: document)
          response.status(HTTPStatusCode.OK).send(json: images)
        } catch {
          Log.error("Failed to get images for \(userId).")
          response.error = BluePicLocalizedError(errorDescription: "Failed to get images for \(userId).")
        }
      } else {
        Log.error("Failed to get images for \(userId).")
        response.error = BluePicLocalizedError(errorDescription: "Failed to get images for \(userId).")
      }
      next()
    }
  }
  
  /**
   * Route for uploading a new picture for a given user.
   * Uses a multi-part form data request to send data in the body.
   * The two items sent in the data is a Json string with image metadata
   * and the second piece is the actual image binary.
   * This route deals with processing and recording the data.
   */
  func postImage(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    // get multipart data for image metadata and imgage binary data
    var (imageJSON, image) = try parseMultipart(fromRequest: request)
    imageJSON = try updateImageJSON(json: imageJSON, withRequest: request)
    
    // Create closure
    let completionHandler = { (success: Bool) -> Void in
      if success {
        // Add image record to database
        self.database.create(imageJSON) { id, revision, doc, error in
          guard let id = id, let revision = revision, error == nil else {
            Log.error("Failed to create image record in Cloudant database.")
            if let error = error {
              Log.error("Error domain: \(error._domain); error code: \(error._code).")
            }
            response.error = BluePicLocalizedError(errorDescription: "Failed to create image record in Cloudant database.")
            next()
            return
          }
          // Contine processing of image (async request for OpenWhisk)
          self.processImage(withId: id)
          // Return image document to caller
          // Update JSON image document with _id, and _rev
          imageJSON["_id"].stringValue = id
          imageJSON["_rev"].stringValue = revision
          response.status(HTTPStatusCode.OK).send(json: imageJSON)
          next()
        }
      } else {
        Log.error("Failed to create image record in Cloudant database.")
        response.error = BluePicLocalizedError(errorDescription: "Failed to create image record in Cloudant database.")
      }
      next()
    }
    // Create container for user before creating image record in database
    store(image: image, withName: imageJSON["fileName"].stringValue, inContainer: imageJSON["userId"].stringValue, completionHandler: completionHandler)
  }
  
  /// Route for sending push notification (this uses the Push server SDK).
  func sendPushNotification(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    // Define response body
    var responseBody = JSON([:])
    responseBody["status"].boolValue = false
    
    guard let imageId = request.parameters["imageId"] else {
      response.status(HTTPStatusCode.badRequest)
      response.send(json: responseBody)
      next()
      return
    }
    
    readImage(database: database, imageId: imageId) { jsonImage in
      if let jsonImage = jsonImage {
        let apnsSettings = Notification.Settings.Apns(badge: nil, category: "imageProcessed", iosActionKey: nil, sound: nil, type: ApnsType.DEFAULT, payload: jsonImage.dictionaryObject)
        let target = Notification.Target(deviceIds: [jsonImage["deviceId"].stringValue], userIds: nil, platforms: [TargetPlatform.Apple], tagNames: nil)
        let message = Notification.Message(alert: "Your image was processed; check it out!", url: nil)
        let notification = Notification(message: message, target: target, apnsSettings: apnsSettings, gcmSettings: nil)
        self.pushNotificationsClient.send(notification: notification) { error in
          if let error = error {
            Log.error("Failed to send push notification: \(error)")
            response.status(HTTPStatusCode.internalServerError)
          } else {
            response.status(HTTPStatusCode.OK)
            responseBody["status"].boolValue = true
          }
          response.send(json: responseBody)
          next()
        }
      } else {
        response.status(HTTPStatusCode.internalServerError)
        response.send(json: responseBody)
        next()
      }
    }
  }
	
}
