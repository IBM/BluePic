//
//  main.swift
//  BluePic-server
//
//  Created by Ira Rosen on 28/12/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import router
import net
import sys

import CouchDB
import SwiftRedis
import HeliumLogger

import SwiftyJSON

import Foundation

Log.logger = BasicLogger()

let (connectionProperties, dbName, redisHost, redisPort) = getConfiguration()

let dbClient = CouchDBClient(connectionProperties: connectionProperties)
let database = dbClient.database(dbName)

let router = Router()

let redis = Redis()
redis.connect(redisHost, port: redisPort) {error in
    if  let error = error {
        Log.error("Failed to connect to Redis server at \(redisHost):\(redisPort). Error=\(error.localizedDescription)")
    }
}

setupAdmin()

setupPhotos()

let server = HttpServer.listen(8090, delegate: router)

Server.run()







