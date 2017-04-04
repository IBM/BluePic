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
 * Holds single string preference value
 */
internal class StringPreference {
    private(set) final var sharedPreferences:UserDefaults
    private final var name:String

    // TODO: should these be syncronized?
    
    init(name:String, sharedPreferences: UserDefaults) {
     self.name = name
        self.sharedPreferences = sharedPreferences
    }
    
    public func get() -> String? {
        return self.sharedPreferences.value(forKey: name) as? String
    }
    
    
    public func set(_ value:String?) {
        self.sharedPreferences.setValue(value, forKey: name)
        self.sharedPreferences.synchronize()
    }
    
    public func clear() {
        self.set(nil)
    }
    
}
