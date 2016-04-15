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

import Kitura
import KituraNet
import KituraSys

import CouchDB
import LoggerAPI
import HeliumLogger
import Credentials
import CredentialsFacebookToken
import CredentialsGoogleToken

import SwiftyJSON

import Foundation

Log.logger = HeliumLogger()

let (connectionProperties, dbName) = getConfiguration()

let dbClient = CouchDBClient(connectionProperties: connectionProperties)
let database = dbClient.database(dbName)

let router = Router()
let fbCredentials = CredentialsFacebookToken()
let googleCredentials = CredentialsGoogleToken()
let credentials = Credentials()
credentials.register(fbCredentials)
credentials.register(googleCredentials)

setupAdmin()

setupPhotos()

let server = HttpServer.listen(8090, delegate: router)

Server.run()
