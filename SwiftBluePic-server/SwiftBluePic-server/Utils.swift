//
//  Utils.swift
//  BluePic-server
//
//  Created by Ira Rosen on 31/12/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import CouchDB
import router
import net
import HeliumLogger

import SwiftyJSON

import Foundation

func parsePhotosList (list: JSON) -> JSON {
    var photos = [JSON]()
    let listLength = Int(list["total_rows"].number!)
    if listLength == 0 {
        let empty = [[String:String]]()
        return JSON(empty)
    }
    for index in 0...(listLength - 1) {
        let photoId = list["rows"][index]["id"].stringValue
        let date = list["rows"][index]["key"].stringValue
        let data = list["rows"][index]["value"].dictionaryValue
        let title = data["title"]!.stringValue
        let ownerId = data["ownerId"]!.stringValue
        let ownerName = data["ownerName"]!.stringValue
        let attachments = data["attachments"]!.dictionaryValue
        let attachmentName = ([String](attachments.keys))[0]
            
        let photo = JSON(["title": title,  "date": date, "ownerId": ownerId, "ownerName": ownerName, "picturePath": "\(photoId)/\(attachmentName)"])
        photos.append(photo)
        
    }
    return JSON(photos)
}

func createPhotoDocument (request: RouterRequest) -> ([String:AnyObject]?, String?) {
    let ownerId = request.params["ownerId"]
    var ownerName = request.params["ownerName"]
    var title = request.params["title"]
    let photoName = request.params["photoname"]
    
    if ownerId == nil || ownerName == nil || photoName == nil {
        return (nil, nil)
    }

    ownerName = ownerName!.stringByReplacingOccurrencesOfString("%20", withString: " ")
    title = title?.stringByReplacingOccurrencesOfString("%20", withString: " ") ?? ""
    
    let ext = photoName!.componentsSeparatedByString(".")[1].lowercaseString
    let contentType = ContentType.contentTypeForExtension(ext)

    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    let dateString = dateFormatter.stringFromDate(NSDate()).bridge()
    
    let doc : [String:AnyObject] = ["ownerId": ownerId!.bridge(), "ownerName": ownerName!.bridge(), "title": title!.bridge(), "date": dateString, "inFeed": NSNumber(bool: true), "type": NSString(string:"photo")]
    
    return (doc, contentType)
}

func createUploadReply (fromDocument document: [String:AnyObject], id: String, photoName: String) -> JSON {
    var result = [String:String]()
    result["picturePath"] = "\(id)/\(photoName)"
    result["ownerId"] = document["ownerId"] as? String
    result["ownerName"] = document["ownerName"] as? String
    result["date"] = document["date"] as? String
    result["title"] = document["title"] as? String
    return JSON(result)
}

func getConfiguration () -> (ConnectionProperties, String, String, Int32) {
    
// In order to be able to access CouchDB through external address, go to 127.0.0.1:5984/_utils/config.html, httpd section and change bind_address to 0.0.0.0, and restart couchdb.
    
// Requires export CONFIG_DIR = ...
//    if let configDir = NSString(UTF8String: getenv("CONFIG_DIR")) as? String,
//    let configData = NSData(contentsOfFile: configDir + "./config.json")
    
    if let configData = NSData(contentsOfFile: "./config.json") {
        let configJson = JSON(data:configData)
        if let ipAddress = configJson["couchDbIpAddress"].string,
            let port = configJson["couchDbPort"].number,
            let dbName = configJson["couchDbDbName"].string,
            let redisHost = configJson["redisIpAddress"].string,
            let redisPort = configJson["redisPort"].number {
                return (ConnectionProperties(hostName: ipAddress, port: Int16(port.integerValue), secured: false),
                    dbName,
                    redisHost, Int32(redisPort.integerValue))
        }
    }
    print("Failed to read the configuration file!")
    exit(1)
}

func getDesign () -> (String?, JSON?) {

    let designDoc = JSON(["_id" : "_design/photos",
        "views" : [
            "sortedByDate" : [
                "map" : "function(doc) {if (doc.type == 'photo' && doc.title && doc.date && doc.ownerId && doc.ownerName) { emit(doc.date, {title: doc.title, ownerId: doc.ownerId, ownerName: doc.ownerName, attachments: doc._attachments});}}"
            ]
        ]
        ])
    return ("photos", designDoc)
}


func respond(response: RouterResponse, withStatus status: HttpStatusCode) {
    do {
        try response.status(status).end()
    }
    catch {
        Log.error("Failed to send response to client")
    }
}

func respond(response: RouterResponse, withJSON json: JSON, withStatus status: HttpStatusCode) {
    do {
        try response.status(status).sendJson(json).end()
    }
    catch {
        Log.error("Failed to send response to client")
    }
}

func respond(response: RouterResponse, withData data: NSData, withContentType contentType: String?, withStatus status: HttpStatusCode) {
    if let contentType = contentType {
        response.setHeader("Content-Type", value: contentType)
    }
    do {
        try response.status(status).end(data)
    }
    catch {
        Log.error("Failed to send response to client")
    }
}


