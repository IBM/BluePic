/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
This sample program is provided AS IS and may be used, executed, copied and modified without royalty payment by customer (a) for its own instruction and study, (b) in order to develop applications designed to run with an IBM product, either for customer's own internal use or for redistribution by customer, as part of such an application, in customer's own products.
*/

import Foundation
import UIKit


extension UIFont {
    
    
    /**
    Method to print all the font names registered with xcode
    */
    class func printAllFontNames(){
        
        for family in UIFont.familyNames()
        {
            print(family)
            
            let names = UIFont.fontNamesForFamilyName(family as String)
            
            for name in names{
                print(" \(name)")
            }
        }
    }
    
    
    /**
    Method that returns travelExtraBoldItalic font defined in the Fonts.plist file
    
    - parameter size: CGFloat
    
    - returns: UIFont
    */
    class func travelExtraBoldItalic(size : CGFloat) -> UIFont {
        return UIFont(name: self.accessFontsPlist("travelExtraBoldItalic"), size: size)!
    }
    
    
    
    /**
    Method that returns travelSemiBoldItalic font defined in the Fonts.plist file
    
    - parameter size: CGFloat
    
    - returns: UIFont
    */
    class func travelSemiBoldItalic(size : CGFloat) -> UIFont {
        return UIFont(name: self.accessFontsPlist("travelSemiBoldItalic"), size: size)!
    }
    
    
    /**
    Method that returns travelExtraBold font defined in the Fonts.plist file
    
    - parameter size: CGFloat
    
    - returns: UIFont
    */
    class func travelExtraBold(size : CGFloat) -> UIFont {
        return UIFont(name: self.accessFontsPlist("travelExtraBold"), size: size)!
    }
    
    
    /**
    Method that returns travelBoldItalic font defined in the Fonts.plist file
    
    - parameter size: CGFloat
    
    - returns: UIFont
    */
    class func travelBoldItalic(size : CGFloat) -> UIFont {
        return UIFont(name: self.accessFontsPlist("travelBoldItalic"), size: size)!
    }
    
    
    /**
    Method that returns travelItalic font defined in the Fonts.plist file
    
    - parameter size: CGFloat
    
    - returns: UIFont
    */
    class func travelItalic(size : CGFloat) -> UIFont {
        return UIFont(name: self.accessFontsPlist("travelItalic"), size: size)!
    }
    
    
    /**
    Method that returns travelSemiBold font defined in the Fonts.plist file
    
    - parameter size: CGFloat
    
    - returns: UIFont
    */
    class func travelSemiBold(size : CGFloat) -> UIFont {
        return UIFont(name: self.accessFontsPlist("travelSemiBold"), size: size)!
    }
    
    
    /**
    Method that returns travelLight font defined in the Fonts.plist file
    
    - parameter size: CGFloat
    
    - returns: UIFont
    */
    class func travelLight(size : CGFloat) -> UIFont {
        return UIFont(name: self.accessFontsPlist("travelLight"), size: size)!
    }
    
    
    /**
    Method that returns travelRegular font defined in the Fonts.plist file
    
    - parameter size: CGFloat
    
    - returns: UIFont
    */
    class func travelRegular(size : CGFloat) -> UIFont {
        return UIFont(name: self.accessFontsPlist("travelRegular"), size: size)!
    }
    
    
    /**
    Method that returns travelLightItalic font defined in the Fonts.plist file
    
    - parameter size: CGFloat
    
    - returns: UIFont
    */
    class func travelLightItalic(size : CGFloat) -> UIFont {
        return UIFont(name: self.accessFontsPlist("travelLightItalic"), size: size)!
    }
    
    
    /**
    Method that returns travelBold font defined in the Fonts.plist file
    
    - parameter size: CGFloat
    
    - returns: UIFont
    */
    class func travelBold(size : CGFloat) -> UIFont {
        return UIFont(name: self.accessFontsPlist("travelBold"), size: size)!
    }
    
    
    /**
    Method used to access a font from the Fonts plist
    
    - parameter font: String
    
    - returns: String
    */
    class func accessFontsPlist(font: String) -> String{
        
        var success = false
        var returnFont = "System"
        
        if let path = NSBundle.mainBundle().pathForResource("Fonts", ofType: "plist") {
            
            if let dict = NSDictionary(contentsOfFile: path) as? [String : String] {
                
                if let value = dict[font] {
                    
                    returnFont = value
                    success = true
                }
            }
        }
        
        if !success {
            print("---\naccessFontsPlist failed to find your font. Returning System.\n---")
        }
        
        return success ? returnFont : "System"
    }
    

}