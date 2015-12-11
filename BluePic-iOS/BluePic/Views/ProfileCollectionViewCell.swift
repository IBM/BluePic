//
//  ImageFeedCollectionViewCell.swift
//  BluePic
//
//  Created by Alex Buck on 12/1/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit

class ProfileCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var photographerNameLabel: UILabel!
    @IBOutlet weak var timeSincePostedLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        // Initialization code
    }
    
    
    
    func setupData(url : String?, image : UIImage?, displayName : String?, timeStamp: Double?, fileName : String?){
        
        
        setImageView(url, fileName: fileName)
        
        
        captionLabel.text = displayName?.uppercaseString ?? ""
        
        
        if let tStamp = timeStamp {
            
            timeSincePostedLabel.text = NSDate.timeStringSinceIntervalSinceReferenceDate(tStamp)
            
            
        }
        
        
    }
    
    
    
    func setImageView(url : String?, fileName : String?){
        let urlString = url ?? ""
        
        
        //unwrap fileName and facebook user id to be safe
        if let fName = fileName, let userID = FacebookDataManager.SharedInstance.fbUniqueUserID {
            let id = fName + userID
            
            if let img = CameraDataManager.SharedInstance.picturesTakenDuringAppSessionById[id] {
                
                //set placeholderImage with local copy of image in cache, and try to pull image from url if url is valid
                if let nsurl = NSURL(string: urlString){
                    //                    imageView.sd_setImageWithURL(nsurl, placeholderImage: img)
                    
                    imageView.image = img
                    //downloadImageWithSDWebImage(urlString, id: id)
                    
                    imageView.sd_setImageWithURL(nsurl, placeholderImage: img, completed: { result  in
                        
                        //clear camera data cache since we will be using sdWebImage's cache from now on
                        if result.0 != nil{
                            CameraDataManager.SharedInstance.picturesTakenDuringAppSessionById[id] = nil
                        }
                    })
                }
                    //url is not valid, so set imageView with local copy of image in cache
                else{
                    imageView.image = img
                }
            }
            else{
                if let nsurl = NSURL(string: urlString){
                    imageView.sd_setImageWithURL(nsurl)
                }
            }
        }
            //fileName or facebook user id were nil
        else {
            //set imageView with image from url if url is valid
            if let nsurl = NSURL(string: urlString){
                imageView.sd_setImageWithURL(nsurl)
            }
            
        }
    }
    
    
    
    
    

}
