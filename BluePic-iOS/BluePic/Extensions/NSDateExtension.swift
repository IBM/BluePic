/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import Foundation

enum DateFormat {
    case ISO8601, DotNet, RSS, AltRSS
    case Custom(String)
}

extension NSDate {
    
    // MARK: Intervals In Seconds
    private class func miliToSecondsMultiplier() -> Double { return 0.001 }
    private class func minuteInSeconds() -> Double { return 60 }
    private class func hourInSeconds() -> Double { return 3600 }
    private class func dayInSeconds() -> Double { return 86400 }
    private class func weekInSeconds() -> Double { return 604800 }
    private class func yearInSeconds() -> Double { return 31556926 }
    
    // MARK: Components
    private class func componentFlags() -> NSCalendarUnit { return NSCalendarUnit.Year.union(.Month).union(.Day).union(.WeekOfYear).union(.Hour).union(.Minute).union(.Second).union(.Weekday).union(.WeekdayOrdinal) }
    
    private class func components(fromDate fromDate: NSDate) -> NSDateComponents! {
        return NSCalendar.currentCalendar().components(NSDate.componentFlags(), fromDate: fromDate)
    }
    
    private func components() -> NSDateComponents  {
        return NSDate.components(fromDate: self)!
    }
    
    // MARK: Date From String
    
    convenience init(fromString string: String, format:DateFormat)
    {
        if string.isEmpty {
            self.init()
            return
        }
        
        let string = string as NSString
        
        switch format {
            
        case .DotNet:
            
            // Expects "/Date(1268123281843)/"
            let startIndex = string.rangeOfString("(").location + 1
            let endIndex = string.rangeOfString(")").location
            let range = NSRange(location: startIndex, length: endIndex-startIndex)
            let milliseconds = (string.substringWithRange(range) as NSString).longLongValue
            let interval = NSTimeInterval(milliseconds / 1000)
            self.init(timeIntervalSince1970: interval)
            
        case .ISO8601:
            
            var s = string
            if string.hasSuffix(" 00:00") {
                s = s.substringToIndex(s.length-6) + "GMT"
            } else if string.hasSuffix("Z") {
                s = s.substringToIndex(s.length-1) + "GMT"
            }
            let formatter = NSDateFormatter()
            formatter.locale = NSLocale.currentLocale()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"
            if let date = formatter.dateFromString(string as String) {
                self.init(timeInterval:0, sinceDate:date)
            } else {
                self.init()
            }
            
        case .RSS:
            
            var s  = string
            if string.hasSuffix("Z") {
                s = s.substringToIndex(s.length-1) + "GMT"
            }
            let formatter = NSDateFormatter()
            formatter.locale = NSLocale.currentLocale()
            formatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss ZZZ"
            if let date = formatter.dateFromString(string as String) {
                self.init(timeInterval:0, sinceDate:date)
            } else {
                self.init()
            }
            
        case .AltRSS:
            
            var s  = string
            if string.hasSuffix("Z") {
                s = s.substringToIndex(s.length-1) + "GMT"
            }
            let formatter = NSDateFormatter()
            formatter.locale = NSLocale.currentLocale()
            formatter.dateFormat = "d MMM yyyy HH:mm:ss ZZZ"
            if let date = formatter.dateFromString(string as String) {
                self.init(timeInterval:0, sinceDate:date)
            } else {
                self.init()
            }
            
        case .Custom(let dateFormat):
            
            let formatter = NSDateFormatter()
            formatter.locale = NSLocale.currentLocale()
            formatter.dateFormat = dateFormat
            if let date = formatter.dateFromString(string as String) {
                self.init(timeInterval:0, sinceDate:date)
            } else {
                self.init()
            }
        }
    }
    
    
    
    // MARK: Comparing Dates
    
    func isEqualToDateIgnoringTime(date: NSDate) -> Bool
    {
        let comp1 = NSDate.components(fromDate: self)
        let comp2 = NSDate.components(fromDate: date)
        return ((comp1.year == comp2.year) && (comp1.month == comp2.month) && (comp1.day == comp2.day))
    }
    
    func isToday() -> Bool
    {
        return isEqualToDateIgnoringTime(NSDate())
    }
    
