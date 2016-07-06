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
    private let kBluemixKeysPlistName = "bluemix"
    private let kIsLocalKey = "isLocal"
    private let kAppRouteLocal = "appRouteLocal"
    private let kAppRouteRemote = "appRouteRemote"
    private let kBluemixAppGUIDKey = "bluemixAppGUID"
    private let kBluemixAppRegionKey = "bluemixAppRegion"

    let localBaseRequestURL: String
    let remoteBaseRequestURL: String
    let appGUID: String
    let appRegion: String
    var isLocal: Bool = true

    override init() {

        if var localBaseRequestURL = Utils.getStringValueWithKeyFromPlist(kBluemixKeysPlistName, key: kAppRouteLocal),
                remoteBaseRequestURL = Utils.getStringValueWithKeyFromPlist(kBluemixKeysPlistName, key: kAppRouteRemote),
                let appGUID = Utils.getStringValueWithKeyFromPlist(kBluemixKeysPlistName, key: kBluemixAppGUIDKey),
                appRegion = Utils.getStringValueWithKeyFromPlist(kBluemixKeysPlistName, key: kBluemixAppRegionKey),
                isLocal = Utils.getBoolValueWithKeyFromPlist(kBluemixKeysPlistName, key: kIsLocalKey) {
            self.appGUID = appGUID
            self.appRegion = appRegion
            self.isLocal = isLocal
            if let lastChar = localBaseRequestURL.characters.last where lastChar == "/" as Character {
                localBaseRequestURL.removeAtIndex(localBaseRequestURL.endIndex.predecessor())
            }
            if let lastChar = remoteBaseRequestURL.characters.last where lastChar == "/" as Character {
                remoteBaseRequestURL.removeAtIndex(remoteBaseRequestURL.endIndex.predecessor())
            }
            self.localBaseRequestURL = localBaseRequestURL
            self.remoteBaseRequestURL = remoteBaseRequestURL

            super.init()
        } else {
            fatalError("Could not load bluemix plist into object properties")
        }
    }

}
