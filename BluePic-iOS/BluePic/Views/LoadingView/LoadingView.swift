/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
This sample program is provided AS IS and may be used, executed, copied and modified without royalty payment by customer (a) for its own instruction and study, (b) in order to develop applications designed to run with an IBM product, either for customer's own internal use or for redistribution by customer, as part of such an application, in customer's own products.
*/

import UIKit

/// Loading view
class LoadingView: UIView {

    /// Image to animate loading
    @IBOutlet weak var imageView: UIImageView!
    
    /// label
    @IBOutlet weak var titleLabel: UILabel!
    
    /// array of uiimages
    var imageNames: [UIImage]! = []
    
    /// time to animate
    var animationTime: NSTimeInterval!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    
    /**
    Method that creates an instance from the nib file
    
    - returns: LoadingView
    */
    class func instanceFromNib() -> LoadingView {
        return UINib(nibName: "LoadingView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! LoadingView
    }
    
    
    /**
    Method to start loading
    */
    func startLoadingAnimation() {
        imageView.animationDuration = animationTime
        imageView.startAnimating()
    }
    
    
    /**
    Method to stop loading
    */
    func stopLoadingAnimation() {
        imageView.stopAnimating()
    }
    
    
    /**
    Method to add all images to the array
    */
    func addImagesToArray() {
        for (var i = 51; i < 100; i++) {
            let image = UIImage(named: "Loader_000\(i)")
            imageNames.append(image!)
        }
        for (var i = 100; i < 148; i++) {
            let image = UIImage(named: "Loader_00\(i)")
            imageNames.append(image!)
        }
        
        imageView.animationImages = imageNames
    }
    
    

}
