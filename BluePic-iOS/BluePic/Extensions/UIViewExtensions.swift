/*

Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.

UIViewExtension.swift
MIL iOS Reusable Assets

*/

import CoreFoundation
import Foundation
import UIKit

/**

MARK: Underscore Convenience

*/
extension UIView {
  
    var _frame: CGRect { return self.frame }
    
    var _origin: CGPoint { return _frame.origin }
    var _size: CGSize { return _frame.size }
    var _center: CGPoint { return self.center }
    
    var _width: CGFloat { return _frame.width }
    var _height: CGFloat { return _frame.height }

    var _x: CGFloat { return _origin.x }
    var _y: CGFloat { return _origin.y }
    
    var _centerX: CGFloat { return _center.x }
    var _centerY: CGFloat { return _center.y }
    
    var _left: CGFloat { return _x }
    var _right: CGFloat { return _x + _width }
    var _top: CGFloat { return _y }
    var _bottom: CGFloat { return _y + _height }
    
}


/**

MARK: Non-Underscore Convenience

*/
extension UIView {

    var origin: CGPoint { return _origin }
    var size: CGSize  { return _size }

    var width: CGFloat { return _width}
    var height: CGFloat { return _height }

    var x: CGFloat { return _x }
    var y: CGFloat { return _y }

    var centerX: CGFloat { return _centerX }
    var centerY: CGFloat { return _centerY }

    var left: CGFloat { return _left }
    var right: CGFloat { return _right }
    var top: CGFloat { return _top }
    var bottom: CGFloat { return _bottom }

}


/** 

MARK: Setters 

*/
extension UIView {

    func setWidth(width: CGFloat) { self.frame.size.width = width }
    func setHeight(height: CGFloat) { self.frame.size.height = height }
    func setSize(size: CGSize) { self.frame.size = size }
    func setOrigin(point: CGPoint) { self.frame.origin = point }
    func setOriginX(x: CGFloat) { self.frame.origin = CGPoint(x: x, y: _origin.y) }
    func setOriginY(y: CGFloat) { self.frame.origin = CGPoint(x: _origin.x, y: y) }
    func setCenterX(x: CGFloat) { self.center = CGPoint(x: x, y: self.center.y) }
    func setCenterY(y: CGFloat) { self.center = CGPoint(x: self.center.x, y: y) }
    func roundCorner(radius: CGFloat) { self.layer.cornerRadius = radius }
    func setTop(top: CGFloat) { self.frame.origin.y = top }
    func setLeft(left: CGFloat) { self.frame.origin.x = left }
    func setRight(right: CGFloat) { self.frame.origin.x = right - _width }
    func setBottom(bottom: CGFloat) { self.frame.origin.y = bottom - _height }
    
}


/**

MARK: IBInspectable

*/
extension UIView {
    
    @IBInspectable var cornerRadius: CGFloat {
        get { return layer.cornerRadius }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get { return layer.borderWidth }
        set { layer.borderWidth = newValue }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            if let borderColor = self.layer.borderColor {
                return UIColor(CGColor: borderColor)
            } else {
                return nil
            }
        }
        set { layer.borderColor = newValue?.CGColor }
    }
    
}
    

/**

    Auto Layout extension code

    NOTE: If you are adjusting constraints on outlets
    that have already been set in storyboard, make sure to
    call removeAllConstraints() before starting to set
    constraints via code with these methods.

*/
extension UIView {
    
    var differentSuperviewsWarningMessage: String {
        return "Since you are adding a constraint to self.superview, self and the view passed in need to have the same superview. The views you are trying to align do not have the same superview."
    }
    
    /// Remove all constraints from a view. Make sure you don't have a weak reference to your view/outlet, else it might be deallocated.
    func removeAllConstraints() {
        
        let theSuperview = self.superview
        self.removeFromSuperview()
        theSuperview?.addSubview(self)
    
    }
    
    /// Center the view vertically and horizontally in superview.
    func centerInSuperview() {
        
        self.centerVerticallyInSuperview()
        self.centerHorizontallyInSuperview()
    
    }
    
    /// Center the view vertically in superview.
    func centerVerticallyInSuperview() {
        
        self.superview?.addConstraint(NSLayoutConstraint(
            item: self,
            attribute: NSLayoutAttribute.CenterY,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self.superview,
            attribute: NSLayoutAttribute.CenterY,
            multiplier: 1,
            constant: 0)
        )
        
    }
    
