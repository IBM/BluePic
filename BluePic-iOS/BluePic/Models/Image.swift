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

// MARK: Conformance protocols

protocol ImageUpload {
    var caption: String {get}
    var fileName: String {get}
    var width: CGFloat {get}
    var height: CGFloat {get}
    var location: Location {get}
    var image: UIImage? {get}
}

protocol ImageDownload: ImageUpload {
    var user: User {get}
    var id: String {get}
    var timeStamp: Date {get}
    var url: String {get}
    var tags: [Tag]? {get}
}

// MARK: Data models

struct Tag {
    let label: String
    let confidence: CGFloat
}

struct Location {
    let name: String
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let weather: Weather?
}

func ==(lhs: Location, rhs: Location) -> Bool {
    return lhs.name == rhs.name &&
        lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude
}

struct Weather {
    let temperature: Int
    let iconId: Int
    let description: String
}

func ==(lhs: Weather, rhs: Weather) -> Bool {
    return lhs.temperature == rhs.temperature &&
        lhs.iconId == rhs.iconId &&
        lhs.description == rhs.description
}

struct ImagePayload: ImageUpload, Equatable {
    fileprivate(set) var caption: String
    fileprivate(set) var fileName: String
    fileprivate(set) var width: CGFloat
    fileprivate(set) var height: CGFloat
    fileprivate(set) var location: Location
    fileprivate(set) var image: UIImage?
}

func ==(lhs: ImagePayload, rhs: ImagePayload) -> Bool {
    return lhs.caption == rhs.caption &&
        lhs.fileName == rhs.fileName &&
        lhs.width == rhs.width &&
        lhs.height == rhs.height &&
        lhs.location == rhs.location &&
        lhs.image === rhs.image
}

struct Image: ImageDownload {
    fileprivate(set) var caption: String
    fileprivate(set) var fileName: String
    fileprivate(set) var width: CGFloat
    fileprivate(set) var height: CGFloat
    fileprivate(set) var location: Location
    fileprivate(set) var user: User
    fileprivate(set) var id: String
    fileprivate(set) var timeStamp: Date
    fileprivate(set) var url: String
    fileprivate(set) var image: UIImage?
    fileprivate(set) var tags: [Tag]?

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
            self.user = User(facebookID: usersId, name: usersName)
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
}
