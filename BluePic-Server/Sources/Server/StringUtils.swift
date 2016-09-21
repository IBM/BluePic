/**
* Copyright IBM Corporation 2016
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
* See the License for the specific language governing permissions and
* limitations under the License.
**/

import Foundation
import LoggerAPI

public struct StringUtils {

  /**
   Strips out any Url encoded whitespace and replaces it with a human readable space
   
   - parameter str: String to parse
   
   - returns: decoded string without whitespace encodings
   */
  static func decodeWhiteSpace(inString str: String) -> String {
    let decodedStr = str.replacingOccurrences(of: "%20", with: " ")
    Log.verbose("Decoded (whitespace) in string: '\(str)' to '\(decodedStr)'.")
    return decodedStr
  }

  /**
   Generates timestamp in specific format
   
   - returns: timestamp in String form
   */
  static func currentTimestamp() -> String {
    let dateStr = Date().description
    let ts = dateStr.substring(r: Range(0..<10)) + "T" + dateStr.substring(r: Range(11..<18))
    Log.verbose("Current time string: \(dateStr)")
    Log.verbose("Current timestamp generated: \(ts)")
    return ts
  }
}

public extension String {
    
    func substring(r: Range<Int>) -> String {
        let fromIndex = self.index(self.startIndex, offsetBy: r.lowerBound)
        let toIndex = self.index(self.startIndex, offsetBy: r.upperBound)
        return self.substring(with: Range<String.Index>(uncheckedBounds: (lower: fromIndex, upper: toIndex)))
    }
    
}
