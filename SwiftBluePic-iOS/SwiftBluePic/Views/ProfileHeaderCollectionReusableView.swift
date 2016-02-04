/**
 * Copyright IBM Corporation 2015
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/


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
