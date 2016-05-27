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

    /**
     Method to simply shake a view back and forth. Most useful on textField to show invalid input
     */
    func shakeView() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.06
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = NSValue(CGPoint: CGPoint(x: self.center.x - 10, y: self.center.y))
        animation.toValue = NSValue(CGPoint: CGPoint(x: self.center.x + 10, y: self.center.y))
        self.layer.addAnimation(animation, forKey: "position")
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
