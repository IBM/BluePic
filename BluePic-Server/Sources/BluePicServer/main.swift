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
import Kitura
import LoggerAPI
import HeliumLogger
import BluePicApp
// import CloudFoundryDeploymentTracker

// Disable all buffering on stdout
setbuf(stdout, nil)

// Logger
Log.logger = HeliumLogger()


do {
  // CloudFoundryDeploymentTracker(repositoryURL: "https://github.com/IBM-Swift/BluePic.git", codeVersion: nil).track()
  let serverController = try ServerController()
  // Start server...
  Kitura.addHTTPServer(onPort: 8090, with: serverController.router)
  Kitura.run()

} catch Configuration.BluePicError.IO{
  Log.error("Oops, something went wrong... Server did not start!")
  exit(1)
}
