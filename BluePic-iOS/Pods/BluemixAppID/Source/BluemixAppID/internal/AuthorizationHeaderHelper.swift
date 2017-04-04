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

public class AuthorizationHeaderHelper {

    
    public static func isAuthorizationRequired(for httpResponse: Response) -> Bool {
        
        let header = httpResponse.headers?.filter({($0.key as? String)?.lowercased() == AppIDConstants.WWW_AUTHENTICATE_HEADER.lowercased() }).first?.1 as? String
        return AuthorizationHeaderHelper.isAuthorizationRequired(statusCode: httpResponse.statusCode, header: header)
    }
    
    
    public static func isAuthorizationRequired(statusCode: Int?, header: String?) -> Bool {
        
        guard let code = statusCode, let unwrappedHeader = header else {
            return false
        }
        
        if code == 401 || code == 403 {
            if unwrappedHeader.lowercased().hasPrefix(AppIDConstants.BEARER.lowercased()) && unwrappedHeader.lowercased().contains(AppIDConstants.AUTH_REALM.lowercased()) {
                return true
            }
        }
        return false
    }
    
}
