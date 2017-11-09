/**
 * Copyright IBM Corporation 2016, 2017
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
import KituraContracts
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

  let database: Database

  let cloudFunctionsProps: CloudFunctionsProps
  var objectStorageConn: ObjectStorageConn
  let pushNotificationsClient: PushNotifications
  let objStorageConnProps: ObjectStorageCredentials

  // Instance constants
  let cloudEnv: CloudEnv = CloudEnv()

  let encoder = JSONEncoder()
  let decoder = JSONDecoder()

  let credentials = Credentials(options: [
    WebAppKituraCredentialsPlugin.AllowAnonymousLogin: true,
    WebAppKituraCredentialsPlugin.AllowCreateNewAnonymousUser: true
  ])

  // let credentials = Credentials()
  // let webCredentialsPlugin: WebAppKituraCredentialsPlugin
  let landing_url = "/#/homepage"

  let kTagsPath = "/tags"
  let kPingPath = "/ping"
  let kUsersPath = "/users"
  let kImagesPath = "/images"
  let kPushPath = "/push/images"

  public var port: Int {
    return cloudEnv.port
  }

  public init() throws {

    guard let couchDBCredentials = cloudEnv.getCloudantCredentials(name: "cloudant-credentials"),
      let objStoreCredentials = cloudEnv.getObjectStorageCredentials(name: "object-storage-credentials"),
      // let appIdCredentials = cloudEnv.getAppIDCredentials(name: "app-id-credentials"),
      let pushCredentials = cloudEnv.getPushSDKCredentials(name: "app-push-credentials"),
      let CloudFunctionsJson = cloudEnv.getDictionary(name: "cloud-functions-credentials"),
      let CloudFunctionsCredentials = CloudFunctionsProps(dict: CloudFunctionsJson) else {

        throw BluePicError.IO("Failed to obtain appropriate credentials.")
    }

    cloudFunctionsProps = CloudFunctionsCredentials
    objStorageConnProps = objStoreCredentials

    // Instantiate Objects
    let couchDBConnProps = ConnectionProperties(host: couchDBCredentials.host,
                                                port: Int16(couchDBCredentials.port),
                                                secured: true,
                                                username: couchDBCredentials.username,
                                                password: couchDBCredentials.password)

    let dbClient = CouchDBClient(connectionProperties: couchDBConnProps)
    database = dbClient.database("bluepic_db")

    objectStorageConn = ObjectStorageConn(credentials: objStoreCredentials)

    pushNotificationsClient = PushNotifications(bluemixRegion: PushNotifications.Region.US_SOUTH,
                                                bluemixAppGuid: pushCredentials.appGuid,
                                                bluemixAppSecret: pushCredentials.appSecret)
    /*
    let options = [
      "clientId": appIdCredentials.clientId,
      "secret": appIdCredentials.secret,
      "tenantId": appIdCredentials.tenantId,
      "oauthServerUrl": appIdCredentials.oauthServerUrl,
      "redirectUri": "http://localhost:8080/ibm/bluemix/appid/callback"
    ]

    webCredentialsPlugin = WebAppKituraCredentialsPlugin(options: options)
     */

    router.all("/", middleware: StaticFileServer(path: "./BluePic-Web"))

    // setupAuth()
    // setupMiddleware()
    setupRoutes()
  }

  private func setupAuth() {
    /* Credentials temporarily disabled

    /// Enable Credentials Plugin and Authorizaiton handlers
    credentials.register(plugin: webCredentialsPlugin)

    router.all(handler: credentials.authenticate(credentialsType: webCredentialsPlugin.name), { (request, response, next) in
      Log.debug("Checking authorization ---------")
      let appIdAuthContext: JSON? = request.session?[WebAppKituraCredentialsPlugin.AuthContext]
      let identityTokenPayload: JSON? = appIdAuthContext?["identityTokenPayload"]

      guard appIdAuthContext?.dictionary != nil, identityTokenPayload?.dictionary != nil else {
        response.status(.unauthorized)
        return next()
      }

      next()
    })

    let handler = credentials.authenticate(credentialsType: webCredentialsPlugin.name,
                                           successRedirect: landing_url,
                                           failureRedirect: landing_url)

    router.get("/ibm/bluemix/appid/login", handler: handler)
    router.get("/ibm/bluemix/appid/callback", handler: handler)
    router.get("/ibm/bluemix/appid/logout", handler: logout)
    */
  }

  private func setupMiddleware() {
    /*
    Log.verbose("Defining middleware for server...")

    router.all(middleware: Session(secret: "Very very secret..."))

    /// Protect Endpoints
    router.get("/users", middleware: credentials)
    router.post("/users", middleware: credentials)
    router.post("/push", middleware: credentials)
    router.get("/ping", middleware: credentials)
    router.post("/images", middleware: credentials)
    */
  }

  private func setupRoutes() {
    Log.verbose("Defining routes for server...")

    router.get(kPingPath, handler: ping)
    router.get(kUsersPath + "/:userId/images", handler: getImagesForUser)
    router.get(kImagesPath, handler: getImage)
    router.get(kImagesPath, handler: getImages)
    router.get(kImagesPath + "/tag", handler: getImagesByTag)
    router.post(kImagesPath, handler: postImage)
    router.get(kTagsPath, handler: getTags)
    router.get(kUsersPath, handler: getUsers)
    router.get(kUsersPath, handler: getUser)
    router.post(kUsersPath, handler: postUser)
    router.post(kPushPath + "/:imageId", handler: sendPushNotification)
  }
}

