/*
*     Copyright 2015 IBM Corp.
*     Licensed under the Apache License, Version 2.0 (the "License");
*     you may not use this file except in compliance with the License.
*     You may obtain a copy of the License at
*     http://www.apache.org/licenses/LICENSE-2.0
*     Unless required by applicable law or agreed to in writing, software
*     distributed under the License is distributed on an "AS IS" BASIS,
*     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*     See the License for the specific language governing permissions and
*     limitations under the License.
*/

import Foundation
import BMSCore

/// This class represents the base device identity class, with default methods and keys

public class MCADeviceIdentity : BaseDeviceIdentity {
    
    public override init() {
        var dict:[String : String] = [:]
        #if os(watchOS)
            dict = [
                BaseDeviceIdentity.ID : "Not Available",
                BaseDeviceIdentity.OS :  WKInterfaceDevice.currentDevice().systemName,
                BaseDeviceIdentity.OS_VERSION : WKInterfaceDevice.currentDevice().systemVersion,
                BaseDeviceIdentity.MODEL :  WKInterfaceDevice.currentDevice().model
            ]
        #else
            dict = [
                BaseDeviceIdentity.ID : (UIDevice.currentDevice().identifierForVendor?.UUIDString)!,
                BaseDeviceIdentity.OS :  UIDevice.currentDevice().systemName,
                BaseDeviceIdentity.OS_VERSION : UIDevice.currentDevice().systemVersion,
                BaseDeviceIdentity.MODEL :  UIDevice.currentDevice().model
            ]
        #endif
        super.init(map: dict)
    }
    
    public override init(map: [String : AnyObject]?) {
        super.init(map: map)
    }
}