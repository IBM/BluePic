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

struct Weather {
    let temperature: Int
    let iconId: Int
    let description: String
}

class Image: NSObject {
    var id: String?
    var caption: String
    let fileName: String
    var timeStamp: NSDate?
    var url: String?
    let width: CGFloat
    let height: CGFloat
    var image: UIImage?
    let location: Location
    var tags: [Tag]?
    let user: User

    init(caption: String, fileName: String, width: CGFloat, height: CGFloat, image: UIImage, location: Location, user: User) {
        self.caption = caption
        self.fileName = fileName
        self.width = width
        self.height = height
        self.image = image
        self.location = location
        self.user = user
    }

    init?(_ dict: [String : AnyObject]) {

        // MARK: Set optional properties

        if let url = dict["url"] as? String {
            self.url = url
        }
        if let timeStamp = dict["uploadedTs"] as? String {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            dateFormatter.timeZone = NSTimeZone(abbreviation: "UTC")
            if let date = dateFormatter.dateFromString(timeStamp) {
                self.timeStamp = date
            }
        }

        //Parse tags data
        var tagsArray = [Tag]()
        if let tags = dict["tags"] as? [[String: AnyObject]] {
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
            let user = dict["user"] as? [String : AnyObject],
            usersName = user["name"] as? String,
            usersId = user["_id"] as? String {

            self.id = id
            self.caption = caption
            self.fileName = fileName
            self.width = width
            self.height = height
            self.user = User(facebookID: usersId, name: usersName)

            //Parse location data
            if let location = dict["location"] as? [String : AnyObject],
                name = location["name"] as? String,
                latitude = location["latitude"] as? CLLocationDegrees,
                longitude = location["longitude"] as? CLLocationDegrees {

                //Parse weather object
                var weatherObject: Weather?
                if let weather = location["weather"] as? [String : AnyObject],
                temperature = weather["temperature"] as? Int,
                iconId = weather["iconId"] as? Int,
                description = weather["description"] as? String {
                    weatherObject = Weather(temperature: temperature, iconId: iconId, description: description)
                }

                self.location = Location(name: name, latitude: latitude, longitude: longitude, weather: weatherObject)

            } else {
                print(NSLocalizedString("invalid image json", comment: ""))
                return nil
            }

        } else {
            print(NSLocalizedString("invalid image json", comment: ""))
            return nil
        }
    }
}
