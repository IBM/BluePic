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

import UIKit

class BluemixConfiguration: NSObject {

    //Plist Keys
    fileprivate let kBluemixKeysPlistName = "bluemix"
    fileprivate let kIsLocalKey = "isLocal"
    fileprivate let kAppRouteLocal = "appRouteLocal"
    fileprivate let kAppRouteRemote = "appRouteRemote"
    fileprivate let kBluemixAppGUIDKey = "bluemixAppGUID"
    fileprivate let kBluemixAppRegionKey = "bluemixAppRegion"
    fileprivate let kBluemixPushAppGUIDKey = "pushAppGUID"
    fileprivate let kBluemixMCATenantIdKey = "mcaTenantId"

    let localBaseRequestURL: String
    let remoteBaseRequestURL: String
    let appGUID: String
    let appRegion: String
    var pushAppGUID: String = ""
    var mcaTenantId: String = ""
    var isLocal: Bool = true

    override init() {

        if var localBaseRequestURL = Utils.getStringValueWithKeyFromPlist(kBluemixKeysPlistName, key: kAppRouteLocal),
                var remoteBaseRequestURL = Utils.getStringValueWithKeyFromPlist(kBluemixKeysPlistName, key: kAppRouteRemote),
                let appGUID = Utils.getStringValueWithKeyFromPlist(kBluemixKeysPlistName, key: kBluemixAppGUIDKey),
                let appRegion = Utils.getStringValueWithKeyFromPlist(kBluemixKeysPlistName, key: kBluemixAppRegionKey),
                let isLocal = Utils.getBoolValueWithKeyFromPlist(kBluemixKeysPlistName, key: kIsLocalKey) {
            self.appGUID = appGUID
            self.appRegion = appRegion
            self.isLocal = isLocal
            if let lastChar = localBaseRequestURL.characters.last, lastChar == "/" as Character {
                localBaseRequestURL.remove(at: localBaseRequestURL.characters.index(before: localBaseRequestURL.endIndex))
            }
            if let lastChar = remoteBaseRequestURL.characters.last, lastChar == "/" as Character {
                remoteBaseRequestURL.remove(at: remoteBaseRequestURL.characters.index(before: remoteBaseRequestURL.endIndex))
            }
            self.localBaseRequestURL = localBaseRequestURL
            self.remoteBaseRequestURL = remoteBaseRequestURL

            // if present, add push app GUID
            if let pushAppGUID = Utils.getStringValueWithKeyFromPlist(kBluemixKeysPlistName, key: kBluemixPushAppGUIDKey) {
                self.pushAppGUID = pushAppGUID
            }

            if let mcaTenantId = Utils.getStringValueWithKeyFromPlist(kBluemixKeysPlistName, key: kBluemixMCATenantIdKey) {
                self.mcaTenantId = mcaTenantId
            }

            super.init()
        } else {
            fatalError("Could not load bluemix plist into object properties")
        }
    }

}
