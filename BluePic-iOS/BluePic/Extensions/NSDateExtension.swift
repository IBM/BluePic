/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation

extension Date {

    /**
     Method returns a NSCalendar Unit

     - returns: NSCalendarUnit
     */
    fileprivate static func componentFlags() -> NSCalendar.Unit {
        return NSCalendar.Unit.year.union(.month).union(.day).union(.weekOfYear).union(.hour).union(.minute).union(.second).union(.weekday).union(.weekdayOrdinal)
    }

    /**
     Method returns the components of the NSCalendar

     - parameter fromDate: NSDate

     - returns: NSDateComponents
     */
    fileprivate static func components(fromDate: Date) -> DateComponents {
        return (Calendar.current as NSCalendar).components(Date.componentFlags(), from: fromDate)
    }

    /**
     Method returns the NSDate components

     - returns: NSDateComponents
     */
    fileprivate func components() -> DateComponents {
        return Date.components(fromDate: self)
    }

    /**
     Method takes in a time interval since reference date and converts it to the number of seconds, minutes, hours, or weeks since the photo was taken

     - parameter timeInterval: NSTimeInterval

     - returns: String
     */
    static func timeStringSinceIntervalSinceReferenceDate(_ timeInterval: TimeInterval) -> String {

        let postedDate = Date(timeIntervalSinceReferenceDate: timeInterval)

        return timeSinceDateString(postedDate)

    }

    /**
     Method returns the number of years since the date parameter

     - parameter date: NSDate

     - returns: Int
     */
    fileprivate static func yearsFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.year, from: date, to: Date(), options: []).year!
    }

    /**
     Method returns the number of months since the date parameter

     - parameter date: NSDate

     - returns: Int
     */
    fileprivate static func monthsFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.month, from: date, to: Date(), options: []).month!
    }

    /**
     Method returns the number of weeks since the date parameter

     - parameter date: NSDate

     - returns: Int
     */
    fileprivate static func weeksFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.weekOfYear, from: date, to: Date(), options: []).weekOfYear!
    }

    /**
     Method returns the number of days since the date parameter

     - parameter date: NSDate

     - returns: Int
     */
    fileprivate static func daysFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.day, from: date, to: Date(), options: []).day!
    }

    /**
     Method returns the number of hours since the date parameter

     - parameter date: NSDate

     - returns: Int
     */
    fileprivate static func hoursFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.hour, from: date, to: Date(), options: []).hour!
    }

    /**
     Method returns the number of minutes since the date parameter

     - parameter date: NSDate

     - returns: Int
     */
    fileprivate static func minutesFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.minute, from: date, to: Date(), options: []).minute!
    }

    /**
     Method returns the number of seconds since the date parameter

     - parameter date: NSDate

     - returns: Int
     */
    fileprivate static func secondsFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.second, from: date, to: Date(), options: []).second!
    }

    /**
     Method returns the time since the data parameter as a string

     - parameter date: NSDate

     - returns: String
     */
    static func timeSinceDateString(_ date: Date) -> String {
        if weeksFrom(date)   > 0 { return "\(weeksFrom(date))" + NSLocalizedString("w", comment: "first letter of the word week")}
        if daysFrom(date)    > 0 { return "\(daysFrom(date))" +  NSLocalizedString("d", comment: "first letter of the word day")}
        if hoursFrom(date)   > 0 { return "\(hoursFrom(date))" +  NSLocalizedString("h", comment: "first letter of the word hour")}
        if minutesFrom(date) > 0 { return "\(minutesFrom(date))" +  NSLocalizedString("m", comment: "first letter of the word minutes")}
        if secondsFrom(date) > 0 { return "\(secondsFrom(date))" +  NSLocalizedString("s", comment: "first letter of the word seconds")}
        return NSLocalizedString("now", comment: "word representing this moment in time")
    }
}
