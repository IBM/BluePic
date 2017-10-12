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
import KituraSession
import CouchDB
import LoggerAPI
import SwiftyJSON
import BluemixAppID
import BluemixPushNotifications
import Credentials
import Configuration
import CredentialsFacebook
import CloudEnvironment
import SafetyContracts
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

  public let router = Router()

  let couchDBConnProps: ConnectionProperties
  let objStorageConnProps: ObjectStorageCredentials
  let appIdProps: AppIDCredentials
  let ibmPushProps: PushSDKCredentials
  let openWhiskProps: OpenWhiskProps
  let database: Database
  var objectStorageConn: ObjectStorageConn
  let pushNotificationsClient: PushNotifications

  // Instance constants
  let cloudEnv: CloudEnv = CloudEnv()

  let encoder = JSONEncoder()
  let decoder = JSONDecoder()

  let credentials = Credentials()
  let webCredentialsPlugin: WebAppKituraCredentialsPlugin
  let landing_url = "/#/homepage"

  public var port: Int {
    return cloudEnv.port
  }

  public init() throws {

    guard let couchDBCredentials = cloudEnv.getCloudantCredentials(name: "cloudant-credentials"),
      let objStoreCredentials = cloudEnv.getObjectStorageCredentials(name: "object-storage-credentials"),
      let appIdCredentials = cloudEnv.getAppIDCredentials(name: "app-id-credentials"),
      let pushCredentials = cloudEnv.getPushSDKCredentials(name: "app-push-credentials"),
      let openWhiskJson = cloudEnv.getDictionary(name: "open-whisk-credentials"),
      let openWhiskCredentials = OpenWhiskProps(dict: openWhiskJson) else {

        throw BluePicError.IO("Failed to obtain appropriate credentials.")
    }

    // Create Props

    couchDBConnProps = ConnectionProperties(host: couchDBCredentials.host,
                                            port: Int16(couchDBCredentials.port),
                                            secured: true,
                                            username: couchDBCredentials.username,
                                            password: couchDBCredentials.password)
    appIdProps = appIdCredentials
    ibmPushProps = pushCredentials
    objStorageConnProps = objStoreCredentials
    openWhiskProps = openWhiskCredentials

    // Instantiate Objects

    let dbClient = CouchDBClient(connectionProperties: couchDBConnProps)
    database = dbClient.database("bluepic_db")

    objectStorageConn = ObjectStorageConn(credentials: objStorageConnProps)

    pushNotificationsClient = PushNotifications(bluemixRegion: PushNotifications.Region.US_SOUTH,
                                                bluemixAppGuid: ibmPushProps.appGuid,
                                                bluemixAppSecret: ibmPushProps.appSecret)

    let options = [
      "clientId": appIdProps.clientId,
      "secret": appIdProps.secret,
      "tenantId": appIdProps.tenantId,
      "oauthServerUrl": appIdProps.oauthServerUrl,
      "redirectUri": "http://localhost:8080/ibm/bluemix/appid/callback"
    ]

    webCredentialsPlugin = WebAppKituraCredentialsPlugin(options: options)

    setupRoutes()
  }

  private func setupRoutes() {

    Log.verbose("Defining middleware for server...")

    credentials.register(plugin: webCredentialsPlugin)

    router.all(middleware: Session(secret: "Very very secret..."))
    router.all("/", middleware: StaticFileServer(path: "./BluePic-Web"))

    router.all(handler: credentials.authenticate(credentialsType: webCredentialsPlugin.name), { (request, response, next) in
      let appIdAuthContext: JSON? = request.session?[WebAppKituraCredentialsPlugin.AuthContext]
      let identityTokenPayload: JSON? = appIdAuthContext?["identityTokenPayload"]

      guard appIdAuthContext?.dictionary != nil, identityTokenPayload?.dictionary != nil else {
        response.status(.unauthorized)
        return next()
      }

      next()
    })

    // Assign middleware instance, endpoint securing temporarily disabled
    router.get("/users", middleware: credentials)
    router.post("/users", middleware: credentials)
    router.post("/push", middleware: credentials)
    router.get("/ping", middleware: credentials)
    router.post("/images", middleware: credentials)
    router.all("/images", middleware: BodyParser())

    Log.verbose("Defining routes for server...")
    router.get("/ping", handler: ping)
    router.get("/users/:userId/images", handler: getImagesForUser)
    router.get("/images", codableHandler: getImage)
    router.get("/images", codableHandler: getImages)
    router.get("/images/tag", codableHandler: getImagesByTag)
    router.post("/images", codableHandler: postImage)
    router.get("/tags", codableHandler: getTags)
    router.get("/users", codableHandler: getUsers)
    router.get("/users", codableHandler: getUser)
    router.post("/users", codableHandler: postUser)
    router.post("/push/images", codableHandler: sendPushNotification)

    // Authentication Redirects
    let handler = credentials.authenticate(credentialsType: webCredentialsPlugin.name,
                                          successRedirect: landing_url,
                                          failureRedirect: landing_url)

    router.get("/ibm/bluemix/appid/login", handler: handler)
    router.get("/ibm/bluemix/appid/callback", handler: handler)
    router.get("/ibm/bluemix/appid/logout", handler: logout)
  }
}

