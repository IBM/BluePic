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

    //imageView that shows a circle thumbnail of the image currently uplaoding
    @IBOutlet weak var imageView: UIImageView!

    //label that shows the caption the user has chosen for the image currently uploading
    @IBOutlet weak var captionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    /**
     Method that sets up the data for this cell

     - parameter image:   UIImage?
     - parameter caption: String?
     */
    func setupData(image: UIImage?, caption: String?) {

        if let img = image {

           imageView.image = img

        }

        //set the captionLabel's text
        var cap = caption ?? ""
        if cap == CameraDataManager.SharedInstance.kEmptyCaptionPlaceHolder {
            cap = ""
        }
        captionLabel.text = cap

    }

}
