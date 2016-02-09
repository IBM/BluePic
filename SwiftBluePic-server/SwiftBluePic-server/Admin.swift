//
//  Admin.swift
//  SwiftBluePic-server
//
//  Created by Samuel Kallner on 09/02/2016.
//  Copyright © 2016 IBM. All rights reserved.
//

import router
import sys
import net

import CouchDB
import HeliumLogger

import SwiftyJSON

import Foundation


func setupAdmin() {
    router.get("/connect") { _, response, next in
        do {
            try response.status(HttpStatusCode.OK).end()
        }
        catch {
            response.error = NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey:"Internal error"])
        }
        
        next()
    }
    
    router.post("/admin/setup") { request, response, next in
        dbClient.dbExists(dbName) { (exists, error) in
            if  error != nil {
                response.error = error!
                next()
            }
            else if  exists  {
                respond(response, withStatus: HttpStatusCode.OK)
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
                                respond(response, withStatus: HttpStatusCode.OK)
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