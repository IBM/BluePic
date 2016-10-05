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

import Foundation
import AVFoundation
import UIKit

extension UIImage {


    /**
     Method resizes the image to an appropriate size to be uploaded to the server

     - parameter image: UIImage

     - returns: UIImage?
     */
    class func resizeImage(_ image: UIImage) -> UIImage? {

        var actualHeight = image.size.height
        var actualWidth =  image.size.width
        let maxHeight: CGFloat = 600.0
        let maxWidth: CGFloat = 600.0
        var imgRatio = actualWidth/actualHeight
        let maxRatio = maxWidth/maxHeight
        let compressionQuality: CGFloat = 1.0

        if actualHeight > maxHeight || actualWidth > maxWidth {

            if imgRatio < maxRatio {
                //adjust width according to maxHeight
                imgRatio = maxHeight / actualHeight
                actualWidth = imgRatio * actualWidth
                actualHeight = maxHeight
            } else if imgRatio > maxRatio {
                //adjust height according to maxWidth
                imgRatio = maxWidth / actualWidth
                actualHeight = imgRatio * actualHeight
                actualWidth = maxWidth
            } else {
                actualHeight = maxHeight
                actualWidth = maxWidth
            }

        }

        let rect = CGRect(x: 0, y: 0, width: actualWidth, height: actualHeight)
        UIGraphicsBeginImageContext(rect.size)
        image.draw(in: rect)
        var imageData: Data?
        if let img = UIGraphicsGetImageFromCurrentImageContext() {
            imageData = UIImageJPEGRepresentation(img, compressionQuality)
        }
        UIGraphicsEndImageContext()

        if let data = imageData {
            return UIImage(data: data)
        } else {
            return nil
        }

    }

    /**
     Method rotates the image to its correct orrientation if necessary

     - parameter imageToRotate: UIImage

     - returns: UIImage
     */
    class func rotateImageIfNecessary(_ imageToRotate: UIImage) -> UIImage? {
        let imageOrientation = imageToRotate.imageOrientation.rawValue
        switch imageOrientation {
        case 0: //Up
            return imageToRotate.imageRotatedByDegrees(0, flip: false)
        case 1: //Down
            return imageToRotate.imageRotatedByDegrees(180, flip: false)
        case 2: //Left
            return imageToRotate.imageRotatedByDegrees(270, flip: false)
        case 3: //Right
            return imageToRotate.imageRotatedByDegrees(90, flip: false)
        default:
            return imageToRotate.imageRotatedByDegrees(0, flip: false)
        }
    }

    /**
     Method rotates image by degrees provided in the parameter. As will it will flip it with true or not with false.

     - parameter degrees: CGFloat
     - parameter flip:    Bool

     - returns: UIImage
     */
    public func imageRotatedByDegrees(_ degrees: CGFloat, flip: Bool) -> UIImage? {
        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 / 180.0 * CGFloat(M_PI)
        }

        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: CGPoint.zero, size: size))
        let t = CGAffineTransform(rotationAngle: degreesToRadians(degrees))
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size

        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        guard let bitmap = UIGraphicsGetCurrentContext() else {
            print("Failed to get bitmap from context")
            return nil
        }

        // Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2.0, y: rotatedSize.height / 2.0)

        //   // Rotate the image context
        bitmap.rotate(by: degreesToRadians(degrees))

        // Now, draw the rotated/scaled image into the context
        var yFlip: CGFloat

        if flip {
            yFlip = CGFloat(-1.0)
        } else {
            yFlip = CGFloat(1.0)
        }

        bitmap.scaleBy(x: yFlip, y: -1.0)
        bitmap.draw(self.cgImage!, in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }


    /**
     Method resizes and rotates the image to prepare it for image upload

     - parameter image: UIImage

     - returns: UIImage?
     */
    class func resizeAndRotateImage(_ image: UIImage) -> UIImage? {

        if let resizedImage = resizeImage(image) {
            return rotateImageIfNecessary(resizedImage)
        } else {
            return nil
        }

    }


}
