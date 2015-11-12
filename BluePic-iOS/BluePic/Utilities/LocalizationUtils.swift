/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import UIKit

/**
*  Useful methods specifically for localization
*/
class LocalizationUtils: NSObject {
    
    /**
    Takes a double value and returns a string representing the value using the user's locale
    
    - parameter amount: A Double amount for a currency
    
    - returns: The value using the user's locale
    */
    class func localizeCurrency(amount: Double) -> String {
        let currencyFormatter = NSNumberFormatter()
        currencyFormatter.locale = NSLocale.currentLocale()
        currencyFormatter.maximumFractionDigits = 2
        currencyFormatter.minimumFractionDigits = 2
        currencyFormatter.alwaysShowsDecimalSeparator = true
        currencyFormatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
        
        return currencyFormatter.stringFromNumber(amount)!
        
    }
    
    
    /**
    Method returns the localized currency symbol which is hard coded to "€"
    
    - returns: String
    */
    class func getLocalizedCurrencySymbol() -> String {
        return "€"
    }
    
    
    /**
    Takes an NSDate for time and converts it to a localized string (either 12 or 24 hour format)
    
    - parameter time: time to convert to localized string
    
    - returns: A string representing the localized time
    */
    class func localizeTime(time: NSDate) -> String {
        let locale = NSLocale.currentLocale()
        let dateFormat = NSDateFormatter.dateFormatFromTemplate("j", options: 0, locale: locale)!
        
        if dateFormat.rangeOfString("a") != nil { //12 hour time
            return time.localizedStringTime()
        } else { //24 hour time
            return time.localizedStringTime()
        }
    }
    
}
