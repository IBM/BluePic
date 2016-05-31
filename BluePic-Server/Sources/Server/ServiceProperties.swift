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

public struct ObjectStorageConnProps {
  // Instace variables
  public let accessPoint = "dal.objectstorage.open.softlayer.com"
  public let projectId: String
  public let userId: String
  public let password: String
  public let publicURL: String

  // Constructor
  public init(projectId: String, userId: String, password: String) {
    self.projectId = projectId
    self.userId = userId
    self.password = password
    self.publicURL = "https://\(accessPoint)/v1/AUTH_\(projectId)"
  }
}

public struct MobileClientAccessProps {
  // Instace variables
  public let secret: String
  public let serverUrl: String
  public let clientId: String
  public let adminUrl: String

  // Constructor
  public init(secret: String, serverUrl: String, clientId: String) {
    self.secret = secret
    self.serverUrl = serverUrl
    self.clientId = clientId
    self.adminUrl = "https://mobile.ng.bluemix.net/imfmobileplatformdashboard/?appGuid=\(clientId)"
  }
}

public struct IbmPushProps {
  // Instace variables
  public let url: String
  public let adminUrl: String
  public let secret: String

  // Constructor
  public init(url: String, adminUrl: String, secret: String) {
    self.url = url
    self.adminUrl = adminUrl
    self.secret = secret
  }
}

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
}
