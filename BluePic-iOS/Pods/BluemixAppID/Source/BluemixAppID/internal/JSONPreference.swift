/* *     Copyright 2016, 2017 IBM Corp.
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 */


import Foundation

/**
 * Holds single JSON preference value
 */
internal class JSONPreference:StringPreference {
    
    // TODO: should these be syncronized?
    
    override init(name:String, sharedPreferences: UserDefaults) {
        super.init(name: name, sharedPreferences: sharedPreferences)
    }
    
    
    public func set(_ value:[String:Any]?) {
        try? super.set(Utils.JSONStringify(value as AnyObject))
    }
    
    public func getAsJSON() -> [String:Any]? {
        guard let stringValue = super.get() else {
            return nil
        }
        return try? Utils.parseJsonStringtoDictionary(stringValue)
        
    }

}
