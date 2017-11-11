/**
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
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation
import CoreLocation

struct Location: Codable {
    let name: String
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let weather: Weather?
}

struct Weather: Codable {
    let temperature: Int
    let iconId: Int
    let description: String
}

func ==(l: Location?, r: Location?) -> Bool {
    guard let lhs = l, let rhs = r else {
        return l == nil || r == nil
    }
    return lhs.name == rhs.name &&
        lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude
}

func ==(lhs: Weather, rhs: Weather) -> Bool {
    return lhs.temperature == rhs.temperature &&
        lhs.iconId == rhs.iconId &&
        lhs.description == rhs.description
}
