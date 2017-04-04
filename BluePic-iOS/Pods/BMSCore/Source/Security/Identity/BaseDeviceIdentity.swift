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



// MARK: - Swift 3

#if swift(>=3.0)

    

// This class represents the base device identity class, with default methods and keys
open class BaseDeviceIdentity: DeviceIdentity {
    
    
    public struct Key {
        
        public static let ID = "id"
        public static let OS = "platform"
        public static let OSVersion = "osVersion"
        public static let model = "model"
    }
    
    
    public internal(set) var jsonData: [String:String] = ([:])
    public private(set) var extendedJsonData : [String:Any] = [String:Any]()
	
	public var ID: String? {
		get {
            return jsonData[BaseDeviceIdentity.Key.ID] != nil ? jsonData[BaseDeviceIdentity.Key.ID] : (extendedJsonData[BaseDeviceIdentity.Key.ID] as? String)
		}
	}
	
	public var OS: String? {
		get {
			return jsonData[BaseDeviceIdentity.Key.OS] != nil ? jsonData[BaseDeviceIdentity.Key.OS] : (extendedJsonData[BaseDeviceIdentity.Key.OS] as? String)
		}
	}

	
	public var OSVersion: String? {
		get {
			return jsonData[BaseDeviceIdentity.Key.OSVersion] != nil ? jsonData[BaseDeviceIdentity.Key.OSVersion] : (extendedJsonData[BaseDeviceIdentity.Key.OSVersion] as? String)
		}
	}

	
	public var model: String? {
		get {
			return jsonData[BaseDeviceIdentity.Key.model] != nil ? jsonData[BaseDeviceIdentity.Key.model] : (extendedJsonData[BaseDeviceIdentity.Key.model] as? String)
		}
	}

	
    public init() {
        
        #if os(watchOS)
            jsonData[BaseDeviceIdentity.Key.ID] = "Not Available"
            jsonData[BaseDeviceIdentity.Key.OS] =  WKInterfaceDevice.current().systemName
            jsonData[BaseDeviceIdentity.Key.OSVersion] = WKInterfaceDevice.current().systemVersion
            jsonData[BaseDeviceIdentity.Key.model] =  WKInterfaceDevice.current().model
        #else
            jsonData[BaseDeviceIdentity.Key.ID] = UIDevice.current.identifierForVendor?.uuidString
            jsonData[BaseDeviceIdentity.Key.OS] =  UIDevice.current.systemName
            jsonData[BaseDeviceIdentity.Key.OSVersion] = UIDevice.current.systemVersion
            jsonData[BaseDeviceIdentity.Key.model] =  UIDevice.current.model
        #endif
	}
    public convenience init(map: [String:AnyObject]?) {
        self.init(map : map as [String:Any]?)
    }
    
    public init(map: [String:Any]?) {
        extendedJsonData = map != nil ? map! : [String:Any]()
        guard let json = map as? [String:String] else {
            jsonData = ([:])
            return
        }
        
        jsonData = json
    }

}
    
    
    
    
    
/**************************************************************************************************/
    
    
    
    
    
// MARK: - Swift 2
    
#else
    
    
    
// This class represents the base device identity class, with default methods and keys
public class BaseDeviceIdentity: DeviceIdentity {
    
    
    public struct Key {
        
        public static let ID = "id"
        public static let OS = "platform"
        public static let OSVersion = "osVersion"
        public static let model = "model"
    }
    
    
    public internal(set) var jsonData: [String:String] = ([:])
    
    public var ID: String? {
        get {
            return jsonData[BaseDeviceIdentity.Key.ID]
        }
    }
    
    public var OS: String? {
        get {
            return jsonData[BaseDeviceIdentity.Key.OS]
        }
    }
    
    
    public var OSVersion: String? {
        get {
            return jsonData[BaseDeviceIdentity.Key.OSVersion]
        }
    }
    
    
    public var model: String? {
        get {
            return jsonData[BaseDeviceIdentity.Key.model]
        }
    }
    
    
    public init() {
    
        #if os(watchOS)
            jsonData[BaseDeviceIdentity.Key.ID] = "Not Available"
            jsonData[BaseDeviceIdentity.Key.OS] =  WKInterfaceDevice.currentDevice().systemName
            jsonData[BaseDeviceIdentity.Key.OSVersion] = WKInterfaceDevice.currentDevice().systemVersion
            jsonData[BaseDeviceIdentity.Key.model] =  WKInterfaceDevice.currentDevice().model
        #else
            jsonData[BaseDeviceIdentity.Key.ID] = UIDevice.currentDevice().identifierForVendor?.UUIDString
            jsonData[BaseDeviceIdentity.Key.OS] =  UIDevice.currentDevice().systemName
            jsonData[BaseDeviceIdentity.Key.OSVersion] = UIDevice.currentDevice().systemVersion
            jsonData[BaseDeviceIdentity.Key.model] =  UIDevice.currentDevice().model
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


    
#endif
