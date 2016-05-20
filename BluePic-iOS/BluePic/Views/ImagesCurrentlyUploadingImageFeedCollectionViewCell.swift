/**
 * Copyright IBM Corporation 2016
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

class ImagesCurrentlyUploadingImageFeedCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var captionLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setupData(image : UIImage?, caption : String?){
        
        if let img = image {
            
           imageView.image = img
            
        }
        
        //set the captionLabel's text
        var cap = caption ?? ""
        if(cap == CameraDataManager.SharedInstance.kEmptyCaptionPlaceHolder){
            cap = ""
        }
        captionLabel.text = cap
        
    }

}
