/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import Foundation
import UIKit

extension UIButton{
    
    func setBackgroundColorForState(color: UIColor, forState: UIControlState){
        setBackgroundImage(UIButton.imageWithColor(color, width: frame.size.width, height: frame.size.height), forState: forState)
    }
    
    /**
    Create an image of a given color
    
    - parameter color:  The color that the image will have
    - parameter width:  Width of the returned image
    - parameter height: Height of the returned image
    
    - returns: An image with the color, height and width
    */
    private class func imageWithColor(color: UIColor, width: CGFloat, height: CGFloat) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func setKernAttribute(size: CGFloat!){
        
        let states = [UIControlState.Normal, UIControlState.Application, UIControlState.Disabled, UIControlState.Highlighted, UIControlState.Reserved, UIControlState.Selected]
        
        for state in states{
            let titleColor = titleColorForState(state)
            let attributes : [String: AnyObject]
            if titleColor != nil {
                attributes = [NSKernAttributeName: size, NSForegroundColorAttributeName: titleColor!]
            }else{
                attributes = [NSKernAttributeName: size]
            }
            let title = titleForState(state)
            if(title != nil){
                setAttributedTitle(NSAttributedString(string: title!, attributes: attributes), forState: state)
            }
        }
        
        
    }
    
}
