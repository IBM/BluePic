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

public struct Configuration {

  public enum Error: ErrorProtocol {
    case IO(String)
  }

  let configurationFile = "config.json"
  let couchDBConnProps: ConnectionProperties
  let couchDBName: String

  init() throws {
    if let configData = NSData(contentsOfFile: "./\(configurationFile)") {
      let configJson = JSON(data:configData)
      if let ipAddress = configJson["couchDbIpAddress"].string,
         let port = configJson["couchDbPort"].number,
         let dbName = configJson["couchDbDbName"].string {
           couchDBConnProps = ConnectionProperties(hostName: ipAddress, port: Int16(port.integerValue), secured: false)
           couchDBName = dbName
           return
      }
    }
    throw Error.IO("Failed to read/parse the contents of the '\(configurationFile)' configuration file.")
  }
}
