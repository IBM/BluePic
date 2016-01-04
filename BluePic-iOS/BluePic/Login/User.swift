//
//  Created by Assaf Akrabi on 2/26/15.
//  Copyright (c) 2015 IBM Corporation. All rights reserved.
//

import Foundation

class User {
    
    enum UserType {
        case Facebook
        case Google
        case Dummy
        case LoggedOut
    }
    
    var id: String = ""
    var name: String = ""
    var email: String = ""
    var type: UserType = UserType.LoggedOut
    
    private var imageURL: String = ""
    
    class var sharedInstance: User {
        struct Singleton {
            static let instance = User()
        }
        return Singleton.instance
    }
    
//    func set(fromFacebook user: AnyObject) {
//        type = UserType.Facebook
//        id = user.valueForKey("id") as! String
//        name = user.valueForKey("name") as! String
//        email = user.valueForKey("email") as! String
//        imageURL = "https://graph.facebook.com/\(id)/picture"
//    }
    
//    func set(fromGoogle user: GTLPlusPerson) {
//        type = UserType.Google
//        id = user.identifier
//        name = user.displayName
//        email = user.emails[0].value!!
//        imageURL = user.image.url
//    }
    
    func getImageURL(imageSize: Int?) -> NSURL? {
        if imageURL.isEmpty {
            return nil
        }
        if let urlComponents = NSURLComponents(string: imageURL) {
            if let size = imageSize {
                if type == UserType.Facebook {
                    urlComponents.query = "type=square&width=\(size)&height=\(size)"
                }
                if type == UserType.Google {
                    urlComponents.query = "sz=\(size)"
                }
            }
            return urlComponents.URL
        }
        return nil
    }
    
    func signOut() {
//        if type == UserType.Facebook {
//            FBSDKLoginManager().logOut()
//        }
//        else if type == UserType.Google {
//            GPPSignIn.sharedInstance().signOut()
//        }
        type = UserType.LoggedOut
        id = ""
        name = ""
        email = ""
        imageURL = ""
    }
}