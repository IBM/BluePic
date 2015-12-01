/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import UIKit

//Project Specific Colors
extension UIColor {
 
    
    /**
    Method that returns the travelMainColor by accessing the Colors.plist
    
    - returns: UIColor
    */
    class func travelMainColor() -> UIColor{return accessColorsPlist("travelMainColor")}
    
    
    /**
    Method that returns the travelDarkMainFontColor by accessing the Colors.plist
    
    - returns: UIColor
    */
    class func travelDarkMainFontColor() -> UIColor{return accessColorsPlist("travelDarkMainFontColor")}
    
    
    /**
    Method that returns the travelSemiDarkMainFontColor by accessing the Colors.plist
    
    - returns: UIColor
    */
    class func travelSemiDarkMainFontColor() -> UIColor{return accessColorsPlist("travelSemiDarkMainFontColor")}
    
    
    /**
    Method that returns the travelLightMainFontColor by accessing the Colors.plist
    
    - returns: UIColor
    */
    class func travelLightMainFontColor() -> UIColor{return accessColorsPlist("travelLightMainFontColor")}
    
    
    /**
    Method that returns the travelTabBarColor by accessing the Colors.plist
    
    - returns: UIColor
    */
    class func travelTabBarColor() -> UIColor{return accessColorsPlist("travelTabBarColor")}
    
    
    /**
    Method that returns the travelNavigationBarColor by accessing the Colors.plist
    
    - returns: UIColor
    */
    class func travelNavigationBarColor() -> UIColor{return accessColorsPlist("travelNavigationBarColor")}
    
    
    /**
    Method that returns the travelItineraryCardBackgroundColor by accessing the Colors.plist
    
    - returns: UIColor
    */
    class func travelItineraryCardBackgroundColor()-> UIColor{return accessColorsPlist("travelItineraryCardBackgroundColor")}
    
    
    /**
    Method that returns the travelItineraryCellBackgroundColor by accessing the Colors.plist
    
    - returns: UIColor
    */
    class func travelItineraryCellBackgroundColor()-> UIColor{return accessColorsPlist("travelItineraryCellBackgroundColor")}
    
    
    /**
    Method that returns the travelFlightIconColor by accessing the Colors.plist
    
    - returns: UIColor
    */
    class func travelFlightIconColor() -> UIColor{return accessColorsPlist("travelFlightIconColor")}
    
    
    /**
    Method that returns the travelHotelIconColor by accessing the Colors.plist
    
    - returns: UIColor
    */
    class func travelHotelIconColor() -> UIColor{return accessColorsPlist("travelHotelIconColor")}
    
    
    /**
    Method that returns the travelMeetingIconColor by accessing the Colors.plist
    
    - returns: UIColor
    */
    class func travelMeetingIconColor() -> UIColor{return accessColorsPlist("travelMeetingIconColor")}
    
    
    /**
    Method that returns the travelEventIconColor by accessing the Colors.plist
    
    - returns: UIColor
    */
    class func travelEventIconColor() -> UIColor{return accessColorsPlist("travelEventIconColor")}
    
    
    /**
    Method that returns the travelTransitIconColor by accessing the Colors.plist
    
    - returns: UIColor
    */
    class func travelTransitIconColor() -> UIColor{return accessColorsPlist("travelTransitIconColor")}
    
    
    /**
    Method that returns the travelRestaurantIconColor by accessing the Colors.plist
    
    - returns: UIColor
    */
    class func travelRestaurantIconColor() -> UIColor{return self.accessColorsPlist("travelRestaurantIconColor")}
    
    
    /**
    Method that returns the travelItineraryRecommendationCardBackgroundColor by accessing the Colors.plist
    
    - returns: UIColor
    */
    class func travelItineraryRecommendationCardBackgroundColor() -> UIColor{return self.accessColorsPlist("travelItineraryRecommendationCardBackgroundColor")}
   
    
    /**
    Method that returns the travelAlertBodyColor by accessing the Colors.plist
    
    - returns: UIColor
    */
    class func travelAlertBodyColor() -> UIColor { return accessColorsPlist("travelAlertBodyColor") }
    
    
    /**
    Method that returns the travelAlertReviewButtonColorNormal by accessing the Colors.plist
    
    - returns: UIColor
    */
    class func travelAlertReviewButtonColorNormal() -> UIColor { return accessColorsPlist("travelAlertReviewButtonColorNormal") }
    
    
    /**
    Method that returns the travelAlertDismissButtonColorNormal by accessing the Colors.plist
    
    - returns: UIColor
    */
    class func travelAlertDismissButtonColorNormal() -> UIColor { return accessColorsPlist("travelAlertDismissButtonColorNormal") }
    
    
    /**
    Method that returns the travelBannerSuccessBackgroundColor by accessing the Colors.plist
    
    - returns: UIColor
    */
    class func travelBannerSuccessBackgroundColor() -> UIColor { return accessColorsPlist("travelBannerSuccessBackgroundColor") }
    
    
    /**
    Method that returns the travelBannerSuccessTextColor by accessing the Colors.plist
    
    - returns: UIColor
    */
    class func travelBannerSuccessTextColor() -> UIColor { return accessColorsPlist("travelBannerSuccessTextColor") }
    
    
    /**
    Method that returns the travelBannerFailureBackgroundColor by accessing the Colors.plist
    
    - returns: UIColor
    */
    class func travelBannerFailureBackgroundColor() -> UIColor { return accessColorsPlist("travelBannerFailureBackgroundColor") }
    
    
    /**
    Method that returns the travelBannerFailureTextColor by accessing the Colors.plist
    
    - returns: UIColor
    */
    class func travelBannerFailureTextColor() -> UIColor { return accessColorsPlist("travelBannerFailureTextColor") }
    
    
    /**
    Method that returns the travelNotificationsVCNavigationBarBottomLineColor by accessing the Colors.plist
    
    - returns: UIColor
    */
    class func travelNotificationsVCNavigationBarBottomLineColor() -> UIColor{ return accessColorsPlist("travelNotificationsVCNavigationBarBottomLineColor")}
    
    
    /**
    Method that accesses the color plist to return the correct UIColor that corresponds with the color String parameter
    
    - returns: UIColor
    */
    class func accessColorsPlist(color: String) -> UIColor! {
        
