//
//  NSAttributedStringExtension.swift
//  BluePic
//
//  Created by Alex Buck on 5/12/16.
//  Copyright © 2016 MIL. All rights reserved.
//





extension NSAttributedString {
    
    class func createAttributedStringWithLetterAndLineSpacingWithCentering(string : String, letterSpacing : CGFloat, lineSpacing : CGFloat, centered : Bool) -> NSAttributedString{
        
        let attributedString = NSMutableAttributedString(string: string)
        attributedString.addAttribute(NSKernAttributeName, value:   letterSpacing, range: NSRange(location: 0, length: attributedString.length))
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        
        if centered{
            paragraphStyle.alignment = NSTextAlignment.Center
        }
        
        attributedString.addAttribute(NSParagraphStyleAttributeName, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))
        
        return attributedString
        
    }
    
}
