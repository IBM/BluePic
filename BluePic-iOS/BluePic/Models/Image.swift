//
//  Image.swift
//  BluePic
//
//  Created by Alex Buck on 4/29/16.
//  Copyright © 2016 MIL. All rights reserved.
//

import UIKit


struct Tag {
    var label: String?
    var confidence: CGFloat?
}

struct Location {
    var temperature: String?
    var name: String?
    var latitude : Double?
    var longitude: Double?
    var weather : String?
}

class Image: NSObject {

    var id : String?
    var caption : String?
    var fileName : String?
    var timeStamp : NSDate?
    var url : String?
    var width : CGFloat?
    var height : CGFloat?
    var image : UIImage?
    var latitude : String?
    var longitude : String?
    var city : String?
    var state : String?
    var location : Location?
    var tags : [Tag]?
    var user : User?
    
    override init() {
        
    }
    
    init?(_ dict : [String : AnyObject]) {
        
        super.init()
  
            if let id = dict["_id"] as? String,
                let caption = dict["caption"] as? String,
                let fileName = dict["fileName"] as? String,
                let url = dict["url"] as? String,
                let timeStamp = dict["uploadedTs"] as? String,
                let user = dict["user"] as? [String : AnyObject] {
            
                self.id = id
                self.caption = caption
                self.fileName = fileName
                self.url = url
                
                let userObject = User()
                if let usersName = user["name"] as? String,
                    let usersId = user["_id"] as? String{
                    
                    userObject.name = usersName
                    userObject.facebookID = usersId
                    
                }
                self.user = userObject
                
                //Parse widht and height data
                if let width = dict["width"] as? CGFloat,
                    let height = dict["height"] as? CGFloat {
                        self.width = width
                        self.height = height
                }
                
    
                //Parse location data
                if let location = dict["location"] as? [String : AnyObject]{
                        if let name = location["name"] as? String,
                        let latitude = location["latitude"] as? String,
                        let longitude = location["longitude"] as? String {
          
                        var loc = Location()
                    
                        loc.name = name
                        loc.latitude = Double(latitude)
                        loc.longitude = Double(longitude)
                        if let temperature = location["temperature"] as? String {
                            loc.temperature = temperature
                        }
                        if let weather = location["weather"] as? String {
                            loc.weather = weather
                        }
                        
                        self.location = loc
                    }
                }
                
                //Parse tags data
                var tagsArray = [Tag]()
                if let tags = dict["tags"] as? [[String: AnyObject]] {
                    for tag in tags {
                        if let label = tag["label"] as? String,
                            let confidence = tag["confidence"] as? CGFloat {
                        
                            var tag = Tag()
                            tag.label = label
                            tag.confidence = confidence
                            tagsArray.append(tag)
    
                        }
                    }
                }
                self.tags = tagsArray

                //set timeStamp
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                dateFormatter.timeZone = NSTimeZone(abbreviation: "UTC")
                if let date = dateFormatter.dateFromString(timeStamp) {
                    
                    print("image date for \(caption) is \(date)")
                    self.timeStamp = date
                }
                

            }else{
                print("invalid image json")
                return nil
            }
        
    }

    
}