        var success = false
        var returnColor = UIColor.clearColor()
        
        if let path = NSBundle.mainBundle().pathForResource("Colors", ofType: "plist") {
            
            if let dict = NSDictionary(contentsOfFile: path) as? [String : String] {
                
                if let value = dict[color] {
                    
                    returnColor = UIColor(hex: value)
                    success = true
                }
            }
        }
        
        if !success {
            print("---\naccessUIColor Extension - ColorsPlist did not contain your color. Returning UIColor.clearColor().")
            print("Faulty Color: \(color)\n---")
        }
        
        return success ? returnColor : UIColor.clearColor()
    }
}

extension UIColor {
    
    /**
    Method called upon init that accepts a HEX string and creates a UIColor.
    
    - parameter hex:   String
    - parameter alpha: CGFloat
    
    - returns: UIColor
    */
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        
        var hexString = ""
                
        if hex.hasPrefix("#") {
            let nsHex = hex as NSString
            hexString = nsHex.substringFromIndex(1)
            
        } else {
            hexString = hex
        }
        
        let scanner = NSScanner(string: hexString)
        var hexValue: CUnsignedLongLong = 0
        if scanner.scanHexLongLong(&hexValue) {
            switch (hexString.characters.count) {
            case 3:
                red = CGFloat((hexValue & 0xF00) >> 8)       / 15.0
                green = CGFloat((hexValue & 0x0F0) >> 4)       / 15.0
                blue = CGFloat(hexValue & 0x00F)              / 15.0
            case 6:
                red = CGFloat((hexValue & 0xFF0000) >> 16)   / 255.0
                green = CGFloat((hexValue & 0x00FF00) >> 8)    / 255.0
                blue = CGFloat(hexValue & 0x0000FF)           / 255.0
            default:
                print("Invalid HEX string, number of characters after '#' should be either 3, 6", terminator: "")
            }
        } else {
            //MQALogger.log("Scan hex error")
        }
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
    
    static func colorWithRedValue(redValue: CGFloat, greenValue: CGFloat, blueValue: CGFloat, alpha: CGFloat) -> UIColor {
        return UIColor(red: redValue/255.0, green: greenValue/255.0, blue: blueValue/255.0, alpha: alpha)
    }
    
    /**
    Method called upon init that takes cyan, magenta, yellow, black, alpha and returns a UIColor
    
    - parameter cyan:    CGFloat
    - parameter magenta: CGFloat
    - parameter yellow:  CGFloat
    - parameter black:   CGFloat
    - parameter alpha:   CGFloat
    
    - returns: UIColor
    */
    convenience init?(cyan: CGFloat, magenta: CGFloat, yellow: CGFloat, black: CGFloat, alpha: CGFloat = 1.0){
        let cmykColorSpace = CGColorSpaceCreateDeviceCMYK()
        let colors = [cyan, magenta, yellow, black, alpha] // CMYK+Alpha
        let cgColor = CGColorCreate(cmykColorSpace, colors)
        self.init(CGColor: cgColor!)
    }
    
}