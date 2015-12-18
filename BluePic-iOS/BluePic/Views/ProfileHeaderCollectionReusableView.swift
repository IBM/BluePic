/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/


import UIKit

class ProfileHeaderCollectionReusableView: UICollectionReusableView {

    //label displays the name of the user
    @IBOutlet weak var nameLabel: UILabel!
    
    //label displays the numebr of shots the user has taken
    @IBOutlet weak var numberOfShotsLabel: UILabel!
    
    //image view displays the user's facebook profile picture
    @IBOutlet weak var profilePictureImageView: UIImageView!
    
    
    /**
     Method is called when the view wakes from nib
     */
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    /**
    Method sets up the data of the profileHeaderCollectionReusableView
     
     - parameter name:              String?
     - parameter numberOfShots:     Int?
     - parameter profilePictureURL: String
     */
    func setupData(name : String?, numberOfShots : Int?, profilePictureURL : String){
    
        nameLabel.text = name?.uppercaseString ?? ""
        
        if let shots = numberOfShots {
            
            if(shots > 0){
                
                var shotsString = ""
            
                if(shots == 1){
                    shotsString = NSLocalizedString("Shot", comment: "")
                }
                else{
                    shotsString = NSLocalizedString("Shots", comment: "")
                }
    
                numberOfShotsLabel.text = "\(shots) \(shotsString)"
                
            }
        }
        
        if let url = NSURL(string: profilePictureURL){
        
            profilePictureImageView.sd_setImageWithURL(url)
            
        }
    
    }
    
    
}
