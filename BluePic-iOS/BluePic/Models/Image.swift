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

import UIKit
import CoreLocation
import BMSCore

struct Image: Equatable {
    var caption: String
    var fileName: String
    var width: CGFloat
    var height: CGFloat
    var location: Location?
    var user: User
    var id: String?
    var timeStamp: Date?
    var url: String?
    var image: UIImage?
    var tags: [Tag] = []
    internal var isExpanded = false

    init?(_ dict: [String : Any]) {

        //Parse tags data
        var tagsArray = [Tag]()
        if let tags = dict["tags"] as? [[String: Any]] {
            for tag in tags {
                if let label = tag["label"] as? String,
                    let confidence = tag["confidence"] as? CGFloat {
                    let tag = Tag(label: label, confidence: confidence)
                    tagsArray.append(tag)
                }
            }
        }
        self.tags = tagsArray

        // MARK: Set required properties

        if let id = dict["_id"] as? String,
            let caption = dict["caption"] as? String,
            let fileName = dict["fileName"] as? String,
            let width = dict["width"] as? CGFloat,
            let height = dict["height"] as? CGFloat,
            let user = dict["user"] as? [String : Any],
            let usersName = user["name"] as? String,
            let usersId = user["_id"] as? String,
            let url = dict["url"] as? String,
            let timeStamp = dict["uploadedTs"] as? String {

            self.id = id
            self.caption = caption
            self.fileName = fileName
            self.width = width
            self.height = height
            self.user = User(id: usersId, name: usersName)
            self.url = url

            //Parse location data
            if let location = dict["location"] as? [String : Any],
                let name = location["name"] as? String,
                let latitude = location["latitude"] as? CLLocationDegrees,
                let longitude = location["longitude"] as? CLLocationDegrees {

                //Parse weather object
                var weatherObject: Weather?
                if let weather = location["weather"] as? [String : Any],
                    let temperature = weather["temperature"] as? Int,
                    let iconId = weather["iconId"] as? Int,
                    let description = weather["description"] as? String {
                    weatherObject = Weather(temperature: temperature, iconId: iconId, description: description)
                }

                self.location = Location(name: name, latitude: latitude, longitude: longitude, weather: weatherObject)

            } else {
                print(NSLocalizedString("invalid image json", comment: ""))
                return nil
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            guard let date = dateFormatter.date(from: timeStamp) else {
                print(NSLocalizedString("Couldn't process timestamp", comment: ""))
                return nil
            }
            self.timeStamp = date

        } else {
            print(NSLocalizedString("invalid image json", comment: ""))
            return nil
        }
    }

    init(caption: String, fileName: String, width: CGFloat, height: CGFloat, location: Location, image: UIImage) {
        self.caption = caption
        self.fileName = fileName
        self.width = width
        self.height = height
        self.location = location
        self.user = User(id: CurrentUser.facebookUserId, name: CurrentUser.fullName)

        self.timeStamp = Date()
        self.image = image
    }
}

extension Image: Codable {

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case fileName
        case caption
        case width
        case height
        case tags
        case uploadedTs
        case type
        case location
        case user
        case userId
        case url
        case image
        case deviceId
    }

    func encode(to encoder: Encoder) throws {
        guard let img = image, let imageData = UIImagePNGRepresentation(img) else {
            print(NSLocalizedString("Post New Image Error: Could not process image data properly", comment: ""))
            NotificationCenter.default.post(name: .imageUploadFailure, object: nil)
            return
        }

        // Sending deviceId and userId through image request body due to server App ID SDK limitations.
        guard let deviceId = BMSClient.sharedInstance.authorizationManager.deviceIdentity.ID else {
            print(NSLocalizedString("Error: Could not get device ID from BMSClient", comment: ""))
            NotificationCenter.default.post(name: .imageUploadFailure, object: nil)
            return
        }

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encode(fileName, forKey: .fileName)
        try container.encode(caption, forKey: .caption)
        try container.encode(Double(height), forKey: .height)
        try container.encode(Double(width), forKey: .width)
        try container.encode(tags, forKey: .tags)
        try container.encode(deviceId, forKey: .deviceId)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encode(user, forKey: .user)
        try container.encode(user.id, forKey: .userId)
        try container.encodeIfPresent(imageData, forKey: .image)
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = try values.decode(String.self, forKey: .id)
        fileName = try values.decode(String.self, forKey: .fileName)
        caption = try values.decode(String.self, forKey: .caption)
        url = try values.decodeIfPresent(String.self, forKey: .url)
        width = CGFloat(integerLiteral: try values.decode(Int.self, forKey: .width))
        height = CGFloat(integerLiteral: try values.decode(Int.self, forKey: .height))
        tags = try values.decodeIfPresent([Tag].self, forKey: .tags) ?? []
        location = try values.decodeIfPresent(Location.self, forKey: .location)
        user = try values.decodeIfPresent(User.self, forKey: .user) ?? User(id: "Anonymous", name: "anonymous")
        timeStamp = Utils.dataFormatter(timestamp: try values.decode(String.self, forKey: .uploadedTs))
    }
}

func ==(lhs: Image, rhs: Image) -> Bool {
    var sameLocation = false
    if let ll = lhs.location, let rl = rhs.location {
        sameLocation = ll == rl
    } else {
        sameLocation = lhs.location == nil && rhs.location == nil
    }
    return lhs.caption == rhs.caption &&
        lhs.fileName == rhs.fileName &&
        lhs.width == rhs.width &&
        lhs.height == rhs.height &&
        sameLocation &&
        lhs.image === rhs.image
}
