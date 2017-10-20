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

public extension String {

    /// A string url expansion method that replaces templated values in a url, with parameters
    /// The template value pattern to be replaced should look like this `{key}`
    /// You can include multiple patterns in a URL as long as you have key and values to replace them
    ///
    /// - Parameter params: parameters to be inserted into the url
    /// - Returns: a `URLComponents` object with expanded url or nil if no substitution was made
    public func expand(params: [String: String]) -> URLComponents? {

        var urlString = self
        for (key, value) in params {
            urlString = urlString.replacingOccurrences(of: "{" + key + "}", with: value)
        }
        return URLComponents(string: urlString) ?? nil
    }

    /// Creates a user agent string to explain the current platform being used. 
    /// `self` is expected to be product info, typically in the format `<productName>/<productVersion>`
    ///
    /// - Returns: user agent `String`
    public func generateUserAgent() -> String {

        let operatingSystem: String = {
            #if os(iOS)
                return "iOS"
            #elseif os(watchOS)
                return "watchOS"
            #elseif os(tvOS)
                return "tvOS"
            #elseif os(macOS)
                return "macOS"
            #elseif os(Linux)
                return "Linux"
            #else
                return "Unknown"
            #endif
        }()

        let operatingSystemVersion: String = {
            let os = ProcessInfo.processInfo.operatingSystemVersion
            return "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
        }()

        return "\(self) \(operatingSystem)/\(operatingSystemVersion)"
    }
}
