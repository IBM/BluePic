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
import CloudEnvironment
import CouchDB

public struct Configuration {

  /**
   Enum used for Configuration errors
   - IO: case to indicate input/output error
   */
  public enum BluePicError: Error {
    case IO(String)
  }
    
  // Instance constants
  let cloudEnv = CloudEnv(cloudFoundryFile: "config/config.json")
    
  public var port: Int {
    return cloudEnv.port
  }

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

    return ObjectStorageConnProps(projectId: objStoreCredentials.projectID,
                                  userId: objStoreCredentials.userID,
                                  password: objStoreCredentials.password)
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

    return AppIdProps(secret: appIdCredentials.secret,
                     serverUrl: appIdCredentials.oauthServerUrl,
                     clientId: appIdCredentials.clientId,
                     tenantId: appIdCredentials.tenantId)
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

    return IbmPushProps(appGuid: pushCredentials.appGuid, secret: pushCredentials.appSecret)
  }
  
  /**
   Method to get OpenWhisk properties in a consumable form
     
   - throws: error when method can't get credentials
     
   - returns: Encapsulated OpenWhiskProps object with the necessary info
  */
  func getOpenWhiskProps() throws -> OpenWhiskProps {
    guard let openWhiskJson = cloudEnv.getDictionary(name: "open-whisk-credentials") as? [String: String],
          let hostName = openWhiskJson["hostName"],
          let urlPath = openWhiskJson["urlPath"],
          let authToken = openWhiskJson["authToken"],
          let utf8BaseStr = authToken.data(using: String.Encoding.utf8) else {

        throw BluePicError.IO("Failed to obtain IBM Open Whisk credentials.")
    }
    
    let computedAuthToken = utf8BaseStr.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))

    return OpenWhiskProps(hostName: hostName, urlPath: urlPath, authToken: computedAuthToken)
  }
}