    func isTomorrow() -> Bool
    {
        return isEqualToDateIgnoringTime(NSDate().dateByAddingDays(1))
    }
    
    func isYesterday() -> Bool
    {
        return isEqualToDateIgnoringTime(NSDate().dateBySubtractingDays(1))
    }
    
    func isSameWeekAsDate(date: NSDate) -> Bool
    {
        let comp1 = NSDate.components(fromDate: self)
        let comp2 = NSDate.components(fromDate: date)
        // Must be same week. 12/31 and 1/1 will both be week "1" if they are in the same week
        if comp1.weekOfYear != comp2.weekOfYear {
            return false
        }
        // Must have a time interval under 1 week
        return abs(timeIntervalSinceDate(date)) < NSDate.weekInSeconds()
    }
    

        func localizedStringTime()->String {
            return NSDateFormatter.localizedStringFromDate(self, dateStyle: NSDateFormatterStyle.NoStyle, timeStyle: NSDateFormatterStyle.ShortStyle)
        }

    
    func isThisWeek() -> Bool
    {
        return isSameWeekAsDate(NSDate())
    }
    
    func isNextWeek() -> Bool
    {
        let interval: NSTimeInterval = NSDate().timeIntervalSinceReferenceDate + NSDate.weekInSeconds()
        let date = NSDate(timeIntervalSinceReferenceDate: interval)
        return isSameYearAsDate(date)
    }
    
    func isLastWeek() -> Bool
    {
        let interval: NSTimeInterval = NSDate().timeIntervalSinceReferenceDate - NSDate.weekInSeconds()
        let date = NSDate(timeIntervalSinceReferenceDate: interval)
        return isSameYearAsDate(date)
    }
    
    func isSameYearAsDate(date: NSDate) -> Bool
    {
        let comp1 = NSDate.components(fromDate: self)
        let comp2 = NSDate.components(fromDate: date)
        return (comp1.year == comp2.year)
    }
    
    func isThisYear() -> Bool
    {
        return isSameYearAsDate(NSDate())
    }
    
    func isNextYear() -> Bool
    {
        let comp1 = NSDate.components(fromDate: self)
        let comp2 = NSDate.components(fromDate: NSDate())
        return (comp1.year == comp2.year + 1)
    }
    
    func isLastYear() -> Bool
    {
        let comp1 = NSDate.components(fromDate: self)
        let comp2 = NSDate.components(fromDate: NSDate())
        return (comp1.year == comp2.year - 1)
    }
    
    func isEarlierThanDate(date: NSDate) -> Bool
    {
        return earlierDate(date) == self
    }
    
    func isLaterThanDate(date: NSDate) -> Bool
    {
        return laterDate(date) == self
    }
    
    // MARK: Worklight Bug Fix
    func getTime() -> NSTimeInterval {
        return timeIntervalSince1970
    }
    
    // MARK: Adjusting Dates
    
    func dateByAddingDays(days: Int) -> NSDate
    {
        let interval: NSTimeInterval = timeIntervalSinceReferenceDate + NSDate.dayInSeconds() * Double(days)
        return NSDate(timeIntervalSinceReferenceDate: interval)
    }
    
    func dateBySubtractingDays(days: Int) -> NSDate
    {
        let interval: NSTimeInterval = timeIntervalSinceReferenceDate - NSDate.dayInSeconds() * Double(days)
        return NSDate(timeIntervalSinceReferenceDate: interval)
    }
    
    func dateByAddingHours(hours: Int) -> NSDate
    {
        let interval: NSTimeInterval = timeIntervalSinceReferenceDate + NSDate.hourInSeconds() * Double(hours)
        return NSDate(timeIntervalSinceReferenceDate: interval)
    }
    
    func dateBySubtractingHours(hours: Int) -> NSDate
    {
        let interval: NSTimeInterval = timeIntervalSinceReferenceDate - NSDate.hourInSeconds() * Double(hours)
        return NSDate(timeIntervalSinceReferenceDate: interval)
    }
    
    func dateByAddingMinutes(minutes: Int) -> NSDate
    {
        let interval: NSTimeInterval = timeIntervalSinceReferenceDate + NSDate.minuteInSeconds() * Double(minutes)
        return NSDate(timeIntervalSinceReferenceDate: interval)
    }
    
