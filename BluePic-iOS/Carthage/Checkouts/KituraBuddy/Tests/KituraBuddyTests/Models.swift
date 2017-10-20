/*
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
 */

import Foundation

// Models/entities (application/use case specific)
public struct User: Codable, Equatable {
    public let id: Int
    public let name: String
    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }

    public static func ==(lhs: User, rhs: User) -> Bool {
        return (lhs.id == rhs.id) && (lhs.name == rhs.name)
   }

}

public struct Employee: Codable, Equatable {    
    public let id: String
    public let name: String

    public static func ==(lhs: Employee, rhs: Employee) -> Bool {
        return (lhs.id == rhs.id) && (lhs.name == rhs.name)
    }
}

let initialStore = [
    "1": User(id: 1, name: "Mike"),
    "2": User(id: 2, name: "Chris"),
    "3": User(id: 3, name: "Ricardo"),
    "4": User(id: 4, name: "Aaron")
]

let initialStoreEmployee = [
    "1": Employee(id: "1", name: "Mike"),
    "2": Employee(id: "2", name: "Chris"),
    "3": Employee(id: "3", name: "Ricardo"),
    "4": Employee(id: "4", name: "Aaron")
]
