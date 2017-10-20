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

import SafetyContracts

extension Persistable {
    // create
    static func create(model: Self, respondWith: @escaping (Self?, Error?) -> Void) {
       // dummy implementation
    }

    // read
    static func read(id: Id, respondWith: @escaping (Self?, Error?) -> Void) {
        // dummy implementation
    }

    // read all
    static func read(respondWith: @escaping ([Self]?, Error?) -> Void) {
        // dummy implementation
    }

    // update
    static func update(id: Id, model: Self, respondWith: @escaping (Self?, Error?) -> Void) {
        // dummy implementation
    }

    // delete
    static func delete(id: Id, respondWith: @escaping (Error?) -> Void) {
        // dummy implementation
    }

    // delete all
    static func delete(respondWith: @escaping (Error?) -> Void) {
        // dummy implementation
    }
}

struct User: Codable {
    let id: String
    let name: String
}

extension User: Persistable {
    public typealias Id = Int
}


