/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import Foundation
import AVFoundation
import UIKit

extension UIImage{
    
    var uncompressedPNGData: NSData      { return UIImagePNGRepresentation(self)!        }
    var highestQualityJPEGNSData: NSData { return UIImageJPEGRepresentation(self, 1.0)!  }
    var highQualityJPEGNSData: NSData    { return UIImageJPEGRepresentation(self, 0.75)! }
    var mediumQualityJPEGNSData: NSData  { return UIImageJPEGRepresentation(self, 0.5)!  }
    var lowQualityJPEGNSData: NSData     { return UIImageJPEGRepresentation(self, 0.25)! }
    var lowestQualityJPEGNSData:NSData   { return UIImageJPEGRepresentation(self, 0.0)!  }
    
    
    
    func croppedImage(bound : CGRect) -> UIImage
    {
        let scaledBounds : CGRect = CGRectMake(bound.origin.x * scale, bound.origin.y * scale, bound.size.width * scale, bound.size.height * scale)
        let imageRef = CGImageCreateWithImageInRect(CGImage, scaledBounds)
        let croppedImage : UIImage = UIImage(CGImage: imageRef!, scale: scale, orientation: UIImageOrientation.Up)
        return croppedImage
    }
    
    
    /**
     Resizes a UIImage given a height
     
     - parameter image:     image to resize
     - parameter newHeight: height of new size of image
     
     - returns: newly resized image
     */
    class func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
//        let newWidth = image.size.width * scale
//        let newHeight = image.size.height * scale
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        image.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
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
    
    
    public func imageRotatedByDegrees(degrees: CGFloat, flip: Bool) -> UIImage {
        let radiansToDegrees: (CGFloat) -> CGFloat = {
            return $0 * (180.0 / CGFloat(M_PI))
        }
        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 / 180.0 * CGFloat(M_PI)
        }
        
        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: CGPointZero, size: size))
        let t = CGAffineTransformMakeRotation(degreesToRadians(degrees));
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap = UIGraphicsGetCurrentContext()
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        CGContextTranslateCTM(bitmap, rotatedSize.width / 2.0, rotatedSize.height / 2.0);
        
        //   // Rotate the image context
        CGContextRotateCTM(bitmap, degreesToRadians(degrees));
        
        // Now, draw the rotated/scaled image into the context
        var yFlip: CGFloat
        
        if(flip){
            yFlip = CGFloat(-1.0)
        } else {
            yFlip = CGFloat(1.0)
        }
        
        CGContextScaleCTM(bitmap, yFlip, -1.0)
        CGContextDrawImage(bitmap, CGRectMake(-size.width / 2, -size.height / 2, size.width, size.height), CGImage)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    
}