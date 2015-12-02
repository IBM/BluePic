//
//  CameraConfirmationView.swift
//  BluePic
//
//  Created by Nathan Hekman on 12/2/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit

class CameraConfirmationView: UIView {

    @IBOutlet weak var photoImageView: UIImageView!
    
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var postButton: UIButton!
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    
    static func instanceFromNib() -> CameraConfirmationView {
        return UINib(nibName: "CameraConfirmationView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! CameraConfirmationView
    }
    
    /**
     Method called when the view wakes from nib and then sets up the view
     */
    override func awakeFromNib() {
        super.awakeFromNib()
        //setupView()
    }
    

}
