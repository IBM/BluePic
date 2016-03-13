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

import KituraRouter
import KituraNet
import KituraSys

import CouchDB
import SwiftRedis
import LoggerAPI
import HeliumLogger
import Credentials
import CredentialsFacebookToken

import SwiftyJSON

import Foundation

Log.logger = HeliumLogger()

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

let fbCredentials = CredentialsFacebookToken()
let credentials = Credentials()
credentials.register(fbCredentials)

setupAdmin()

setupPhotos()

let server = HttpServer.listen(8090, delegate: router)

Server.run()







