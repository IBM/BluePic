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
import SwiftyJSON

extension JSON {

  /**
     Converts a JSON response to a Data Array
  
     - returns: decoded Data Array
  */
  public func toData() throws -> [Data] {

    guard let rows = self["rows"].array else {
      throw BluePicLocalizedError.noJsonData("No JSON array for User request")
    }

    return try rows.map { row in try row["value"].rawData() }
  }
  
  /**
     Converts a JSON response to a Data Array of (data, data) pairs for responses with Docs
     
     - returns: decoded Data Array
  */
  public func toDataWithDocs() throws -> [(Data, Data)] {

    guard let doc = self["rows"].array else {
      throw BluePicLocalizedError.noJsonData("No JSON array for Image request")
    }

    return try doc.enumerated().reduce([]) { (acc, current) in
      guard current.offset % 2 == 1 else {
        return acc
      }

      guard let usrDict = doc[current.offset - 1].dictionaryObject?["doc"],
            let imgDict = current.element.dictionaryObject?["doc"] else {
        return acc
      }

      var acc = acc
      let user = try JSONSerialization.data(withJSONObject: usrDict as Any, options: .prettyPrinted)
      let image = try JSONSerialization.data(withJSONObject: imgDict as Any, options: .prettyPrinted)
      acc.append((user, image))

      return acc
    }
  }
}
