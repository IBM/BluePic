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
*/

import Foundation
import CouchDB
import SwiftyJSON
import LoggerAPI
import Configuration
import CloudFoundryConfig
import BluemixObjectStorage

public struct Configuration {

  /**
   Enum used for Configuration errors
   - IO: case to indicate input/output error
   */
  public enum BluePicError: Error {
    case IO(String)
  }

    // Instance constants
    let configurationFile = "cloud_config.json"
    let configMgr = ConfigurationManager()

    init() throws {
        let path = Configuration.getAbsolutePath(relativePath: "/\(configurationFile)", useFallback: false)

        guard let finalPath = path else {
            Log.warning("Could not find '\(configurationFile)'.")
            configMgr.load(.environmentVariables)
            return
        }

        configMgr.load(file: finalPath).load(.environmentVariables)
        Log.info("Using configuration values from '\(configurationFile)'.")
    }

  /**
   Method to get CouchDB credentials in a consumable form

   - throws: error when method can't get credentials

   - returns: Encapsulated ConnectionProperties object with the necessary info
   */
  func getCouchDBConnProps() throws -> ConnectionProperties {
    let couchDBCredentials = try configMgr.getCloudantService(name: "BluePic-Cloudant")
    let connProperties = ConnectionProperties(host: couchDBCredentials.host, port: Int16(couchDBCredentials.port), secured: true, username: couchDBCredentials.username, password: couchDBCredentials.password)
    return connProperties
  }

  /**
   Method to get Object Storage credentials in a consumable form

   - throws: error when method can't get credentials

   - returns: Encapsulated ObjectStorageConnProps object with the necessary info
   */
  func getObjectStorageConnProps() throws -> ObjectStorageConnProps {
    let objStoreCredentials = try configMgr.getObjectStorageService(name: "BluePic-Object-Storage")
    let connProperties = ObjectStorageConnProps(projectId: objStoreCredentials.projectID, userId: objStoreCredentials.userID, password: objStoreCredentials.password)
    return connProperties
  }

  /**
   Method to get App ID credentials in a consumable form

   - throws: error when method can't get credentials

   - returns: Encapsulated AppIdProps object with the necessary info
   */
  func getAppIdProps() throws -> AppIdProps {
    guard let appIdCredentials = configMgr.getService(spec: "BluePic-App-ID")?.credentials else {
      throw BluePicError.IO("Failed to obtain App ID service and/or its credentials.")
    }

    guard let secret = appIdCredentials["secret"] as? String,
    let serverUrl = appIdCredentials["oauthServerUrl"] as? String,
    let clientId = appIdCredentials["clientId"] as? String else {
      throw BluePicError.IO("Failed to obtain App ID credentials.")
    }

    let appIdProperties = AppIdProps(secret: secret, serverUrl: serverUrl, clientId: clientId)
    return appIdProperties
  }

  /**
   Method to get IBM Push credentials in a consumable form

   - throws: error when method can't get credentials

   - returns: Encapsulated IbmPushProps object with the necessary info
   */
  func getIbmPushProps() throws -> IbmPushProps {
    guard let pushCredentials = configMgr.getService(spec: "BluePic-IBM-Push")?.credentials else {
      throw BluePicError.IO("Failed to obtain IBM Push service and/or its credentials.")
    }

    guard let appGuid = pushCredentials["appGuid"] as?String,
      let url = pushCredentials["url"] as?String,
      let adminUrl = pushCredentials["admin_url"] as?String,
      let secret = pushCredentials["appSecret"] as?String else {
        throw BluePicError.IO("Failed to obtain IBM Push credentials.")
    }

    let ibmPushProperties = IbmPushProps(appGuid: appGuid, url: url, adminUrl: adminUrl, secret: secret)
    return ibmPushProperties
  }

  func getOpenWhiskProps() throws -> OpenWhiskProps {
    let relativePath = "/properties.json"
    guard let workingPath = Configuration.getAbsolutePath(relativePath: relativePath, useFallback: true) else {
      throw BluePicError.IO("Could not find file at relative path \(relativePath).")
    }

    let url = URL(fileURLWithPath: workingPath)
    let propertiesData = try Data(contentsOf: url)
    let propertiesJson = JSON(data: propertiesData)
    if let openWhiskJson = propertiesJson.dictionary?["openWhisk"],
        let hostName = openWhiskJson["hostName"].string,
        let urlPath = openWhiskJson["urlPath"].string,
        let authToken = openWhiskJson["authToken"].string {
            let utf8BaseStr = authToken.data(using: String.Encoding.utf8)
            guard let computedAuthToken = utf8BaseStr?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) else {
                throw BluePicError.IO("Could not perform base64 encoding on authToken")
            }
        return OpenWhiskProps(hostName: hostName, urlPath: urlPath, authToken: computedAuthToken)
    }

    throw BluePicError.IO("Failed to obtain OpenWhisk credentials.")
    }

  private static func getAbsolutePath(relativePath: String, useFallback: Bool) -> String? {
    let initialPath = #file
    let components = initialPath.characters.split(separator: "/").map(String.init)
    let notLastThree = components[0..<components.count - 3]
    var filePath = "/" + notLastThree.joined(separator: "/") + relativePath

    let fileManager = FileManager.default

    if fileManager.fileExists(atPath: filePath) {
      return filePath
    } else if useFallback {
      // Get path in alternate way, if first way fails
      let currentPath = fileManager.currentDirectoryPath
      filePath = currentPath + relativePath
      if fileManager.fileExists(atPath: filePath) {
        return filePath
      } else {
        return nil
      }
    } else {
      return nil
    }
  }

}