    func dateByAddingMiliSeconds(miliSeconds: Int) -> NSDate
    {
        let interval: NSTimeInterval = timeIntervalSinceReferenceDate + NSDate.miliToSecondsMultiplier() * Double(miliSeconds)
        return NSDate(timeIntervalSinceReferenceDate: interval)
    }
    
    func dateBySubtractingMinutes(minutes: Int) -> NSDate
    {
        let interval: NSTimeInterval = timeIntervalSinceReferenceDate - NSDate.minuteInSeconds() * Double(minutes)
        return NSDate(timeIntervalSinceReferenceDate: interval)
    }
    
    func dateAtStartOfDay() -> NSDate
    {
        let comps = components()
        comps.hour = 0
        comps.minute = 0
        comps.second = 0
        return NSCalendar.currentCalendar().dateFromComponents(comps)!
    }
    
    func dateAtEndOfDay() -> NSDate
    {
        let comps = components()
        comps.hour = 23
        comps.minute = 59
        comps.second = 59
        return NSCalendar.currentCalendar().dateFromComponents(comps)!
    }
    
    func dateAtStartOfWeek() -> NSDate
    {
        let flags :NSCalendarUnit = [.Year, .Month, .WeekOfYear, .Weekday]
        let components = NSCalendar.currentCalendar().components(flags, fromDate: self)
        components.weekday = 1 // Sunday
        components.hour = 0
        components.minute = 0
        components.second = 0
        return NSCalendar.currentCalendar().dateFromComponents(components)!
    }
    
    func dateAtEndOfWeek() -> NSDate
    {
        let flags :NSCalendarUnit = [.Year, .Month, .WeekOfYear, .Weekday]
        let components = NSCalendar.currentCalendar().components(flags, fromDate: self)
        components.weekday = 7 // Sunday
        components.hour = 0
        components.minute = 0
        components.second = 0
        return NSCalendar.currentCalendar().dateFromComponents(components)!
    }
    
    
    // MARK: Retrieving Intervals
    
    func minutesAfterDate(date: NSDate) -> Int
    {
        let interval = timeIntervalSinceDate(date)
        return Int(interval / NSDate.minuteInSeconds())
    }
    
    func minutesBeforeDate(date: NSDate) -> Int
    {
        let interval = date.timeIntervalSinceDate(self)
        return Int(interval / NSDate.minuteInSeconds())
    }
    
    func hoursAfterDate(date: NSDate) -> Int
    {
        let interval = timeIntervalSinceDate(date)
        return Int(interval / NSDate.hourInSeconds())
    }
    
    func hoursBeforeDate(date: NSDate) -> Int
    {
        let interval = date.timeIntervalSinceDate(self)
        return Int(interval / NSDate.hourInSeconds())
    }
    
    func daysAfterDate(date: NSDate) -> Int
    {
        let interval = timeIntervalSinceDate(date)
        return Int(interval / NSDate.dayInSeconds())
    }
    
    func daysBeforeDate(date: NSDate) -> Int
    {
        let interval = date.timeIntervalSinceDate(self)
        return Int(interval / NSDate.dayInSeconds())
    }
    
    
    // MARK: Decomposing Dates
    
    func nearestHour () -> Int {
        let halfHour = NSDate.minuteInSeconds() * 30
        var interval = timeIntervalSinceReferenceDate
        if  seconds() < 30 {
            interval -= halfHour
        } else {
            interval += halfHour
        }
        let date = NSDate(timeIntervalSinceReferenceDate: interval)
        return date.hour()
    }
    