    /// Center the view horizontally in superview.
    func centerHorizontallyInSuperview() {
        
        self.superview?.addConstraint(NSLayoutConstraint(
            item: self,
            attribute: NSLayoutAttribute.CenterX,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self.superview,
            attribute: NSLayoutAttribute.CenterX,
            multiplier: 1,
            constant: 0)
        )
        
    }
    
    /// Set the leading (left) space to superview.
    ///
    /// :param: space The amount to space.
    func leadingSpaceToSuperview(space: CGFloat) {
        
        self.superview?.addConstraint(NSLayoutConstraint(
            item: self,
            attribute: NSLayoutAttribute.Leading,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self.superview,
            attribute: NSLayoutAttribute.Leading,
            multiplier: 1,
            constant: space)
        )
        
    }
    
    /// Set the top space to superview.
    ///
    /// :param: space The amount to space.
    func topSpaceToSuperview(space: CGFloat) {
        
        self.superview?.addConstraint(NSLayoutConstraint(
            item: self,
            attribute: NSLayoutAttribute.Top,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self.superview,
            attribute: NSLayoutAttribute.Top,
            multiplier: 1,
            constant: space)
        )
        
    }
    
    /// Set the bottom space to superview.
    ///
    /// :param: space The amount to space.
    func bottomSpaceToSuperview(space: CGFloat) {
        
        self.superview?.addConstraint(NSLayoutConstraint(
            item: self,
            attribute: NSLayoutAttribute.Bottom,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self.superview,
            attribute: NSLayoutAttribute.Bottom,
            multiplier: 1,
            constant: -space))
        
    }
    
    /// Set the trailing (right) space to superview.
    ///
    /// :param: space The amount to space.
    func trailingSpaceToSuperview(space: CGFloat) {
        
        self.superview?.addConstraint(NSLayoutConstraint(
            item: self,
            attribute: NSLayoutAttribute.Trailing,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self.superview,
            attribute: NSLayoutAttribute.Trailing,
            multiplier: 1,
            constant: -space))
        
    }
    
    /// Space the calling view's left border away from the passed in view's right border.
    ///
    /// :param: view The view to space from.
    /// :param: space The amount to space.
    func horizontalSpacingToRightOf(view: UIView, space: CGFloat) {
        
        assert(self.superview == view.superview, differentSuperviewsWarningMessage)
        
        self.superview?.addConstraint(NSLayoutConstraint(
            item: self,
            attribute: NSLayoutAttribute.Left,
            relatedBy: NSLayoutRelation.Equal,
            toItem: view,
            attribute: NSLayoutAttribute.Right,
            multiplier: 1,
            constant: space))
        
    }
    
    /// Space the calling view's right border away from the passed in view's left border.
    ///
    /// :param: view The view to space from.
    /// :param: space The amount to space.
    func horizontalSpacingToLeftOf(view: UIView, space: CGFloat) {
        
        assert(self.superview == view.superview, differentSuperviewsWarningMessage)
        
        self.superview?.addConstraint(NSLayoutConstraint(
            item: self,
            attribute: NSLayoutAttribute.Right,
            relatedBy: NSLayoutRelation.Equal,
            toItem: view,
            attribute: NSLayoutAttribute.Left,
            multiplier: 1,
            constant: -space))
        
    }
    
    /// Space the calling view's top border away from the passed in view's bottom border.
    ///
    /// :param: view The view to space from.
    /// :param: space The amount to space.
    func verticalSpacingBelow(view: UIView, space: CGFloat) {
        
        assert(self.superview == view.superview, differentSuperviewsWarningMessage)
        
        self.superview?.addConstraint(NSLayoutConstraint(
            item: self,
            attribute: NSLayoutAttribute.Top,
            relatedBy: NSLayoutRelation.Equal,
            toItem: view,
            attribute: NSLayoutAttribute.Bottom,
            multiplier: 1,
            constant: space))
        
    }
    
    /// Space the calling view's bottom border away from the passed in view's top border.
    ///
    /// :param: view The view to space from.
    /// :param: space The amount to space.
    func verticalSpacingAbove(view: UIView, space: CGFloat) {
        
        assert(self.superview == view.superview, differentSuperviewsWarningMessage)
        
        self.superview?.addConstraint(NSLayoutConstraint(
            item: self,
            attribute: NSLayoutAttribute.Bottom,
            relatedBy: NSLayoutRelation.Equal,
            toItem: view,
            attribute: NSLayoutAttribute.Top,
            multiplier: 1,
            constant: -space))
        
    }
    
