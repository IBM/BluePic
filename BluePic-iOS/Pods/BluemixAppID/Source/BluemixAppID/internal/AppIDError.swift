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

internal enum AppIDError: Error {
    case authenticationError(msg: String?)
    case registrationError(msg: String?)
    case tokenRequestError(msg: String?)
    case jsonUtilsError(msg: String?)
    case generalError
    
    
    var description: String {
        switch self {
        case .authenticationError(let msg), .jsonUtilsError(let msg), .registrationError(let msg), .tokenRequestError(let msg) :
            return msg ?? "error"
        case .generalError :
            return "General Error"
        }
    }

    
}
