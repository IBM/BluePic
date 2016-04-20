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


import WatchKit


/// This class represents the base device identity class, with default methods and keys
public class BaseDeviceIdentity : DeviceIdentity {
    
    public static let ID = "id"
    public static let OS = "platform"
	public static let OS_VERSION = "osVersion";
    public static let MODEL = "model"
    
    public internal(set) var jsonData : [String:String] = ([:])
	
	public var id:String? {
		get{
			return jsonData[BaseDeviceIdentity.ID]
		}
	}
	
	public var OS:String? {
		get{
			return jsonData[BaseDeviceIdentity.OS]
		}
	}

	
	public var OSVersion:String? {
		get{
			return jsonData[BaseDeviceIdentity.OS_VERSION]
		}
	}

	
	public var model:String? {
		get{
			return jsonData[BaseDeviceIdentity.MODEL]
		}
	}

	
    public init() {
		#if os(watchOS)
			jsonData[BaseDeviceIdentity.ID] = "Not Available"
			jsonData[BaseDeviceIdentity.OS] =  WKInterfaceDevice.currentDevice().systemName
			jsonData[BaseDeviceIdentity.OS_VERSION] = WKInterfaceDevice.currentDevice().systemVersion
			jsonData[BaseDeviceIdentity.MODEL] =  WKInterfaceDevice.currentDevice().model
		#else
			jsonData[BaseDeviceIdentity.ID] = UIDevice.currentDevice().identifierForVendor?.UUIDString
			jsonData[BaseDeviceIdentity.OS] =  UIDevice.currentDevice().systemName
			jsonData[BaseDeviceIdentity.OS_VERSION] = UIDevice.currentDevice().systemVersion
			jsonData[BaseDeviceIdentity.MODEL] =  UIDevice.currentDevice().model
		#endif
		
	}
    
    public init(map: [String:AnyObject]?) {
        guard let json = map as? [String:String] else {
            jsonData = ([:])
            return
        }
        
        jsonData = json
    }

}