    /// Set the calling view's x center equal to the passed in view's x center.
    ///
    /// :param: view The view to center with.
    func centerXWith(view: UIView) {
        
        assert(self.superview == view.superview, differentSuperviewsWarningMessage)
        
        self.superview?.addConstraint(NSLayoutConstraint(
            item: self,
            attribute: NSLayoutAttribute.CenterX,
            relatedBy: NSLayoutRelation.Equal,
            toItem: view,
            attribute: NSLayoutAttribute.CenterX,
            multiplier: 1,
            constant: 0))
    
    }
    
    /// Set the calling view's y center equal to the passed in view's y center.
    ///
    /// :param: view The view to center with.
    func centerYWith(view: UIView) {
        assert(self.superview == view.superview, differentSuperviewsWarningMessage)
        self.superview?.addConstraint(NSLayoutConstraint(
            item: self,
            attribute: NSLayoutAttribute.CenterY,
            relatedBy: NSLayoutRelation.Equal,
            toItem: view,
            attribute: NSLayoutAttribute.CenterY,
            multiplier: 1,
            constant: 0))
    }
    
    /// Align the calling view's top border with the passed in view's top border.
    ///
    /// :param: view The view to align with.
    func alignTopWith(view: UIView) {
        
        assert(self.superview == view.superview, differentSuperviewsWarningMessage)
        
        self.superview?.addConstraint(NSLayoutConstraint(
            item: self,
            attribute: NSLayoutAttribute.Top,
            relatedBy: NSLayoutRelation.Equal,
            toItem: view,
            attribute: NSLayoutAttribute.Top,
            multiplier: 1,
            constant: 0))
    
    }
    
    /// Align the calling view's bottom border with the passed in view's bottom border.
    ///
    /// :param: view The view to align with.
    func alignBottomWith(view: UIView) {
        
        assert(self.superview == view.superview, differentSuperviewsWarningMessage)
        
        self.superview?.addConstraint(NSLayoutConstraint(
            item: self,
            attribute: NSLayoutAttribute.Bottom,
            relatedBy: NSLayoutRelation.Equal,
            toItem: view,
            attribute: NSLayoutAttribute.Bottom,
            multiplier: 1,
            constant: 0))
        
    }
    
    /// Align the calling view's left border with the passed in view's left border.
    ///
    /// :param: view The view to align with.
    func alignLeftWith(view: UIView) {
        
        assert(self.superview == view.superview, differentSuperviewsWarningMessage)
        
        self.superview?.addConstraint(NSLayoutConstraint(
            item: self,
            attribute: NSLayoutAttribute.Left,
            relatedBy: NSLayoutRelation.Equal,
            toItem: view,
            attribute: NSLayoutAttribute.Left,
            multiplier: 1,
            constant: 0))
        
    }
    
    /// Align the calling view's right border with the passed in view's right border.
    ///
    /// :param: view The view to align with.
    func alignRightWith(view: UIView) {
        
        assert(self.superview == view.superview, differentSuperviewsWarningMessage)
        
        self.superview?.addConstraint(NSLayoutConstraint(
            item: self,
            attribute: NSLayoutAttribute.Right,
            relatedBy: NSLayoutRelation.Equal,
            toItem: view,
            attribute: NSLayoutAttribute.Right,
            multiplier: 1,
            constant: 0))
        
    }

}

// MARK: - Rotating animation
extension UIView {
    func startRotating(duration: Double = 1) {
        let kAnimationKey = "rotation"
        
        if self.layer.animationForKey(kAnimationKey) == nil {
            let animate = CABasicAnimation(keyPath: "transform.rotation")
            animate.duration = duration
            animate.repeatCount = Float.infinity
            animate.fromValue = 0.0
            animate.toValue = Float(M_PI * 2.0)
            self.layer.addAnimation(animate, forKey: kAnimationKey)
        }
    }
    func stopRotating() {
        let kAnimationKey = "rotation"
        
        if self.layer.animationForKey(kAnimationKey) != nil {
            self.layer.removeAnimationForKey(kAnimationKey)
        }
    }
}


/** 

MARK: Animation

*/
extension UIView {
    
    /**
    Method that simply applies an animation to shake a view
    */
    func shakeView() {
        
        let key = "position"
        
        let animation = CABasicAnimation(keyPath: key)
        animation.duration = 0.06
        animation.repeatCount = 3
        animation.autoreverses = true
        
        animation.fromValue = NSValue(CGPoint: CGPoint(
            x: self.center.x - 10,
            y: self.center.y)
        )
        
        animation.toValue = NSValue(CGPoint: CGPoint(
            x: self.center.x + 10,
            y: self.center.y)
        )
        
        self.layer.addAnimation(animation, forKey: key)
        
    }
    
}