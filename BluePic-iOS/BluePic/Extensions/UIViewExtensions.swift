/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/


import CoreFoundation
import Foundation
import UIKit


//// MARK: - Rotating animation
extension UIView {
    
    /**
     Method starts rotating a uiview 360 degrees until it is told to stop
     
     - parameter duration: Double
     */
    func startRotating(duration: Double = 1) {
        let kAnimationKey = "rotation"
        self.layer.removeAnimationForKey(kAnimationKey)
        if self.layer.animationForKey(kAnimationKey) == nil {
            let animate = CABasicAnimation(keyPath: "transform.rotation")
            animate.duration = duration
            animate.repeatCount = Float.infinity
            animate.fromValue = 0.0
            animate.toValue = Float(M_PI * 2.0)
            self.layer.addAnimation(animate, forKey: kAnimationKey)
            
        }
    }
    
    /**
     Method stops rotating a uiview 360 degrees
     */
    func stopRotating() {
        let kAnimationKey = "rotation"
        
        if self.layer.animationForKey(kAnimationKey) != nil {
            self.layer.removeAnimationForKey(kAnimationKey)
        }
    }
    
}

/**
 
 MARK: IBInspectable
 
 */
extension UIView {
    
    
    /// Allows you to modify the corner radius of a view in storyboard
    @IBInspectable var cornerRadius: CGFloat {
        get { return layer.cornerRadius }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
}