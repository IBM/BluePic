/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import Foundation


extension String {
    
    var length:Int {return self.characters.count}
    
    func containsString(s: String) -> Bool {
        
        return rangeOfString(s) != nil
        
    }
    
    func containsString(s: String, compareOption: NSStringCompareOptions) -> Bool {
    
        return (rangeOfString(s, options: compareOption)) != nil
        
    }
    
    func reverse() -> String {
        
        var reverseString : String = ""
        
        for character in self.characters {
            
            reverseString = "\(character)\(reverseString)"
        
        }
        
        return reverseString
    
    }
    
    
    

    /**
    
    Extract a **String** prior to the first "@" character
    
    */
    func getUserIdFromEmail() -> String? {
        
        if let range = rangeOfString("@") {
            
            let startRange = Range<String.Index>(
                start: startIndex,
                end: range.startIndex
            )
            
            return substringWithRange(startRange)
            
        } else {
            return nil
        }
    }
    
    func lowercaseFirstLetterString() -> String {
        return stringByReplacingCharactersInRange(startIndex...startIndex, withString: String(self[startIndex]).lowercaseString)
    }
    
}

/**

MARK: Numbers

*/
extension String {
    
    func toDouble() -> Double? {
        
        return NSNumberFormatter().numberFromString(self)?.doubleValue
        
    }
    
    func toLong() -> Int64? {
        return NSNumberFormatter().numberFromString(self)?.longLongValue
    }
}
