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

/// This class represents the base user identity class, with default methods and keys
public class BaseUserIdentity : UserIdentity {
    public static let ID = "id"
    public static let AUTH_BY = "authBy"
    public static let DISPLAY_NAME = "displayName"
	
    public private(set) var jsonData : [String:String] = ([:])
    
	public var id:String? {
		get {
			return jsonData[BaseUserIdentity.ID]
		}
	}
	
	public var authBy:String? {
		get {
			return jsonData[BaseUserIdentity.AUTH_BY]
		}
	}
	
	public var displayName:String? {
		get {
			return jsonData[BaseUserIdentity.DISPLAY_NAME]
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