    func year () -> Int { return components().year  }
    func month () -> Int { return components().month }
    func week () -> Int { return components().weekOfYear }
    func day () -> Int { return components().day }
    func hour () -> Int { return components().hour }
    func minute () -> Int { return components().minute }
    func seconds () -> Int { return components().second }
    func weekday () -> Int { return components().weekday }
    func nthWeekday () -> Int { return components().weekdayOrdinal } //// e.g. 2nd Tuesday of the month is 2
    func monthDays () -> Int { return NSCalendar.currentCalendar().rangeOfUnit(.Day, inUnit: .Month, forDate: self).length }
    func firstDayOfWeek () -> Int {
        let distanceToStartOfWeek = NSDate.dayInSeconds() * Double(components().weekday - 1)
        let interval: NSTimeInterval = timeIntervalSinceReferenceDate - distanceToStartOfWeek
        return NSDate(timeIntervalSinceReferenceDate: interval).day()
    }
    func lastDayOfWeek () -> Int {
        let distanceToStartOfWeek = NSDate.dayInSeconds() * Double(components().weekday - 1)
        let distanceToEndOfWeek = NSDate.dayInSeconds() * Double(7)
        let interval: NSTimeInterval = timeIntervalSinceReferenceDate - distanceToStartOfWeek + distanceToEndOfWeek
        return NSDate(timeIntervalSinceReferenceDate: interval).day()
    }
    func isWeekday() -> Bool {
        return !isWeekend()
    }
    func isWeekend() -> Bool {
        let range = NSCalendar.currentCalendar().maximumRangeOfUnit(NSCalendarUnit.Weekday)
        return (weekday() == range.location || weekday() == range.length)
    }
    
    
    // MARK: To String
    
    func toString() -> String {
        return toString(dateStyle: .ShortStyle, timeStyle: .ShortStyle, doesRelativeDateFormatting: false)
    }
    
    func toString(format format: DateFormat) -> String
    {
        let dateFormat: String
        switch format {
        case .DotNet:
            let offset = NSTimeZone.defaultTimeZone().secondsFromGMT / 3600
            let nowMillis = 1000 * timeIntervalSince1970
            return  "/Date(\(nowMillis)\(offset))/"
        case .ISO8601:
            dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        case .RSS:
            dateFormat = "EEE, d MMM yyyy HH:mm:ss ZZZ"
        case .AltRSS:
            dateFormat = "d MMM yyyy HH:mm:ss ZZZ"
        case .Custom(let string):
            dateFormat = string
        }
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale.currentLocale()
        formatter.dateFormat = dateFormat
        return formatter.stringFromDate(self)
    }
    
    func toString(dateStyle dateStyle: NSDateFormatterStyle, timeStyle: NSDateFormatterStyle, doesRelativeDateFormatting: Bool = false) -> String
    {
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale.currentLocale()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        formatter.doesRelativeDateFormatting = doesRelativeDateFormatting
        return formatter.stringFromDate(self)
    }
    
    func relativeTimeToString() -> String
    {
        let time = timeIntervalSince1970
        let now = NSDate().timeIntervalSince1970
        
        let seconds = now - time
        let minutes = round(seconds/60)
        let hours = round(minutes/60)
        let days = round(hours/24)
        
        if seconds < 10 {
            return NSLocalizedString("just now", comment: "relative time")
        } else if seconds < 60 {
            return NSLocalizedString("\(Int(seconds)) seconds ago", comment: "relative time")
        }
        
        if minutes < 60 {
            if minutes == 1 {
                return NSLocalizedString("1 minute ago", comment: "relative time")
            } else {
                return NSLocalizedString("\(Int(minutes)) minutes ago", comment: "relative time")
            }
        }
        
        if hours < 24 {
            if hours == 1 {
                return NSLocalizedString("1 hour ago", comment: "relative time")
            } else {
                return NSLocalizedString("\(Int(hours)) hours ago", comment: "relative time")
            }
        }
        
        if days < 7 {
            if days == 1 {
                return NSLocalizedString("1 day ago", comment: "relative time")
            } else {
                return NSLocalizedString("\(Int(days)) days ago", comment: "relative time")
            }
        }
        
        return toString()
    }
    
    
    func weekdayToString() -> String {
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale.currentLocale()
        return formatter.weekdaySymbols[weekday()-1] 
    }
    
    func shortWeekdayToString() -> String {
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale.currentLocale()
        return formatter.shortWeekdaySymbols[weekday()-1] 
    }
    
    func veryShortWeekdayToString() -> String {
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale.currentLocale()
        return formatter.veryShortWeekdaySymbols[weekday()-1] 
    }
    
    func monthToString() -> String {
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale.currentLocale()
        return formatter.monthSymbols[month()-1] 
    }
    
    func shortMonthToString() -> String {
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale.currentLocale()
        return formatter.shortMonthSymbols[month()-1] 
    }
    
