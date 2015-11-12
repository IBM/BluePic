/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import Foundation

extension Double{
    
    
    func roundToDecimalDigits(decimals:Int) -> Double
    {
        let a : Double = self
        let format : NSNumberFormatter = NSNumberFormatter()
        format.numberStyle = NSNumberFormatterStyle.DecimalStyle
        format.roundingMode = NSNumberFormatterRoundingMode.RoundHalfUp
        format.maximumFractionDigits = decimals
        let string: NSString = format.stringFromNumber(NSNumber(double: a))!
        return string.doubleValue
    }
    
    func formatToDecimalDigits(decimals:Int) -> String
    {
        let a : Double = self
        let format : NSNumberFormatter = NSNumberFormatter()
        format.numberStyle = NSNumberFormatterStyle.DecimalStyle
        format.roundingMode = NSNumberFormatterRoundingMode.RoundHalfUp
        format.maximumFractionDigits = decimals
        let string: NSString = format.stringFromNumber(NSNumber(double: a))!
        
        return string as String
    }
}