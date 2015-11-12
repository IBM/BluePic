/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import Foundation
import AVFoundation
import UIKit

extension UIImage{
    func croppedImage(bound : CGRect) -> UIImage
    {
        let scaledBounds : CGRect = CGRectMake(bound.origin.x * scale, bound.origin.y * scale, bound.size.width * scale, bound.size.height * scale)
        let imageRef = CGImageCreateWithImageInRect(CGImage, scaledBounds)
        let croppedImage : UIImage = UIImage(CGImage: imageRef!, scale: scale, orientation: UIImageOrientation.Up)
        return croppedImage
    }
    
    /**
    Creates an image from a video. Created with help from http://stackoverflow.com/questions/8906004/thumbnail-image-of-video/8906104#8906104
    
    - parameter videoURL: The url of the video to grab an image from
    
    - returns: The thumbnail image
    */
    class func getThumbnailFromVideo(videoURL: NSURL) -> UIImage {
        let asset: AVURLAsset = AVURLAsset(URL: videoURL, options: nil)
        let imageGen: AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
        imageGen.appliesPreferredTrackTransform = true
        let time = CMTimeMakeWithSeconds(1.0, 600)
        let image: CGImageRef = try! imageGen.copyCGImageAtTime(time, actualTime: nil)
        let thumbnail: UIImage = UIImage(CGImage: image)
        
        return thumbnail
    }
    
    /**
    Create an image of a given color
    
    - parameter color:  The color that the image will have
    - parameter width:  Width of the returned image
    - parameter height: Height of the returned image
    
    - returns: An image with the color, height and width
    */
    class func imageWithColor(color: UIColor, width: CGFloat, height: CGFloat) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    /**
    Method to perform crop based on square inside app frame
    
    - parameter view: the view image was capture in
    - parameter square: the crop square over the image
    - parameter fromCam: determine how to handle the passed in image
    
    - returns: UIImage - the cropped image
    */
    func cropImageInView(view: UIView, square: CGRect, fromCam: Bool) -> UIImage {
        let cropSquare: CGRect
        let frameWidth = view.frame.size.width
        let imageHeight = size.height
        let imageWidth = size.width
        
        // "if" creates a square from cameraroll image, else creates square from square frame in camera
        if !fromCam {
            
            let edge: CGFloat
            if imageWidth > imageHeight {
                edge = imageHeight
            } else {
                edge = imageWidth
            }
            
            let posX = (imageWidth  - edge) / 2.0
            let posY = (imageHeight - edge) / 2.0
            
            cropSquare = CGRectMake(posX, posY, edge, edge)
            
        } else {
            
            let imageScale: CGFloat!
            imageScale = imageWidth / frameWidth
            // x and y are switched because image has -90 degrees rotation by default
            cropSquare = CGRectMake(square.origin.y * imageScale, square.origin.x * imageScale, square.size.width * imageScale, square.size.height * imageScale)
        }
        
        let imageRef = CGImageCreateWithImageInRect(CGImage, cropSquare)
        return UIImage(CGImage: imageRef!, scale: UIScreen.mainScreen().scale, orientation: imageOrientation)
    }
}