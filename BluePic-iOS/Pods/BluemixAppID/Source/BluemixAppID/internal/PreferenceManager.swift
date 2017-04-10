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


import BMSCore


internal class PreferenceManager {

    private(set) final var sharedPreferences:UserDefaults = UserDefaults.standard
    private static let logger =  Logger.logger(name: Logger.bmsLoggerPrefix + "PreferenceManager")

    public func getStringPreference(name:String) -> StringPreference {
        return StringPreference(name: name, sharedPreferences: sharedPreferences)
    }
    
    public func getJSONPreference(name:String) -> JSONPreference {
        return JSONPreference(name: name, sharedPreferences: sharedPreferences)
    }

    
    
 }


