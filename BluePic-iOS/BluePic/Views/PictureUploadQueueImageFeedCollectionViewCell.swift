//
//  PictureUploadQueueImageFeedCollectionViewCell.swift
//  BluePic
//
//  Created by Alex Buck on 12/20/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit

class PictureUploadQueueImageFeedCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var captionLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    
    
    
    func setupData(image : UIImage?, caption : String?){
        
        
        if let img = image {
            
           imageView.image = img
            
        }
        
        //set the captionLabel's text
        captionLabel.text = caption ?? ""
        
    }
    
    
    

}
