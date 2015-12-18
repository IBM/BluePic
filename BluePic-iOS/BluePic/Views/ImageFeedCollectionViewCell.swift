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
    

    /**
     Method is called when the view wakes from nib
     */
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
     
        //set the image view's image
        self.setImageView(url, fileName: fileName)

        //set the captionLabel's text
        captionLabel.text = displayName?.uppercaseString ?? ""
        
        //set the photographerNameLabel's text
        var ownerNameString = ""
        if let owner = ownerName {
            ownerNameString = NSLocalizedString("by", comment: "") + " \(owner)"
        }
        photographerNameLabel.text = ownerNameString
        
        //set the time since posted label's text
        if let tStamp = timeStamp {
           timeSincePostedLabel.text = NSDate.timeStringSinceIntervalSinceReferenceDate(tStamp)
        }

    }
    
    
    /**
     Method sets up the image view with the url provided or a locally cached verion of the image
     
     - parameter url:      String?
     - parameter fileName: String?
     */
    func setImageView(url : String?, fileName : String?){
        
        self.loadingView.hidden = false
        
        //first try to set image view with locally cached image (from a photo the user has posted during the app session)
        let locallyCachedImage = self.tryToSetImageViewWithLocallyCachedImage(fileName)
        
        //then try to set the imageView with a url, using the locally cached image as the placeholder (if there is one)
        self.tryToSetImageViewWithURL(url, placeHolderImage: locallyCachedImage)
        
    }
    
    
    
    /**
     Method trys to set the image view with a locally cached image if there is one and then returns the locally cached image
     
     - parameter fileName: String?
     
     - returns: UIImage?
     */
    private func tryToSetImageViewWithLocallyCachedImage(fileName : String?) -> UIImage?{
        
        //check if file name and facebook user id aren't nil
        if let fName = fileName, let userID = FacebookDataManager.SharedInstance.fbUniqueUserID {
            
            //generate id which is a concatenation of the file name and facebook user id
            let id = fName + userID
            
            //check to see if there is an image cached in the camera data manager's picturesTakenDuringAppSessionById cache
            if let img = CameraDataManager.SharedInstance.picturesTakenDuringAppSessionById[id] {
        
                //hide loading placeholder view
                self.loadingView.hidden = true
                
                //set image view's image to locally cached image
                imageView.image = img
                
                return img
            }
        }
        
        return nil
    }
    
    
    
    /**
     Method trys to set the image view with a url to an image and sets the placeholder to a locally cached image if its not nil
     
     - parameter url:              String?
     - parameter placeHolderImage: UIImage?
     */
    private func tryToSetImageViewWithURL(url : String?, placeHolderImage : UIImage?){
        
        let urlString = url ?? ""
        
        //check if string is empty, if it is, then its not a valid url
        if(urlString != ""){
            
            //check if we can turn the string into a valid NSURL
            if let nsurl = NSURL(string: urlString){
                
                //if placeHolderImage parameter isn't nil, then set image with URL and use placeholder image
                if let image = placeHolderImage {
                    setImageViewWithURLAndPlaceHolderImage(nsurl, placeHolderImage: image)
                }
                //else dont use placeholder image and
                else{
                    setImageViewWithURL(nsurl)
                }
            }
        }
    }
    
    
    /**
     Method sets the imageView with a url to an image and uses a locally cached image
     
     - parameter url:              NSURL
     - parameter placeHolderImage: UIImage
     */
    private func setImageViewWithURLAndPlaceHolderImage(url : NSURL, placeHolderImage : UIImage){
        
        imageView.sd_setImageWithURL(url, placeholderImage: placeHolderImage, completed: { result in
            
            if result.0 != nil {
                self.loadingView.hidden = true
            }
            
        })
    }
    
    
    /**
     Method sets the imageView with a url to an image using no placeholder
     
     - parameter url: NSURL
     */
    private func setImageViewWithURL(url : NSURL){
        imageView.sd_setImageWithURL(url, completed: { result in
            
            if result.0 != nil{
                self.loadingView.hidden = true
            }
            
        })
    }
    

}