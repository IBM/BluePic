//
//  ImageFeedCollectionViewCell.swift
//  BluePic
//
//  Created by Alex Buck on 12/1/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit

class ImageFeedCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var photographerNameLabel: UILabel!
    @IBOutlet weak var timeSincePostedLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        // Initialization code
    }
    
    
    
    func setupData(url : String?, image : UIImage?, displayName : String?, ownerName: String?, timeStamp: String?){
        
        let urlString = url ?? ""
        
        if let img = image {
            
            imageView.image = img
            
        }
        else{
            if let nsurl = NSURL(string: urlString){
                
                imageView.sd_setImageWithURL(nsurl, completed: { _ in
                    
                    
                    
                })
            }
        }
        
       
        
        captionLabel.text = displayName?.uppercaseString ?? ""
        
        
        var ownerNameString = ""
        if let owner = ownerName {
            ownerNameString = NSLocalizedString("by", comment: "") + " \(owner)"
        }
        photographerNameLabel.text = ownerNameString
        
    }
    
    

}
