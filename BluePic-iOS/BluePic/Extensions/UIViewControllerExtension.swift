//
//  UIViewControllerExtension.swift
//  BluePic
//
//  Created by Alex Buck on 6/8/16.
//  Copyright © 2016 MIL. All rights reserved.
//

import Foundation


extension UIViewController {


    /**
     Method returns whether the view controller is visible or not

     - parameter viewController: UIViewController

     - returns: Bool
     */
    func isVisible() -> Bool {

        if let navigationController = self.navigationController, let visibleViewController = navigationController.visibleViewController {
            if self == visibleViewController {
                return true
            } else {
                return false
            }
        } else {
            return false
        }

    }
}
