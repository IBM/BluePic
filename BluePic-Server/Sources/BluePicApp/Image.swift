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

struct Image: Codable {
  let id: String
  var rev: String?
  let fileName: String
  let caption: String
  let contentType: String
  let url: String
  let width: Int
  let height: Int
  let tags: [Tag]
  let uploadedTs: String
  let userId: String
  let deviceId: String?
  let location: Location?

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
    case type
    case location
  }
}

extension Image {
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(fileName, forKey: .fileName)
    try container.encode(rev, forKey: .rev)
    try container.encode(caption, forKey: .caption)
    try container.encode(contentType, forKey: .contentType)
    try container.encode(url, forKey: .url)
    try container.encode(height, forKey: .height)
    try container.encode(width, forKey: .width)
    try container.encode(tags, forKey: .tags)
    try container.encode(uploadedTs, forKey: .uploadedTs)
    try container.encode(userId, forKey: .userId)
    try container.encodeIfPresent(deviceId, forKey: .deviceId)
    try container.encodeIfPresent(location, forKey: .location)
    try container.encode("image", forKey: .type)
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)

    id = try values.decode(String.self, forKey: .id)
    rev = try values.decode(String.self, forKey: .rev)
    fileName = try values.decode(String.self, forKey: .fileName)
    caption = try values.decode(String.self, forKey: .caption)
    contentType = try values.decode(String.self, forKey: .contentType)
    url = try values.decode(String.self, forKey: .url)
    width = try values.decode(Int.self, forKey: .width)
    height = try values.decode(Int.self, forKey: .height)
    tags = try values.decodeIfPresent([Tag].self, forKey: .tags) ?? []
    uploadedTs = try values.decode(String.self, forKey: .uploadedTs)
    userId = try values.decode(String.self, forKey: .userId)
    deviceId = try values.decodeIfPresent(String.self, forKey: .deviceId)
    location = try values.decodeIfPresent(Location.self, forKey: .location)
  }
}

struct TagCount: Codable {
  let key: String
  let value: Int
}

struct Tag: Codable {
  let label: String
  let confidence: Int
}

struct Weather: Codable {
  let description: String
  let temperature: Int
  let iconId: Int
}

struct Location: Codable {
  let name: String
  let latitude: Double
  let longitude: Double
  let weather: Weather?

}
