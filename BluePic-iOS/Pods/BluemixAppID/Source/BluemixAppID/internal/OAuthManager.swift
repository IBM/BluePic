/* *     Copyright 2016, 2017 IBM Corp.
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 */


import Foundation


public class OAuthManager {
    private(set) var appId:AppID
    private(set) var preferenceManager:PreferenceManager
    internal var registrationManager:RegistrationManager?
    internal var authorizationManager:AuthorizationManager?
    internal var tokenManager:TokenManager?

    init(appId:AppID) {
        self.appId = appId
        self.preferenceManager = PreferenceManager()
        self.registrationManager = RegistrationManager(oauthManager: self)
        self.authorizationManager = AuthorizationManager(oAuthManager: self)
        self.tokenManager = TokenManager(oAuthManager: self)
    }
}