    func veryShortMonthToString() -> String {
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale.currentLocale()
        return formatter.veryShortMonthSymbols[month()-1] 
    }
    
    
    /**
    This adds a new method dateAt to NSDate.
    
    It returns a new date at the specified hours and minutes of the receiver
    
    - parameter hours:: The hours value
    - parameter minutes:: The new minutes
    
    - returns: a new NSDate with the same year/month/day as the receiver, but with the specified hours/minutes values
    */
    func dateAt(hours hours: Int, minutes: Int) -> NSDate
    {
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        
        //get the month/day/year componentsfor today's date.
        
        
        let date_components = calendar.components(
            [NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day],
            fromDate: self)
        
        //Create an NSDate for 8:00 AM today.
        date_components.hour = hours
        date_components.minute = minutes
        date_components.second = 0
        
        let newDate = calendar.dateFromComponents(date_components)!
        return newDate
    }
    
    
    /**
    Method that converts a date represented as milliseconds since 1970 to a NSDate
    
    - parameter milliseconds: NSTimeInterval
    
    - returns: NSDate
    */
    class func convertMillisecondsSince1970ToNSDate(milliseconds : NSTimeInterval) -> NSDate{
        
        let seconds = milliseconds / 1000.0
        
        let date = NSDate(timeIntervalSince1970: seconds)
        
        return date
    }
    
    
    /**
    Method that converts a date represented as milliseconds since 1970 to a string of format "21 Aug"
    
    - parameter milliseconds: NSTimeInterval
    
    - returns: String
    */
    class func convertMillisecondsSince1970ToDateStringWithDayAndMonth(milliseconds : NSTimeInterval) -> String{
        let date = self.convertMillisecondsSince1970ToNSDate(milliseconds)
        
        return self.getDateStringWithDayAndMonth(date)
    }
    
    
    /**
    Method that converts a date represented as milliseconds since 1970 to a string of format "Mon"
    
    - parameter milliseconds: NSTimeInterval
    
    - returns: String
    */
    class func convertMillisecondsSince1970ToDayOfTheWeekString(milliseconds : NSTimeInterval) -> String {
        
        let date = self.convertMillisecondsSince1970ToNSDate(milliseconds)
        
        return self.getDateStringWithDayOfWeek(date)
    }
    
    
    /**
    Method that converts a date represented as milliseconds since 1970 to a string in the format of "HH:MM"
    
    - parameter milliseconds: NSTimeInterval
    
    - returns: String
    */
    class func convertMillisecondsSince1970ToDateWithTimeOfDay(milliseconds : NSTimeInterval) -> String{
        
        let date = self.convertMillisecondsSince1970ToNSDate(milliseconds)
        
        return self.getDateStringWithTimeOfDay(date)
        
    }
    
    
    /**
    Method that converts a date represented as milliseconds since 1970 to a string in the format of "13:00, 21 Sept"
    
    - parameter milliseconds: NSTimeInterval
    
    - returns: String
    */
    class func convertMillisecondsSince1970ToTimeOfDayThenDayOfMonthThenMonth(milliseconds : NSTimeInterval)->String{
        
        let date = self.convertMillisecondsSince1970ToNSDate(milliseconds)
        
        return self.getDateStringWithTimeOfDayThenDayOfMonthThenMonth(date)
        
    }
    
    
    /**
    Method that converts a date represented as milliseconds since 1970 to a string in the format of "Mon, 21 Aug"
    
    - parameter milliseconds: NSTimeInterval
    
    - returns: String
    */
    class func convertMillisecondsSince1970ToDayOfWeekDayAndMonth(milliseconds : NSTimeInterval) -> String {
        let date = self.convertMillisecondsSince1970ToNSDate(milliseconds)
        
        return self.getDateStringWithDayOfWeekDayAndMonth(date)
        
    }
    
    
    /**
    Method that converts a date represented as milliseconds since 1970 to a string in the format of "Monday, 21 Aug"
    
    - parameter milliseconds: NSTimeInterval
    
    - returns: String
    */
    class func convertMillisecondsSince1970ToFullDayOfWeekDayAndMonth(milliseconds : NSTimeInterval) -> String {
        let date = self.self.convertMillisecondsSince1970ToNSDate(milliseconds)
        
