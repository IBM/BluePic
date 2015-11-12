/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/


import Foundation
import UIKit

extension UILabel {
    
    func sizeToFitFixedWidth(fixedWidth: CGFloat) {
        if text != "" {
            let objcString: NSString = text!
            var frame = objcString.boundingRectWithSize(CGSizeMake(fixedWidth, CGFloat.max), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName:font], context: nil)
            frame = CGRectMake(frame.origin.x, frame.origin.y, fixedWidth, frame.size.height)
        }

    }
    
    class func heightForText(text: String, font: UIFont, width: CGFloat)->CGFloat{
        let label:UILabel = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.font = font
        label.text = text
        
        label.sizeToFit()

        return label.frame.size.height
    }
    
    func setKernAttribute(size: CGFloat!){
        let kernAttribute : Dictionary = [NSKernAttributeName: size]
        if text != nil {
            attributedText = NSAttributedString(string: text!, attributes: kernAttribute)
        }
    }
}