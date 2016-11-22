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

#if swift (>=3.0)
public class MCADeviceIdentity : BaseDeviceIdentity {
    
    public override init() {
        var dict:[String : String] = [:]
        
        #if os(watchOS)
            dict = [
                BaseDeviceIdentity.Key.ID : "Not Available",
                BaseDeviceIdentity.Key.OS :  WKInterfaceDevice.currentDevice().systemName,
                BaseDeviceIdentity.Key.OSVersion : WKInterfaceDevice.currentDevice().systemVersion,
                BaseDeviceIdentity.Key.model :  WKInterfaceDevice.currentDevice().model
            ]
        #else
            dict = [
                BaseDeviceIdentity.Key.ID : (UIDevice.current.identifierForVendor?.uuidString)!,
                BaseDeviceIdentity.Key.OS :  UIDevice.current.systemName,
                BaseDeviceIdentity.Key.OSVersion : UIDevice.current.systemVersion,
                BaseDeviceIdentity.Key.model :  UIDevice.current.model
            ]
        #endif
        super.init(map: dict as [String : Any]?)
    }
    
    public convenience init(map: [String:AnyObject]?) {
        self.init(map: map as [String:Any]?)
    }
    
    public override init(map: [String : Any]?) {
        super.init(map: map)
    }
}
#else
    public class MCADeviceIdentity : BaseDeviceIdentity {
        
        public override init() {
            var dict:[String : String] = [:]
            #if os(watchOS)
                dict = [
                    BaseDeviceIdentity.Key.ID  : "Not Available",
                    BaseDeviceIdentity.Key.OS :  WKInterfaceDevice.currentDevice().systemName,
                    BaseDeviceIdentity.Key.OSVersion : WKInterfaceDevice.currentDevice().systemVersion,
                    BaseDeviceIdentity.Key.model :  WKInterfaceDevice.currentDevice().model
                ]
            #else
                dict = [
                    BaseDeviceIdentity.Key.ID : (UIDevice.currentDevice().identifierForVendor?.UUIDString)!,
                    BaseDeviceIdentity.Key.OS :  UIDevice.currentDevice().systemName,
                    BaseDeviceIdentity.Key.OSVersion : UIDevice.currentDevice().systemVersion,
                    BaseDeviceIdentity.Key.model :  UIDevice.currentDevice().model
                ]
            #endif
            super.init(map: dict)
        }
        
        public override init(map: [String : AnyObject]?) {
            super.init(map: map)
        }
    }
#endif