        return self.getDateStringWithFullDayOfWeekDayAndMonth(date)
        
    }
    
    
    /**
    Method that converts two dates represented as milliseconds since 1970, to the number of days between these dates
    
    - parameter startMilliseconds: NSTimeInterval
    - parameter endMilliseconds:   NSTimeInterval
    
    - returns: Int
    */
    class func convertStartAndEndMillisecondsSince1970ToNumberOfDays(startMilliseconds : NSTimeInterval, endMilliseconds : NSTimeInterval) -> Int{
        
        let startDate = self.convertMillisecondsSince1970ToNSDate(startMilliseconds)
        
        let endDate = self.convertMillisecondsSince1970ToNSDate(endMilliseconds)
        
        return self.daysBetweenDate(startDate, endDate: endDate)
    }
    
    
    
    /**
    Method that returns the number of days between two NSDates
    
    - parameter startDate: NSDate
    - parameter endDate:   NSDate
    
    - returns: Int
    */
    class func daysBetweenDate(startDate: NSDate, endDate: NSDate) -> Int
    {
        let calendar = NSCalendar.currentCalendar()
        
        let components = calendar.components([.Day], fromDate: startDate, toDate: endDate, options: [])
        
        return components.day
    }
    
    
    
    /**
    Method that returns the number of minutes between two dates represented as milliseconds since 1970
    
    - parameter start: NSTimeInterval
    - parameter end:   NSTimeInterval
    
    - returns: NSTimeInterval
    */
    class func minutesBetweenDates(start: NSTimeInterval, end: NSTimeInterval) -> NSTimeInterval
    {
        
        let startDate = convertMillisecondsSince1970ToNSDate(start)
        let endDate = convertMillisecondsSince1970ToNSDate(end)
        
        let interval = endDate.timeIntervalSinceDate(startDate)
        
        let numberOfSecondsInAMinute : NSTimeInterval = 60
        
        return interval/numberOfSecondsInAMinute
        
    }
    
    
    
    /**
    Method that returns the number of nights between two dates represented as milliseconds since 1970
    
    - parameter start: NSTimeInterval
    - parameter end:   NSTimeInterval
    
    - returns: NSTimeInterval
    */
    class func nightsBetweenDates(start: NSTimeInterval, end: NSTimeInterval) -> NSTimeInterval
    {
        
        let startDate = convertMillisecondsSince1970ToNSDate(start)
        let endDate = convertMillisecondsSince1970ToNSDate(end)
        
        let interval = endDate.timeIntervalSinceDate(startDate)
        
        let numberOfSecondsInADay : NSTimeInterval = 86400
        