extension ServerController: ServerProtocol {

  public func logout(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    self.credentials.logOut(request: request)
    webCredentialsPlugin.logout(request: request)
    _ = try? response.redirect(landing_url)
  }

  public func ping(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    response.headers.append("Content-Type", value: "text/plain; charset=utf-8")
    response.status(HTTPStatusCode.OK).send("Hello World, from BluePic-Server! Original URL: \(request.originalURL)")
    next()
  }

  /// Route for getting all image documents for a given user.
  func getImagesForUser(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    guard let userId = request.parameters["userId"] else {
      response.error = BluePicLocalizedError.missingUserId
      next()
      return
    }

    let anyUserId = userId as Database.KeyType
    let queryParams: [Database.QueryParameters] = [
                                                    .descending(true),
                                                    .endKey([anyUserId, "0" as Database.KeyType]),
                                                    .startKey([anyUserId, NSObject()])
                                                  ]

    database.queryByView("images_per_user", ofDesign: "main_design", usingParameters: queryParams) { document, error in
      if let document = document, error == nil {
        do {
          let images = try self.parseImages(forUserId: userId, usingDocument: document)
          response.status(HTTPStatusCode.OK).send(json: images)
        } catch {
          Log.error("Failed to get images for \(userId).")
          response.error = BluePicLocalizedError.getImagesFailed(userId)
        }
      } else {
        Log.error("Failed to get images for \(userId).")
        response.error = BluePicLocalizedError.getImagesFailed(userId)
      }
      next()
    }
  }

  ///                ///
  /// Codable Routes ///
  ///                ///

  /// Route for getting the most popular tags
  func getTags(respondWith: @escaping ([TagCount]?, Swift.Error?) -> Void) {

    let params: [Database.QueryParameters] = [.group(true), .groupLevel(1)]

    database.queryByView("tags", ofDesign: "main_design", usingParameters: params) { document, error in

      do {
        guard error == nil, let document = document else {
          throw BluePicLocalizedError.readDocumentFailed
        }

        let rows = try document["rows"].rawData()
        var tags = try self.decoder.decode([TagCount].self, from: rows)

        // Sort tags in descending order
        tags = tags.sorted { $0.value > $1.value }

        // Slice tags array (max number of items is 10)
        if tags.count > 10 { tags = Array(tags[0...9]) }

        respondWith(tags, nil)

      } catch {
        Log.error("\(error)")
        respondWith(nil, error)
      }
    }
  }

  /// Route for getting a specific image
  func getImage(id: String, respondWith: @escaping (Image?, Swift.Error?) -> Void) {
    readImage(database: database, imageId: id, callback: respondWith)
  }

  /// Route for getting all images
  func getImages(respondWith: @escaping ([Image]?, Swift.Error?) -> Void) {
    readImagesByView("images", database: database, callback: respondWith)
  }

  /// Route for getting images with a specific tag
  func getImagesByTag(tag: String, respondWith: @escaping ([Image]?, Swift.Error?) -> Void) {
    let tag = StringUtils.decodeWhiteSpace(inString: tag)
    let anyTag = tag as Database.KeyType
    let zeroKey = "0" as Database.KeyType
    let queryParams: [Database.QueryParameters] = [
                                                  .reduce(false),
                                                  .endKey([anyTag, zeroKey, zeroKey, NSNumber(integerLiteral: 0)]),
                                                  .startKey([anyTag, NSObject()])
                                                  ]
    readImagesByView("images_by_tags", params: queryParams, database: database, callback: respondWith)
  }

  /// Route for creating a new image
  func postImage(image: Image, respondWith: @escaping (Image?, Swift.Error?) -> Void) {

    do {
      let imageData = try self.encoder.encode(image)
      let imageJson = JSON(data: imageData)

      let completionHandler = { (success: Bool) -> Void in

        guard success else {
          Log.error("Failed to create image record in Cloudant database.")
          respondWith(nil, BluePicLocalizedError.addImageRecordFailed)
          return
        }

        // Add image record to database
        self.database.create(imageJson) { id, revision, _, error in

          guard error == nil, let id = id, let revision = revision else {
            Log.error("Failed to add user to the system of records.")
            respondWith(nil, BluePicLocalizedError.addImageRecordFailed)
            return
          }

          var image = image
          image.rev = revision

          respondWith(image, nil)

          self.processImage(withId: id)  // Contine processing of image (async request for OpenWhisk)

        }
      }
      // Create container for user before creating image record in database
      store(image: imageData, withName: image.fileName, inContainer: image.userId, completionHandler: completionHandler)
    } catch {
      Log.error("\(error)")
      respondWith(nil, error)
    }
  }

