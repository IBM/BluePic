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

protocol ServerProtocol {
    
  var router: Router { get }

  func ping(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws
  func token(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws
  func getPopularTags(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws
  func getUsers(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws
  func getUser(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws
  func createUser(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws
  func getImages(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws
  func getImage(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws
  func getImagesForUser(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws
  func postImage(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws
  func sendPushNotification(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws
    
}
