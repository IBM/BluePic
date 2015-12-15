/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/


import UIKit

class ImageFeedCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var photographerNameLabel: UILabel!
    @IBOutlet weak var timeSincePostedLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingImageView: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        // Initialization code
    }
    
    
    
    func setupData(url : String?, image : UIImage?, displayName : String?, ownerName: String?, timeStamp: Double?, fileName : String?, orientation: String?){
        
     
        self.setImageView(url, fileName: fileName)
        
        self.setImageOrientation(orientation)

        
        captionLabel.text = displayName?.uppercaseString ?? ""
        
        
        var ownerNameString = ""
        if let owner = ownerName {
            ownerNameString = NSLocalizedString("by", comment: "") + " \(owner)"
        }
        photographerNameLabel.text = ownerNameString
        
        
        
        if let tStamp = timeStamp {
         
           timeSincePostedLabel.text = NSDate.timeStringSinceIntervalSinceReferenceDate(tStamp)
       
        }

    }
    
    
    
    func setImageView(url : String?, fileName : String?){
        
        self.loadingView.hidden = false
        
        let urlString = url ?? ""
        
        
        //unwrap fileName and facebook user id to be safe
        if let fName = fileName, let userID = FacebookDataManager.SharedInstance.fbUniqueUserID {
            let id = fName + userID
        
            if let img = CameraDataManager.SharedInstance.picturesTakenDuringAppSessionById[id] {
                
                //set placeholderImage with local copy of image in cache, and try to pull image from url if url is valid
                if let nsurl = NSURL(string: urlString){
                    
                    self.loadingView.hidden = true
                    
                    imageView.image = img
                    
                    imageView.sd_setImageWithURL(nsurl, placeholderImage: img, completed: { result  in
                        
                        //clear camera data cache since we will be using sdWebImage's cache from now on
                        if result.0 != nil{
                            
                            //CameraDataManager.SharedInstance.picturesTakenDuringAppSessionById[id] = nil
                        }
                    })
                }
                //url is not valid, so set imageView with local copy of image in cache
                else{
                    
                    self.loadingView.hidden = true
                    imageView.image = img
                }
            }
            else{
                if let nsurl = NSURL(string: urlString){
                    
                    imageView.sd_setImageWithURL(nsurl, completed: { result in
                        
                        if result.0 != nil{
                        self.loadingView.hidden = true
                        }
                        
                    })
                }
            }
        }
        //fileName or facebook user id were nil
        else {
            //set imageView with image from url if url is valid
            if let nsurl = NSURL(string: urlString){
                
                imageView.sd_setImageWithURL(nsurl, completed: { result in
                    
                    if result.0 != nil{
                        self.loadingView.hidden = true
                    }
                    
                })
            }
        
        }
    }
    
    
    func setImageOrientation(orientation : String?){

        if let orient = orientation {
        
            if let orientationInt = Int(orient) {
            
                switch orientationInt {
                    
                    case 0: //Up
                        self.imageView.transform = CGAffineTransformMakeRotation(0)
                    case 1: //Down
                        self.imageView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
                    case 2: //Left
                        self.imageView.transform = CGAffineTransformMakeRotation(CGFloat(3 * M_PI_2))
                    case 3: //Right
                        self.imageView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
                    default:
                        self.imageView.transform = CGAffineTransformMakeRotation(0)
                }
            }
        }
        
        
    }
    
    
    
    
    
    

}
