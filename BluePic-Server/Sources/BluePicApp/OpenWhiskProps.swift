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

public struct OpenWhiskProps {
  // Public instance variables
  public let hostName: String
  public let urlPath: String
  public let authToken: String

  // Constructor
  public init(hostName: String, urlPath: String, authToken: String) {
    self.hostName = hostName
    self.urlPath = urlPath
    self.authToken = authToken
  }
    
  public init?(dict: [String: Any]) {
    guard let openWhiskJson = dict as? [String: String] else {
      return nil
    }

    guard let hostName = openWhiskJson["hostName"],
          let urlPath = openWhiskJson["urlPath"],
          let authToken = openWhiskJson["authToken"],
          let computedAuthToken = authToken.data(using: String.Encoding.utf8)?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) else {
            
            return nil
    }
    
    self.hostName = hostName
    self.urlPath = urlPath
    self.authToken = computedAuthToken
  }
}
