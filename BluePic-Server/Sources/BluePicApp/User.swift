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

struct User {
  var id: String
  let name: String
  var rev: String?

  init(id: String, name: String, rev: String? = nil) {
    self.id = id
    self.name = name
    self.rev = nil
  }
}

extension User: Codable {

  enum CodingKeys: String, CodingKey {
    case id = "_id"
    case rev = "_rev"
    case name
    case type
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(name, forKey: .name)
    try container.encodeIfPresent(rev, forKey: .rev)
    try container.encode("user", forKey: .type)
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)

    id = try values.decode(String.self, forKey: .id)
    name = try values.decode(String.self, forKey: .name)
    rev = try values.decodeIfPresent(String.self, forKey: .rev)
  }
}

extension User: JSONConvertible {
  static func convert(document: JSON, decoder: JSONDecoder) throws -> [User] {
    return try document.toData().map { try decoder.decode(User.self, from: $0) }
  }
}
