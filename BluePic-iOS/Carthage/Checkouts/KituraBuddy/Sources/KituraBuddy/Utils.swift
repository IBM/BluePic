/*
 * Copyright IBM Corporation 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific langua›ge governing permissions and
 * limitations under the License.
 */

 import Foundation
 import SafetyContracts

extension Error {
    func httpErrorCode() -> Int? {
        // sample error string: Error HTTP Response: `Optional(404)`
        let errorStr = String(describing: self)
        let httpErrorCode = errorStr.trimmingCharacters(in: CharacterSet(charactersIn: "01234567890").inverted)
        return Int(httpErrorCode)
    }
}

extension RouteHandlerError {
    init?(_ error: Error) {
        if let httpErrorCode = error.httpErrorCode() {
            self.init(rawValue: httpErrorCode)
        } else {
            return nil
        }
    }
}
