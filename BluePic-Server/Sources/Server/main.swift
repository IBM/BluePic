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
import KituraSys
import CouchDB
import LoggerAPI
import HeliumLogger
import SwiftyJSON
import CFEnvironment

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

// Logger
Log.logger = HeliumLogger()

// Define "global" variables for module
let router: Router = Router()
let objStorageConnProps: ObjectStorageConnProps
let couchDBConnProps: ConnectionProperties
let mobileClientAccessProps: MobileClientAccessProps
let ibmPushProps: IbmPushProps

do {
  // Create Configuration object
  let config = try Configuration()
  couchDBConnProps = try config.getCouchDBConnProps()
  objStorageConnProps = try config.getObjectStorageConnProps()
  mobileClientAccessProps = try config.getMobileClientAccessProps()
  ibmPushProps = try config.getIbmPushProps()

  // Define routes
  defineRoutes()

  // Start server...
  HttpServer.listen(port: config.appEnv.port, delegate: router)
  Server.run()
} catch Configuration.Error.IO {
  Log.error("Oops, something went wrong... Server did not start!")
  exit(1)
}
