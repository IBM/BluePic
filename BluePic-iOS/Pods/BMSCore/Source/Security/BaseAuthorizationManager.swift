/*
*     Copyright 2016 IBM Corp.
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



internal class BaseAuthorizationManager : AuthorizationManager {
    
    
    internal init() {
        
    }
	
	var cachedAuthorizationHeader:String? {
		get{
			return nil
		}
	}
	
	var userIdentity:UserIdentity? {
		get{
			return nil
		}
	}
	
	var deviceIdentity:DeviceIdentity {
		get{
			return BaseDeviceIdentity()
		}
	}
	
	var appIdentity:AppIdentity {
		get{
			return BaseAppIdentity()
		}
	}
	
	func isAuthorizationRequired(for statusCode: Int, httpResponseAuthorizationHeader: String) -> Bool{
        return false
    }
    
    func isAuthorizationRequired(for httpResponse: Response) -> Bool {
        return false
    }
    
    func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
		callback?(nil, nil)
    }
    
    func clearAuthorizationData() {
        
    }
    
    func addCachedAuthorizationHeader(request: NSMutableURLRequest) {
        
    }
	
}
