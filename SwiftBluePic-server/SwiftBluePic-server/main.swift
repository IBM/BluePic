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
import HeliumLogger

import SwiftyJSON

import Foundation

Log.logger = BasicLogger()

let (connectionProperties, dbName, redisHost, redisPort) = getConfiguration()

let dbClient = CouchDBClient(connectionProperties: connectionProperties)

let database = dbClient.database(dbName)

let router = Router()

setupAdmin()


router.use("/photos/*", middleware: BodyParser())


router.get("/photos") { _, response, next in
    database.queryByView("sortedByDate", ofDesign: "photos", usingParameters: [.Descending(true)]) { (document, error) in
        if  let document = document where error == nil  {
            do {
                try response.status(HttpStatusCode.OK).sendJson(parsePhotosList(document)).end()
            }
            catch {
                Log.error("Failed to send response to client")
            }
        }
        else {
            response.error = error ?? NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey:"View not found"])
        }
        next()
    }
}


router.get("/photos/:docid/:photoid") { request, response, next in
    let docId = request.params["docid"]
    let attachmentName = request.params["photoid"]
    if docId != nil && attachmentName != nil {
        database.retrieveAttachment(docId!, attachmentName: attachmentName!) { (photo, error, contentType) in
            if  let photo = photo where error == nil  {
                respond(response, withData: photo, withContentType: contentType, withStatus: HttpStatusCode.OK)
            }
            else {
                response.error = error  ??  NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey:"Photo not found"])
            }
            next()
        }
    }
    else {
        response.error = NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey:"Photo not found"])
        next()
    }
}


router.post("/photos/:ownerId/:ownerName/:title/:photoname") { request, response, next in
    let (document, contentType) = createPhotoDocument(request)
    if let document = document, let contentType = contentType {
        var image: NSData?
        var photoName = request.params["photoname"]!
        
        do {
            try image = BodyParser.readBodyData(request)
        }
        catch {
            response.error = NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey:"Invalid photo"])
            next()
            return
        }

        database.create(JSON(document)) { (id, revision, doc, error) in
            if let doc = doc, let id = id, let revision = revision where error == nil {
                database.createAttachment(id, docRevison: revision, attachmentName: photoName, attachmentData: image!, contentType: contentType) { (rev, photoDoc, error) in
                    if let photoDoc = photoDoc where error == nil  {
                        let reply = createUploadReply(fromDocument: document, id: id, photoName: photoName)
                        respond(response, withJSON: reply, withStatus: HttpStatusCode.OK)
                    }
                    else {
                        response.error = error  ??  NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey:"Internal error"])
                    }
                    next()
                }
            }
            else {
                response.error = error ?? NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey:"Internal error"])
                next()
            }            
        }
    }
    else {
        response.error = NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey:"Invalid photo"])
        next()
    }
}


let server = HttpServer.listen(8090, delegate: router)

Server.run()







