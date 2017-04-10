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



// MARK: - Swift 3

#if swift(>=3.0)

    

// This class represents the base app identity class, with default methods and keys
open class BaseAppIdentity: AppIdentity {
    
    
    public struct Key {
        
        public static let ID = "id"
        public static let version = "version"
    }
    
    
    public internal(set) var jsonData: [String:String] = ([:])
    public private(set) var extendedJsonData : [String:Any] = [String:Any]()
    
    public var ID: String? {
        get {
            return jsonData[BaseAppIdentity.Key.ID] != nil ? jsonData[BaseAppIdentity.Key.ID] : (extendedJsonData[BaseAppIdentity.Key.ID] as? String)
        }
    }
    public var version: String? {
        get {
            return jsonData[BaseAppIdentity.Key.version] != nil ? jsonData[BaseAppIdentity.Key.version] : (extendedJsonData[BaseAppIdentity.Key.version] as? String)
        }
    }
    
    public init() {
        
        jsonData[BaseAppIdentity.Key.ID] = Bundle.main.bundleIdentifier
        jsonData[BaseAppIdentity.Key.version] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
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
    
    
    
// This class represents the base app identity class, with default methods and keys
public class BaseAppIdentity: AppIdentity {

    
    public struct Key {
        
        public static let ID = "id"
        public static let version = "version"
    }
    
    
    public internal(set) var jsonData: [String:String] = ([:])
    
	public var ID: String? {
		get {
			return jsonData[BaseAppIdentity.Key.ID]
		}
	}
	public var version: String? {
		get {
			return jsonData[BaseAppIdentity.Key.version]
		}
	}
	
	public init() {
        
        jsonData[BaseAppIdentity.Key.ID] = NSBundle.mainBundle().bundleIdentifier
        jsonData[BaseAppIdentity.Key.version] = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String
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
