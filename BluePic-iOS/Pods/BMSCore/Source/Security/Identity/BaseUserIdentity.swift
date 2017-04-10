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


    
// This class represents the base user identity class, with default methods and keys
open class BaseUserIdentity: UserIdentity {
    
    
    public struct Key {
        
        public static let ID = "id"
        public static let authorizedBy = "authBy"
        public static let displayName = "displayName"
    }
    
    
    public private(set) var jsonData : [String:String] = ([:])
    public private(set) var extendedJsonData : [String:Any] = [String:Any]()
    
    public var ID: String? {
        get {
            return jsonData[BaseUserIdentity.Key.ID] != nil ? jsonData[BaseUserIdentity.Key.ID] : (extendedJsonData[BaseUserIdentity.Key.ID] as? String)
        }
    }
    
    public var authorizedBy: String? {
        get {
            return jsonData[BaseUserIdentity.Key.authorizedBy] != nil ? jsonData[BaseUserIdentity.Key.authorizedBy] : (extendedJsonData[BaseUserIdentity.Key.authorizedBy] as? String)
        }
    }
    
    public var displayName: String? {
        get {
            return jsonData[BaseUserIdentity.Key.displayName] != nil ? jsonData[BaseUserIdentity.Key.displayName] : (extendedJsonData[BaseUserIdentity.Key.displayName] as? String)
        }
    }
    
    public init() {
        
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



// This class represents the base user identity class, with default methods and keys
public class BaseUserIdentity: UserIdentity {
    
    
    public struct Key {
        
        public static let ID = "id"
        public static let authorizedBy = "authBy"
        public static let displayName = "displayName"
    }
    
    
    public private(set) var jsonData : [String:String] = ([:])
    
    public var ID: String? {
        get {
            return jsonData[BaseUserIdentity.Key.ID]
        }
    }
    
    public var authorizedBy: String? {
        get {
            return jsonData[BaseUserIdentity.Key.authorizedBy]
        }
    }
    
    public var displayName: String? {
        get {
            return jsonData[BaseUserIdentity.Key.displayName]
        }
    }
    
    public init() {
        
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
