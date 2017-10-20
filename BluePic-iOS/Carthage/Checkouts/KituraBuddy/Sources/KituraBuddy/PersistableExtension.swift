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
 * See the License for the specific langua›ge governing permissions and
 * limitations under the License.
 */

import Foundation
import SafetyContracts

// CRUD API - type safe routing
extension Persistable {
    
    static var client: KituraBuddy {
        return KituraBuddy.default
    }
    
    // create
    static func create(model: Self, respondWith: @escaping (Self?, Error?) -> Void) {
        client.post(route, data: model) { (model: Self?, error: Error?) -> Void in
            // First determine if error was not nil            
            if let error = error {
                respondWith(nil, error)
                return
            }

            // Next, determine if model was nil
            guard let model = model else {
                respondWith(nil, error)
                return
            }
            
            // If we get here, then model was not nil and error was nil
            respondWith(model, nil)
        }
    }
    
    // read
    static func read(id: Id, respondWith: @escaping (Self?, Error?) -> Void) {
        client.get(route, identifier: id) { (model: Self?, error: Error?) -> Void in
            if let error = error {
                respondWith(nil, error)
                return
            }

            guard let model = model else {
                respondWith(nil, error)
                return
            }
            
            respondWith(model, nil)
        }
    }
    
    // read all
    static func read(respondWith: @escaping ([Self]?, Error?) -> Void) {
        client.get(route) { (model: [Self]?, error: Error?) -> Void in
            
            if let error = error {
                respondWith(nil, error)
                return
            }

            guard let model = model else {
                respondWith(nil, error)
                return
            }
            
            respondWith(model, nil)
        }
    }


    // update
    static func update(id: Id, model: Self, respondWith: @escaping (Self?, Error?) -> Void) {
        client.put(route, identifier: id, data: model) { (model: Self?, error: Error?) -> Void in
            
            if let error = error {
                respondWith(nil, error)
                return
            }

            guard let model = model else {
                respondWith(nil, error)
                return
            }
            
            respondWith(model, nil)
        }
    }

    // delete
    static func delete(id: Id, respondWith: @escaping (Error?) -> Void) {
        // Perform delete REST call...
        client.delete(route, identifier: id) { (error: Error?) -> Void in
            respondWith(error)
        }
    }

    // delete all
    static func delete(respondWith: @escaping (Error?) -> Void) {
        // Perform delete REST call...
        client.delete("/") { (error: Error?) -> Void in
            respondWith(error)
        }
    }

}

