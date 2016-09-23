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
import CouchDB
import SwiftyJSON
import LoggerAPI
import CloudFoundryEnv
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
    let appEnv: AppEnv
    
    init() throws {
        let path = Configuration.getAbsolutePath(relativePath: "/\(configurationFile)", useFallback: false)

        guard let finalPath = path else {
            Log.warning("Could not find '\(configurationFile)'.")
            appEnv = try CloudFoundryEnv.getAppEnv()
            return
        }

        let url = URL(fileURLWithPath: finalPath)
        let configData = try Data(contentsOf: url)
        let configJson = JSON(data: configData)
        appEnv = try CloudFoundryEnv.getAppEnv(options: configJson)
        Log.info("Using configuration values from '\(configurationFile)'.")
    }

  /**
   Method to get CouchDB credentials in a consumable form

   - throws: error when method can't get credentials

   - returns: Encapsulated ConnectionProperties object with the necessary info
   */
  func getCouchDBConnProps() throws -> ConnectionProperties {
    if let couchDBCredentials = appEnv.getService(spec: "BluePic-Cloudant")?.credentials {
      if let host = couchDBCredentials["host"].string,
      let user = couchDBCredentials["username"].string,
      let password = couchDBCredentials["password"].string,
      let port = couchDBCredentials["port"].int {
        let connProperties = ConnectionProperties(host: host, port: Int16(port), secured: true, username: user, password: password)
        return connProperties
      }
    }
    throw BluePicError.IO("Failed to obtain database service and/or its credentials.")
  }

  /**
   Method to get Object Storage credentials in a consumable form

   - throws: error when method can't get credentials

   - returns: Encapsulated ObjectStorageConnProps object with the necessary info
   */
  func getObjectStorageConnProps() throws -> ObjectStorageConnProps {
    guard let objStoreCredentials = appEnv.getService(spec: "BluePic-Object-Storage")?.credentials else {
      throw BluePicError.IO("Failed to obtain object storage service and/or its credentials.")
    }

    guard let projectId = objStoreCredentials["projectId"].string,
    let userId = objStoreCredentials["userId"].string,
    let password = objStoreCredentials["password"].string else {
      throw BluePicError.IO("Failed to obtain object storage credentials.")
    }

    let connProperties = ObjectStorageConnProps(projectId: projectId, userId: userId, password: password)
    return connProperties
  }

  /**
   Method to get MCA credentials in a consumable form

   - throws: error when method can't get credentials

   - returns: Encapsulated MobileClientAccessProps object with the necessary info
   */
  func getMobileClientAccessProps() throws -> MobileClientAccessProps {
    guard let mcaCredentials = appEnv.getService(spec: "BluePic-Mobile-Client-Access")?.credentials else {
      throw BluePicError.IO("Failed to obtain MCA service and/or its credentials.")
    }

    guard let secret = mcaCredentials["secret"].string,
    let serverUrl = mcaCredentials["serverUrl"].string,
    let clientId = mcaCredentials["clientId"].string else {
      throw BluePicError.IO("Failed to obtain MCA credentials.")
    }

    let mcaProperties = MobileClientAccessProps(secret: secret, serverUrl: serverUrl, clientId: clientId)
    return mcaProperties
  }

  /**
   Method to get IBM Push credentials in a consumable form

   - throws: error when method can't get credentials

   - returns: Encapsulated IbmPushProps object with the necessary info
   */
  func getIbmPushProps() throws -> IbmPushProps {
    guard let pushCredentials = appEnv.getService(spec: "BluePic-IBM-Push")?.credentials else {
      throw BluePicError.IO("Failed to obtain IBM Push service and/or its credentials.")
    }

    guard let url = pushCredentials["url"].string,
      let adminUrl = pushCredentials["admin_url"].string,
      let secret = pushCredentials["appSecret"].string else {
        throw BluePicError.IO("Failed to obtain IBM Push credentials.")
    }

    let ibmPushProperties = IbmPushProps(url: url, adminUrl: adminUrl, secret: secret)
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