        return ceil(interval/numberOfSecondsInADay)
        
    }
    
    
    /**
    Method that takes in an NSDate and the number of days after this NSDate as parameters and returns the correct NSDate that is that many days after the NSDate parameter
    
    - parameter date:      NSDate
    - parameter daysAfter: Int
    
    - returns: NSDate
    */
    class func getDateForNumberDaysAfterDate(date: NSDate, daysAfter: Int)->NSDate {
        let components: NSDateComponents = NSDateComponents()
        components.setValue(daysAfter, forComponent: NSCalendarUnit.Day);
        let daysAfterDate = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: date, options: NSCalendarOptions(rawValue: 0))
        return daysAfterDate!
    }
    
    
    /**
    Method used to convert a NSDate to a string of format "Mon"
    
    - parameter date: NSDate
    
    - returns: String
    */
    class func getDateStringWithDayOfWeek(date : NSDate) -> String {
        let dayTimePeriodFormatter = NSDateFormatter()
        dayTimePeriodFormatter.dateFormat = "E"
        dayTimePeriodFormatter.timeZone = NSTimeZone(name: "GMT")
        
        let dateString = dayTimePeriodFormatter.stringFromDate(date)
        return dateString
    }
    
    
    /**
    Method used to convert a NSDare to string of format "Mon, 21 Aug"
    
    - parameter date: NSDate
    
    - returns: String
    */
    class func getDateStringWithDayOfWeekDayAndMonth(date: NSDate)->String {
        let dayTimePeriodFormatter = NSDateFormatter()
        dayTimePeriodFormatter.dateFormat = "E, d MMM"
        dayTimePeriodFormatter.timeZone = NSTimeZone(name: "GMT")
        
        let dateString = dayTimePeriodFormatter.stringFromDate(date)
        return dateString
    }
    
    
    /**
    Method used to convert a NSDate to a string of format "Monday, 21 Aug"
    
    - parameter date: NSDate
    
    - returns: String
    */
    class func getDateStringWithFullDayOfWeekDayAndMonth(date : NSDate) -> String {
        let dayTimePeriodFormatter = NSDateFormatter()
        dayTimePeriodFormatter.dateFormat = "EEEE, d MMM"
        dayTimePeriodFormatter.timeZone = NSTimeZone(name: "GMT")
        
        let dateString = dayTimePeriodFormatter.stringFromDate(date)
        return dateString
    }
    
    
    
    /**
    Method used to convert an NSDate to a string of format "21 Aug"
    
    - parameter date: NSDate
    
    - returns: String
    */
    class func getDateStringWithDayAndMonth(date: NSDate)->String {
        let dayTimePeriodFormatter = NSDateFormatter()
        dayTimePeriodFormatter.dateFormat = "d MMM"
        dayTimePeriodFormatter.timeZone = NSTimeZone(name: "GMT")
        
        let dateString = dayTimePeriodFormatter.stringFromDate(date)
        return dateString
    }
    
    
    /**
    Method used to convert NSDate to string of format 21 Aug, 2015"
    
    - parameter date: NSDate
    
    - returns: String
    */
    class func getDateStringWithDayMonthAndYear(date: NSDate)->String {
        let dayTimePeriodFormatter = NSDateFormatter()
        dayTimePeriodFormatter.dateFormat = "d MMM, yyyy"
        dayTimePeriodFormatter.timeZone = NSTimeZone(name: "GMT")
        
        let dateString = dayTimePeriodFormatter.stringFromDate(date)
        return dateString
    }
    
    
    
    /**
    Method used to convert a NSDate to a string of format "HH:MM"
    
    - parameter date: NSDate
    
    - returns: String
    */
    class func getDateStringWithTimeOfDay(date : NSDate)-> String {
        
        let dayTimePeriodFormatter = NSDateFormatter()
        dayTimePeriodFormatter.dateFormat = "HH:mm"
        dayTimePeriodFormatter.locale = NSLocale(localeIdentifier: "de-dE")
            
        dayTimePeriodFormatter.timeZone = NSTimeZone(name: "GMT")
        
        let dateString = dayTimePeriodFormatter.stringFromDate(date)
        return dateString
    }
    
    
    /**
    Method used to convert a NSDate to a string of format "13:00, 21 Sept"
    
    - parameter date: NSDate
    
    - returns: String
    */
    class func getDateStringWithTimeOfDayThenDayOfMonthThenMonth(date : NSDate)->String{
        
        let dayTimePeriodFormatter = NSDateFormatter()
        dayTimePeriodFormatter.dateFormat = "HH:mm, d MMM"
        
        dayTimePeriodFormatter.timeZone = NSTimeZone(name: "GMT")
        
        let dateString = dayTimePeriodFormatter.stringFromDate(date)
        return dateString
        
    }

    
    
    
}
//-------------------------------------------------------------
//Tell the system that NSDates can be compared with ==, >, >=, <, and <= operators
extension NSDate: Comparable {}

//-------------------------------------------------------------
//Define the global operators for the
//Equatable and Comparable protocols for comparing NSDates

public func ==(lhs: NSDate, rhs: NSDate) -> Bool
{
    return lhs.timeIntervalSince1970 == rhs.timeIntervalSince1970
}

public func <(lhs: NSDate, rhs: NSDate) -> Bool
{
    return lhs.timeIntervalSince1970 < rhs.timeIntervalSince1970
}
public func >(lhs: NSDate, rhs: NSDate) -> Bool
{
    return lhs.timeIntervalSince1970 > rhs.timeIntervalSince1970
}
public func <=(lhs: NSDate, rhs: NSDate) -> Bool
{
    return lhs.timeIntervalSince1970 <= rhs.timeIntervalSince1970
}
public func >=(lhs: NSDate, rhs: NSDate) -> Bool
{
    return lhs.timeIntervalSince1970 >= rhs.timeIntervalSince1970

//-------------------------------------------------------------
    
    
}