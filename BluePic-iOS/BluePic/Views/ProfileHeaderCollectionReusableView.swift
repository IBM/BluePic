/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/


import UIKit

class ProfileHeaderCollectionReusableView: UICollectionReusableView {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var numberOfShotsLabel: UILabel!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    
    
    
    
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
