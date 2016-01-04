//
//  main.swift
//  BluePic-server
//
//  Created by Ira Rosen on 28/12/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import router
import sys
import net

import SwiftCouchDB

import SwiftyJSON

import Foundation

let router = Router()
let database = CouchDB(ipAddress: "localhost", port: 5984, dbName: "swift-bluepic")


router.use("/photos/*", middleware: BodyParser())


router.get("/photos") { (request: RouterRequest, response: RouterResponse, next: ()->Void) in
    
    database.queryByView("sortedByDate", ofDesign: "photos", usingParameters: [.Descending(true)]) { (document, error) in
        guard  error == nil  else {
            response.error = error
            next()
            return
        }
        
        if let document = document {
            do {
                try response.status(HttpStatusCode.OK).sendJson(parsePhotosList(document)).end()
            }
            catch {
                response.error = NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey:"Internal error"])
            }
        }
        else {
            response.error = NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey:"View not found"])
        }
        next()
    }
}


router.get("/photos/:docid/:photoid") { (request: RouterRequest, response: RouterResponse, next: ()->Void) in
    let docId = request.params["docid"]
    let attachmentName = request.params["photoid"]
    if docId != nil && attachmentName != nil {
        database.retrieveAttachment(docId!, attachmentName: attachmentName!) { (photo, error, contentType) in
            guard  error == nil  else {
                response.error = error
                next()
                return
            }

            if let photo = photo {
                if let contentType = contentType {
                    response.setHeader("Content-Type", value: contentType)
                }
                do {
                    try response.status(HttpStatusCode.OK).end(photo)
                }
                catch {
                    response.error = NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey:"Internal error"])
                }
            }
            else {
                response.error = NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey:"Photo not found"])
            }
            next()
        }
    }
    else {
        response.error = NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey:"Photo not found"])
        next()
    }
}


router.post("/photos/:owner/:title/:photoname") { (request: RouterRequest, response: RouterResponse, next: ()->Void) in
    let owner = request.params["owner"]
    let title = request.params["title"]
    let photoName = request.params["photoname"]
    let (document, contentType) = createPhotoDocument(owner, title: title, photoName: photoName)
    var image: NSData?
    
    print("post photo")
    
    do {
        try image = BodyParser.readBodyData(request)
    }
    catch {
        response.error = NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey:"Invalid photo"])
        next()
    }

    print("got image")
    
    if let document = document, let contentType = contentType {
        
        print("creating doc on db")
        
        database.create(document) { (id, revision, doc, error) in
            guard  error == nil  else {
                response.error = error
                next()
                return
            }
            
            if let doc = doc, let id = id, let revision = revision {
                print("image size \(image!.length)")
                database.createAttachment(id, docRevison: revision, attachmentName: photoName!, attachmentData: image!, contentType: contentType) { (rev, photoDoc, error) in
                    guard  error == nil  else {
                        response.error = error
                        next()
                        return
                    }
                    if let photoDoc = photoDoc {
                        do {
                            print("picturePath: id=\(id) name = \(photoName!)")
                            try response.status(HttpStatusCode.OK).sendJson(JSON(["picturePath": "\(id)/\(photoName!)"])).end()
                        }
                        catch {
                            response.error = NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey:"Internal error"])
                        }
                    }
                    else {
                        response.error = NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey:"Internal error"])
                    }
                }
            }
            else {
                response.error = NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey:"Internal error"])
            }
            next()
        }
    }
    else {
        response.error = NSError(domain: "SwiftBluePic", code: 1, userInfo: [NSLocalizedDescriptionKey:"Invalid photo"])
        next()
    }
}


router.listen(8090)

Server.run()







