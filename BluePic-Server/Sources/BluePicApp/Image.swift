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

struct Image {
    var id: String
    var rev: String?
    let fileName: String
    let caption: String
    let contentType: String
    var url: String?
    let width: Double
    let height: Double
    let tags: [Tag]
    let uploadedTs: String
    let userId: String
    let deviceId: String?
    let location: Location?
    var user: User?
    var image: Data?
}

extension Image: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(rev, forKey: .rev)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encode(fileName, forKey: .fileName)
        try container.encode(caption, forKey: .caption)
        try container.encode(contentType, forKey: .contentType)
        try container.encode(height, forKey: .height)
        try container.encode(width, forKey: .width)
        try container.encode(tags, forKey: .tags)
        try container.encode(uploadedTs, forKey: .uploadedTs)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(deviceId, forKey: .deviceId)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(user, forKey: .user)
        try container.encode("image", forKey: .type)
    }
}

extension Image: Decodable {

  enum CodingKeys: String, CodingKey {
    case id = "_id"
    case rev = "_rev"
    case fileName
    case caption
    case contentType
    case url
    case width
    case height
    case tags
    case uploadedTs
    case userId
    case deviceId
    case location
    case user
    case image
    case type
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)

    // Must Exist
    fileName = try values.decode(String.self, forKey: .fileName)
    caption = try values.decode(String.self, forKey: .caption)
    width = try values.decode(Double.self, forKey: .width)
    height = try values.decode(Double.self, forKey: .height)
    userId = try values.decode(String.self, forKey: .userId)

    // Server Created -- Optional coming from Client
    id = try values.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    rev = try values.decodeIfPresent(String.self, forKey: .rev)
    contentType = try values.decodeIfPresent(String.self, forKey: .contentType) ?? "image/png"
    url = try values.decodeIfPresent(String.self, forKey: .url)

    // Optional
    tags = try values.decodeIfPresent([Tag].self, forKey: .tags) ?? []
    uploadedTs = try values.decodeIfPresent(String.self, forKey: .uploadedTs) ?? StringUtils.currentTimestamp()
    deviceId = try values.decodeIfPresent(String.self, forKey: .deviceId)
    location = try values.decodeIfPresent(Location.self, forKey: .location)
    user = try values.decodeIfPresent(User.self, forKey: .user)
    image = try values.decodeIfPresent(Data.self, forKey: .image)
  }
}

extension Image: JSONConvertible {
  static func convert(document: JSON, hasDocs: Bool = true, decoder: JSONDecoder) throws -> [Image] {
    return try !hasDocs ? document.toData().map { try decoder.decode(Image.self, from: $0) }
                          :
                          document.toDataWithDocs().reduce([]) { acc, current in
                            var acc = acc
                            let user = try decoder.decode(User.self, from: current.0)
                            var image = try decoder.decode(Image.self, from: current.1)
                            image.user = user
                            acc.append(image)
                            return acc
                        }
  }
}
