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
import CloudEnvironment
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
  let cloudEnv = CloudEnv(mappingsFilePath: "config", cloudFoundryFile: "config/config.json")

  /**
   Method to get CouchDB credentials in a consumable form

   - throws: error when method can't get credentials

   - returns: Encapsulated ConnectionProperties object with the necessary info
   */
  func getCouchDBConnProps() throws -> ConnectionProperties {

    guard let couchDBCredentials = cloudEnv.getCloudantCredentials(name: "cloudant-credentials") else {
        throw BluePicError.IO("Failed to obtain Cloudant Credentials.")
    }

    let connProperties = ConnectionProperties(host: couchDBCredentials.host, 
                                              port: Int16(couchDBCredentials.port), 
                                              secured: true, 
                                              username: couchDBCredentials.username, 
                                              password: couchDBCredentials.password)

    return connProperties
  }

  /**
   Method to get Object Storage credentials in a consumable form

   - throws: error when method can't get credentials

   - returns: Encapsulated ObjectStorageConnProps object with the necessary info
   */
  func getObjectStorageConnProps() throws -> ObjectStorageConnProps {
    guard let objStoreCredentials = cloudEnv.getObjectStorageCredentials(name: "object-storage-credentials") else {
        throw BluePicError.IO("Failed to obtain Cloudant Credentials.")
    }

    let connProperties = ObjectStorageConnProps(projectId: objStoreCredentials.projectID, 
                                                userId: objStoreCredentials.userID, 
                                                password: objStoreCredentials.password)

    return connProperties
  }

  /**
   Method to get App ID credentials in a consumable form

   - throws: error when method can't get credentials

   - returns: Encapsulated AppIdProps object with the necessary info
   */
  func getAppIdProps() throws -> AppIdProps {
    guard let appIdCredentials = cloudEnv.getAppIDCredentials(name: "app-id-credentials") else {
      throw BluePicError.IO("Failed to obtain App ID service and/or its credentials.")
    }

    let secret = appIdCredentials.secret
    let serverUrl = appIdCredentials.oauthServerUrl
    let clientId = appIdCredentials.clientId
    let tenantId = appIdCredentials.tenantId

    let appIdProperties = AppIdProps(secret: secret, serverUrl: serverUrl, clientId: clientId, tenantId: tenantId)
    return appIdProperties
  }

  /**
   Method to get IBM Push credentials in a consumable form

   - throws: error when method can't get credentials

   - returns: Encapsulated IbmPushProps object with the necessary info
   */
  func getIbmPushProps() throws -> IbmPushProps {
    guard let pushCredentials = cloudEnv.getPushSDKCredentials(name: "app-push-credentials") else {
      throw BluePicError.IO("Failed to obtain IBM Push service and/or its credentials.")
    }

    let appGuid = pushCredentials.appGuid
    let url = "" //pushCredentials.url
    let adminUrl = "" //pushCredentials.admin_url
    let secret = pushCredentials.appSecret

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
