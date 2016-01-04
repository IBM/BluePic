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

func createPhotoDocument (owner: String?, title: String?, photoName: String?) -> (JSON?, String?) {
    if owner == nil || photoName == nil {
        return (nil, nil)
    }
    
    let ext = photoName!.componentsSeparatedByString(".")[1].lowercaseString
    let contentType = ContentType.contentTypeForExtension(ext)

    print("photoName: \(photoName), ext: \(ext)")

    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    let dateString = dateFormatter.stringFromDate(NSDate())
    
    let doc = JSON(["owner": owner!, "title": (title == nil ? "" : title!), "date": dateString, "inFeed": true, "type": "photo"])
    
    
    print("type: \(contentType), doc: \(doc)")
    
    return (doc, contentType)
}