extension ServerController: ServerProtocol {
  /*
  fileprivate func logout(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    credentials.logOut(request: request)
    webCredentialsPlugin.logout(request: request)
    _ = try? response.redirect(landing_url)
  }
 */

  /// Route for handling ping request
  public func ping(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    response.headers.append("Content-Type", value: "text/plain; charset=utf-8")
    response.status(.OK).send("Hello World, from BluePic-Server! Original URL: \(request.originalURL)")
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
      .endKey([anyUserId, "0" as Database.KeyType]),
      .startKey([anyUserId, NSObject()])
    ]
    self.readByView(View.images_per_user, params: queryParams, type: Image.self, database: database) { images, error in
      guard let images = images, error == nil else {
        Log.error("\(error ?? .notFound)")
        return
      }

      response.status(.OK).send(json: images)
      next()
    }
  }

  ///                ///
  /// Codable Routes ///
  ///                ///

  /// Route for getting the most popular tags
  func getTags(respondWith: @escaping ([String]?, RequestError?) -> Void) {

    let params: [Database.QueryParameters] = [.group(true), .groupLevel(1)]

    readByView(View.tags, params: params, type: PopularTag.self, database: database) { tags, error in
      guard error == nil, var tags = tags else {
        respondWith(nil, error ?? .notFound)
        return
      }

      // Sort tags in descending order
      tags = tags.sorted { $0.value > $1.value }

      // Slice tags array (max number of items is 10)
      if tags.count > 10 { tags = Array(tags[0...9]) }

      respondWith(tags.map { $0.key }, nil)
    }
  }

  /// Route for getting a specific image
  func getImage(id: String, respondWith: @escaping (Image?, RequestError?) -> Void) {
    readImage(database: database, imageId: id, callback: respondWith)
  }

  /// Route for getting all images
  func getImages(respondWith: @escaping ([Image]?, RequestError?) -> Void) {
    let params: [Database.QueryParameters] = [.includeDocs(true)]
    readByView(View.images, params: params, type: Image.self, database: database, callback: respondWith)
  }

  /// Route for getting images with a specific tag
  func getImagesByTag(tag: String, respondWith: @escaping ([Image]?, RequestError?) -> Void) {
    let tag = StringUtils.decodeWhiteSpace(inString: tag)
    let anyTag = tag as Database.KeyType
    let zeroKey = "0" as Database.KeyType
    let queryParams: [Database.QueryParameters] = [
      .includeDocs(true),
      .reduce(false),
      .endKey([anyTag, zeroKey, zeroKey, NSNumber(integerLiteral: 0)]),
      .startKey([anyTag, NSObject()])
    ]
    readByView(View.images_by_tag, params: queryParams, type: Image.self, database: database, callback: respondWith)
  }

  /// Route for creating a new image
  func postImage(image: Image, respondWith: @escaping (Image?, RequestError?) -> Void) {
    do {
      let completionHandler = { (success: Bool) -> Void in

        guard success else {
          Log.error("Failed to create image record in Cloudant database.")
          respondWith(nil, .internalServerError)
          return
        }

        var image = image
        image.url = self.generateUrl(forContainer: image.userId, forImage: image.fileName)

        self.createObject(object: image, database: self.database) { image, error in
          guard let image = image, error == nil else {
            respondWith(nil, .internalServerError)
            return
          }

          self.processImage(withId: image.id)  // Contine processing of image (async request for CloudFunctions)
          respondWith(image, nil)
        }
      }
      // Create container for user before creating image record in database
      try store(image: image, completionHandler: completionHandler)
    } catch {
      Log.error("\(error)")
      respondWith(nil, .internalServerError)
    }
  }

  /// Route for getting a specific user document.
  func getUser(id: String, respondWith: @escaping (User?, RequestError?) -> Void) {

    let params: [Database.QueryParameters] = [ .keys([id as Database.KeyType]) ]

    readByView(View.users, params: params, type: User.self, database: database) { users, error in
      guard error == nil, let user = users?.first else {
        respondWith(nil, error ?? .notFound)
        return
      }

      respondWith(user, nil)
    }
  }

  /// Route for getting all user documents.
  func getUsers(respondWith: @escaping ([User]?, RequestError?) -> Void) {
    let params: [Database.QueryParameters] = [ .includeDocs(false) ]
    readByView(View.users, params: params, type: User.self, database: database, callback: respondWith)
  }

  /// Route for creating a new user
  func postUser(user: User, respondWith: @escaping (User?, RequestError?) -> Void) {

    // Closure for adding new user document to the database
    let createRecord = {
      Log.verbose("Creating new user record '\(user.id)'.")
      self.createObject(object: user, database: self.database, callback: respondWith)
    }

    // Closure for verifying if user exists and creating new record
    let addUser = {
      self.getUser(id: user.id) { user, error in
        guard error == nil, let usr = user else {
          Log.verbose("User with id \(user?.id ?? "") was not found.")
          createRecord()
          return
        }

        respondWith(usr, nil)
      }
    }

    // Create completion handler closure
    let completionHandler = { (success: Bool) -> Void in
      guard success else {
        Log.error("Failed to add user to the system of records.")
        respondWith(user, .internalServerError)
        return
      }
      addUser()
    }

    // Create container for user before adding record to database
    createContainer(withName: user.id, completionHandler: completionHandler)
  }

  /// Route for sending a push notification
  func sendPushNotification(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

    guard let imageId = request.parameters["imageId"] else {
      response.status(.badRequest)
      response.send(NotificationStatus(status: false))
      next()
      return
    }

    readImage(database: database, imageId: imageId) { image, error in
      do {
        guard let image = image, let deviceId = image.deviceId, error == nil else {
          throw error ?? .internalServerError
        }

        let data = try self.encoder.encode(image)
        let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)

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
          if let error = error {
            Log.error("\(error)")
            response.status(.internalServerError)
            response.send(NotificationStatus(status: false))
          } else {
            response.send(NotificationStatus(status: true))
          }
          next()
        }
      } catch {
        Log.error("\(error)")
        response.status(.internalServerError)
        response.send(NotificationStatus(status: false))
        next()
      }
    }
  }
}
