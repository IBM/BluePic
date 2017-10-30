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
import KituraContracts

protocol ServerProtocol {
  
  var router: Router { get }
  var port: Int { get }
  
  func ping(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws
  func getImagesForUser(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws
  
  func getTags(respondWith: @escaping ([PopularTag]?, RequestError?) -> Void)
  func getImage(id: String, respondWith: @escaping (Image?, RequestError?) -> Void)
  func getImages(respondWith: @escaping ([Image]?, RequestError?) -> Void)
  func postImage(image: Image, respondWith: @escaping (Image?, RequestError?) -> Void)
  func postUser(user: User, respondWith: @escaping (User?, RequestError?) -> Void)
  func getUsers(respondWith: @escaping ([User]?, RequestError?) -> Void)
  func getUser(id: String, respondWith: @escaping (User?, RequestError?) -> Void)
  func sendPushNotification(imageId: String, respondWith: @escaping (NotificationStatus?, RequestError?) -> Void)
}
