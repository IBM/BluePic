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

import router
import sys
import net

import CouchDB
import LoggerAPI

import SwiftyJSON

import Foundation


func setupAdmin() {
    router.get("/connect") { _, response, next in
        response.status(HttpStatusCode.OK)
        
        next()
    }
    
    router.post("/admin/setup") { request, response, next in
        dbClient.dbExists(dbName) { (exists, error) in
            if  error != nil {
                response.error = error!
                next()
            }
            else if  exists  {
                response.status(HttpStatusCode.OK)
                next()
            }
            else {
                dbClient.createDB(dbName) { (db, error) in
                    guard  error == nil  &&  db != nil  else {
                        response.error = error ?? NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey:"Internal error"])
                        next()
                        return
                    }
                    
                    let (designName, design) = getDesign()
                    if let design = design, let designName = designName {
                        database.createDesign (designName, document: design) { (document, error) in
                            if  error == nil  &&  document != nil  {
                                response.status(HttpStatusCode.OK)
                            }
                            else {
                                response.error = error  ??  NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey:"Internal error"])
                            }
                            next()
                        }
                    }
                    else {
                        next()
                    }
                }
            }
        }
    }
}
