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
import BMSCore

internal class Config {

    private static var serverUrlPrefix = "https://appid-oauth"
    private static var attributesUrlPrefix = "https://appid-profiles"

    internal static let logger =  Logger.logger(name: AppIDConstants.ConfigLoggerName)

    internal static func getServerUrl(appId:AppID) -> String {

        guard let region = appId.bluemixRegion, let tenant = appId.tenantId else {
            logger.error(message: "Could not set server url properly, no tenantId or no region set")
            return serverUrlPrefix
        }

        var serverUrl = Config.serverUrlPrefix + region + "/oauth/v3/"
        if let overrideServerHost = AppID.overrideServerHost {
            serverUrl = overrideServerHost
        }
        
        serverUrl = serverUrl + tenant
        return serverUrl
    }
    
    internal static func getAttributesUrl(appId:AppID) -> String {
        
        guard let region = appId.bluemixRegion else {
            logger.error(message: "Could not set server url properly, no region set")
            return serverUrlPrefix
        }
        
        var attributesUrl = Config.attributesUrlPrefix + region + "/api/v1/"
        if let overrideHost = AppID.overrideAttributesHost {
            attributesUrl = overrideHost
        }
        
        return attributesUrl
    }
    
}