  /// Route for getting a specific user document.
  func getUser(id: String, respondWith: @escaping (User?, Swift.Error?) -> Void) {

    let params: [Database.QueryParameters] = [
      .descending(true),
      .includeDocs(false),
      .keys([id as Database.KeyType])
    ]

    database.queryByView("users", ofDesign: "main_design", usingParameters: params) { document, error in

      do {
        guard error == nil, let document = document  else {
          throw BluePicLocalizedError.readDocumentFailed
        }

        guard let first = try document.toData().first else {
          throw BluePicLocalizedError.noUserId(id)
        }

        let user = try self.decoder.decode(User.self, from: first)
        respondWith(user, nil)

      } catch {
        Log.error("\(error)")
        respondWith(nil, error)
      }
    }
  }

  /// Route for getting all user documents.
  func getUsers(respondWith: @escaping ([User]?, Swift.Error?) -> Void) {

    let params: [Database.QueryParameters] = [.descending(true), .includeDocs(false)]

    database.queryByView("users", ofDesign: "main_design", usingParameters: params) { document, error in

      do {
        guard error == nil, let document = document else {
          throw BluePicLocalizedError.readDocumentFailed
        }

        let rows = try document.toData()
        let users = try rows.map { try self.decoder.decode(User.self, from: $0) }

        respondWith(users, nil)

      } catch {
        Log.error("\(error)")
        respondWith(nil, error)
      }
    }
  }

  /// Route for creating a new user
  func postUser(user: User, respondWith: @escaping (User?, Swift.Error?) -> Void) {

    // Closure for adding new user document to the database
    let createRecord = {
      Log.verbose("Creating new user record '\(user.id)'.")

      do {
        let userData = try self.encoder.encode(user)
        let userJson = JSON(data: userData)

        self.database.create(userJson) { _, _, document, error in
          guard error == nil, let document = document else {
            Log.error("Failed to add user to the system of records.")
            respondWith(nil, BluePicLocalizedError.readDocumentFailed)
            return
          }

          var user = user
          user.rev = document["rev"].string

          respondWith(user, nil)
        }
      } catch {
        Log.error("\(error)")
        respondWith(nil, error)
      }
    }

    // Closure for verifying if user exists and creating new record
    let addUser = {

      let params: [Database.QueryParameters] = [
        .descending(true),
        .includeDocs(false),
        .keys([user.id as Database.KeyType])
      ]

      self.database.queryByView("users", ofDesign: "main_design", usingParameters: params) { document, error in

        do {
          guard error == nil, let document = document else {
            Log.error("Failed to read requested user document.")
            respondWith(user, BluePicLocalizedError.readDocumentFailed)
            return
          }

          guard let first = try document.toData().first else {
            throw BluePicLocalizedError.missingUserId
          }

          let user = try self.decoder.decode(User.self, from: first)
          respondWith(user, nil)

        } catch {
          Log.error("User with id \(user.id) was not found.")
          createRecord()
        }
      }
    }

    // Create completion handler closure
    let completionHandler = { (success: Bool) -> Void in
      guard success else {
        Log.error("Failed to add user to the system of records.")
        respondWith(user, BluePicLocalizedError.addUserRecordFailed("User with id: \(user.id)"))
        return
      }
      addUser()
    }

    // Create container for user before adding record to database
    createContainer(withName: user.id, completionHandler: completionHandler)
  }

  /// Route for sending a push notification
  func sendPushNotification(imageId: String, respondWith: @escaping (NotificationStatus?, Swift.Error?) -> Void) {

    readImage(database: database, imageId: imageId) { image, error in
      do {
        guard let image = image, let deviceId = image.deviceId, error == nil else {
          throw error ?? BluePicLocalizedError.getImagesFailed(imageId)
        }

        let data = try self.encoder.encode(image)
        let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)

        guard let dict = json as? [String: Any] else {
          throw BluePicLocalizedError.getImagesFailed(imageId)
        }

        let apnsSettings = Notification.Settings.Apns(
                                                      badge: nil,
                                                      interactiveCategory: "imageProcessed",
                                                      iosActionKey: nil,
                                                      sound: nil,
                                                      type: ApnsType.DEFAULT,
                                                      payload: dict
                                                      )

        let target = Notification.Target(deviceIds: [deviceId], userIds: nil, platforms: nil, tagNames: nil)
        let message = Notification.Message(alert: "Your image was processed; check it out!", url: nil)
        let notification = Notification(message: message, target: target, apnsSettings: apnsSettings, gcmSettings: nil)

        self.pushNotificationsClient.send(notification: notification) { error in
          guard error == nil else {
            respondWith(nil, BluePicLocalizedError.requestFailed)
            return
          }
        }
      } catch {
        respondWith(NotificationStatus(status: false), error)
      }
    }
  }
}
