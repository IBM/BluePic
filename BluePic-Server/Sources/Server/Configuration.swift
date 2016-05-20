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
import CFEnvironment
import BluemixObjectStorage

public struct Configuration {

  public enum Error: ErrorProtocol {
    case IO(String)
  }

  // Instance constants
  let configurationFile = "config.json"
  let appEnv: AppEnv

  init() throws {
    // Generate file path for config.json
    let filePath = #file
    let components = filePath.characters.split(separator: "/").map(String.init)
    let notLastThree = components[0..<components.count - 3]
    let finalPath = "/" + notLastThree.joined(separator: "/") + "/\(configurationFile)"

    if let configData = NSData(contentsOfFile: finalPath) {
      let configJson = JSON(data: configData)
      appEnv = try CFEnvironment.getAppEnv(options: configJson)
      Log.info("Using configuration values from '\(configurationFile)'.")
    } else {
      Log.warning("Could not find '\(configurationFile)'.")
      appEnv = try CFEnvironment.getAppEnv()
    }
  }

  func getCouchDBConnProps() throws -> ConnectionProperties {
    if let couchDBCredentials = appEnv.getService(spec: "Cloudant NoSQL DB-fz")?.credentials {
      if let host = couchDBCredentials["host"].string,
      user = couchDBCredentials["username"].string,
      password = couchDBCredentials["password"].string,
      port = couchDBCredentials["port"].int {
        let connProperties = ConnectionProperties(host: host, port: Int16(port), secured: true, username: user, password: password)
        return connProperties
      }
    }
    throw Error.IO("Failed to obtain database service and/or its credentials.")
  }

  func getObjectStorageConnProps() throws -> ObjectStorageConnProps {
    guard let objStoreCredentials = appEnv.getService(spec: "Object Storage-bv")?.credentials else {
      throw Error.IO("Failed to obtain object storage service and/or its credentials.")
    }

    guard let projectId = objStoreCredentials["projectId"].string,
    userId = objStoreCredentials["userId"].string,
    password = objStoreCredentials["password"].string else {
      throw Error.IO("Failed to obtain object storage credentials.")
    }

    let connProperties = ObjectStorageConnProps(projectId: projectId, userId: userId, password: password)
    return connProperties
  }

    func getMobileClientAccessProps() throws -> MobileClientAccessProps {
        guard let mcaCredentials = appEnv.getService(spec: "Mobile Client Access-ag")?.credentials else {
            throw Error.IO("Failed to obtain MCA service and/or its credentials.")
        }

        guard let secret = mcaCredentials["secret"].string,
        serverUrl = mcaCredentials["serverUrl"].string,
        clientId = mcaCredentials["clientId"].string else {
                throw Error.IO("Failed to obtain MCA credentials.")
        }

        let mcaProperties = MobileClientAccessProps(secret: secret, serverUrl: serverUrl, clientId: clientId)
        return mcaProperties
    }

    func getIbmPushProps() throws -> IbmPushProps {
        guard let pushCredentials = appEnv.getService(spec: "IBM Push Notifications-12")?.credentials else {
            throw Error.IO("Failed to obtain IBM Push service and/or its credentials.")
        }

        guard let url = pushCredentials["url"].string,
            adminUrl = pushCredentials["admin_url"].string,
            secret = pushCredentials["appSecret"].string else {
                throw Error.IO("Failed to obtain IBM Push credentials.")
        }

        let ibmPushProperties = IbmPushProps(url: url, adminUrl: adminUrl, secret: secret)
        return ibmPushProperties
    }
}
