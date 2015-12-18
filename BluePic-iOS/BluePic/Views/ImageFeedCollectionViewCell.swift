/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/


import UIKit

class ImageFeedCollectionViewCell: UICollectionViewCell {
    
    
    //image view used to display image
    @IBOutlet weak var imageView: UIImageView!
    
    //label used to display the photos caption
    @IBOutlet weak var captionLabel: UILabel!
    
    //label used to display the photographer's name
    @IBOutlet weak var photographerNameLabel: UILabel!
    
    //label that displays the amount of time since the photo was taken
    @IBOutlet weak var timeSincePostedLabel: UILabel!
    
    //button that triggers the options display for a photo (currently hidden and not in use)
    @IBOutlet weak var moreButton: UIButton!
    
    //the view that is shown while we wait for the image to download and display
    @IBOutlet weak var loadingView: UIView!
    
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
    /**
     Method sets up the data for the image feed cell
     
     - parameter url:         String?
     - parameter image:       UIImage?
     - parameter displayName: String?
     - parameter ownerName:   String?
     - parameter timeStamp:   Double?
     - parameter fileName:    String?
     */
    func setupData(url : String?, image : UIImage?, displayName : String?, ownerName: String?, timeStamp: Double?, fileName : String?){
     
        self.setImageView(url, fileName: fileName)

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
    
    
    /**
     Method sets up the image view with the url provided or a local verion of the image
     
     - parameter url:      String?
     - parameter fileName: String?
     */
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
    

}