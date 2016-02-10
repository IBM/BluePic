//
//  Photos.swift
//  SwiftBluePic-server
//
//  Created by Samuel Kallner on 09/02/2016.
//  Copyright © 2016 IBM. All rights reserved.
//

import router
import net
import sys

import CouchDB
import SwiftRedis
import LoggerAPI

import SwiftyJSON

import Foundation


/// Setup the handlers for the Photo APIs
func setupPhotos() {
    router.use("/photos/*", middleware: BodyParser())
    
    
    router.get("/photos") { _, response, next in
        database.queryByView("sortedByDate", ofDesign: "photos", usingParameters: [.Descending(true)]) { (document, error) in
            if  let document = document where error == nil  {
                do {
                    updatePhotoListsFetchedCounter()
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
            let photoName = request.params["photoname"]!
            
            do {
                try image = BodyParser.readBodyData(request)
            }
            catch {
                response.error = NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey:"Invalid photo"])
                next()
                return
            }
            
            database.create(JSON(document)) { (id, revision, doc, error) in
                if let _ = doc, let id = id, let revision = revision where error == nil {
                    database.createAttachment(id, docRevison: revision, attachmentName: photoName, attachmentData: image!, contentType: contentType) { (rev, photoDoc, error) in
                        if let _ = photoDoc where error == nil  {
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
}

private func updatePhotoListsFetchedCounter() {
    let multi = redis.multi()
    multi.incr("PhotoListsFetched")
    multi.expire("PhotoListsFetched", inTime: Double(1440*60))
    multi.exec() {response in
        if  let responses = response.asArray,
                    _ = responses[0].asInteger,
                    _ = responses[1].asInteger {
            // All is OK
        }
        else {
            Log.error("Failed to increment PhotoListsFetched counter")
        }
    }
}