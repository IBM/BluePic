/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import Foundation


extension NSDate {
    
    /**
     Method returns a NSCalendar Unit
     
     - returns: NSCalendarUnit
     */
    private class func componentFlags() -> NSCalendarUnit { return NSCalendarUnit.Year.union(.Month).union(.Day).union(.WeekOfYear).union(.Hour).union(.Minute).union(.Second).union(.Weekday).union(.WeekdayOrdinal) }
    
    
    /**
     Method returns the components of the NSCalendar
     
     - parameter fromDate: NSDate
     
     - returns: NSDateComponents!
     */
    private class func components(fromDate fromDate: NSDate) -> NSDateComponents! {
        return NSCalendar.currentCalendar().components(NSDate.componentFlags(), fromDate: fromDate)
    }
    
    
    /**
     Method returns the NSDate components
     
     - returns: NSDateComponents
     */
    private func components() -> NSDateComponents  {
        return NSDate.components(fromDate: self)!
    }

    
    /**
     Method takes in a time interval since reference date and converts it to the number of seconds, minutes, hours, or weeks since the photo was taken
     
     - parameter timeInterval: NSTimeInterval
     
     - returns: String
     */
    class func timeStringSinceIntervalSinceReferenceDate(timeInterval : NSTimeInterval) -> String{
    
        let postedDate = NSDate(timeIntervalSinceReferenceDate: timeInterval)

        return timeSinceDateString(postedDate)
    
    }
    

    /**
     Method returns the number of years since the date parameter
     
     - parameter date: NSDate
     
     - returns: Int
     */
    private class func yearsFrom(date:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Year, fromDate: date, toDate: NSDate(), options: []).year
    }
    
    
    /**
     Method returns the number of months since the date parameter
     
     - parameter date: NSDate
     
     - returns: Int
     */
    private class func monthsFrom(date:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Month, fromDate: date, toDate: NSDate(), options: []).month
    }
    
    
    /**
     Method returns the number of weeks since the date parameter
     
     - parameter date: NSDate
     
     - returns: Int
     */
    private class func weeksFrom(date:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.WeekOfYear, fromDate: date, toDate: NSDate(), options: []).weekOfYear
    }
    
    
    /**
     Method returns the number of days since the date parameter
     
     - parameter date: NSDate
     
     - returns: Int
     */
    private class func daysFrom(date:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Day, fromDate: date, toDate: NSDate(), options: []).day
    }
    
    
    /**
     Method returns the number of hours since the date parameter
     
     - parameter date: NSDate
     
     - returns: Int
     */
    private class func hoursFrom(date:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Hour, fromDate: date, toDate: NSDate(), options: []).hour
    }
    
    
    /**
     Method returns the number of minutes since the date parameter
     
     - parameter date: NSDate
     
     - returns: Int
     */
    private class func minutesFrom(date:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Minute, fromDate: date, toDate: NSDate(), options: []).minute
    }
    
    
    /**
     Method returns the number of seconds since the date parameter
     
     - parameter date: NSDate
     
     - returns: Int
     */
    private class func secondsFrom(date:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Second, fromDate: date, toDate: NSDate(), options: []).second
    }
    
    
    /**
     Method returns the time since the data parameter as a string
     
     - parameter date: NSDate
     
     - returns: String
     */
    private class func timeSinceDateString(date:NSDate) -> String {
        if weeksFrom(date)   > 0 { return "\(weeksFrom(date))w"   }
        if daysFrom(date)    > 0 { return "\(daysFrom(date))d"    }
        if hoursFrom(date)   > 0 { return "\(hoursFrom(date))h"   }
        if minutesFrom(date) > 0 { return "\(minutesFrom(date))m" }
        if secondsFrom(date) > 0 { return "\(secondsFrom(date))s" }
        return "now"
    }

}
