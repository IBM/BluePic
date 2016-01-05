//
//  Utils.swift
//  BluePic-server
//
//  Created by Ira Rosen on 31/12/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import router

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
        let owner = data["owner"]!.stringValue
        let attachments = data["attachments"]!.dictionaryValue
        let attachmentName = ([String](attachments.keys))[0]
            
        let photo = JSON(["title": title,  "date": date, "owner": owner, "picturePath": "\(photoId)/\(attachmentName)"])
        photos.append(photo)
        
    }
    return JSON(photos)
}

func createPhotoDocument (owner: String?, title: String?, photoName: String?) -> ([String:AnyObject]?, String?) {
    if owner == nil || photoName == nil {
        return (nil, nil)
    }
    
    let ext = photoName!.componentsSeparatedByString(".")[1].lowercaseString
    let contentType = ContentType.contentTypeForExtension(ext)

    print("photoName: \(photoName), ext: \(ext)")

    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    let dateString = dateFormatter.stringFromDate(NSDate())
    
    let doc : [String:AnyObject] = ["owner": owner!, "title": (title == nil ? "" : title!), "date": dateString, "inFeed": true, "type": "photo"]
    
    
    print("type: \(contentType), doc: \(doc)")
    
    return (doc, contentType)
}

func createUploadReply (fromDocument document: [String:AnyObject], id: String, photoName: String) -> JSON {
    var result = [String:String]()
    result["picturePath"] = "\(id)/\(photoName)"
    result["owner"] = document["owner"] as? String
    result["date"] = document["date"] as? String
    result["title"] = document["title"] as? String
    return JSON(result)
}