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
    
    
    
    func setupData(imageURL : String?, captionText : String?, photographerName : String?, timeSincePosted : String?){
        
        let urlString = imageURL ?? ""
        
        if let url = NSURL(string: urlString){
            imageView.sd_setImageWithURL(url, completed: { _ in
                
                
                
            })
        }
        
        captionLabel.text = captionText ?? ""
        
        photographerNameLabel.text = photographerName ?? ""
        
    }
    
    

}
