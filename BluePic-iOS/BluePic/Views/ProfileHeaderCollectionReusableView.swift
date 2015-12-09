//
//  ProfileHeaderCollectionReusableView.swift
//  BluePic
//
//  Created by Alex Buck on 12/8/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit

class ProfileHeaderCollectionReusableView: UICollectionReusableView {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var numberOfShotsLabel: UILabel!
    
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    
    
    
    
    func setupData(name : String?, numberOfShots : Int?){
    
        nameLabel.text = name?.uppercaseString ?? ""
        
        if let shots = numberOfShots {
            let shotsString = NSLocalizedString("Shots", comment: "")
            
            numberOfShotsLabel.text = "\(shots) \(shotsString)"
        }

    }
    
    
}
