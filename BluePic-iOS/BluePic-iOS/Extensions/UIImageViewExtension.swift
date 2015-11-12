/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import Foundation
import UIKit

extension UIImageView{
    func roundImageView()
    {
        //height and width should be the same
        clipsToBounds = true
        layer.cornerRadius = frame.size.width / 2
    }
    
    /**
    Method that compiles an array of sequenced images to later animate and assigns them to the `animationImages` property on `UIImageView`
    
    - parameter imagePrefix: name consistent with all images in sequence
    - parameter range:       numerical suffix of sequence of images
    */
    func createImageAnimation(imagePrefix: String, range: (Int, Int)) {
        
        var animatedImagesArray = [UIImage]()
        for index in range.0...range.1 {
            animatedImagesArray.append(UIImage(named: "\(imagePrefix)\(index)")!)
        }
        
        self.animationImages = animatedImagesArray
        
        // When done animating, display last image
        self.image = self.animationImages!.last! as UIImage
    }
    
}