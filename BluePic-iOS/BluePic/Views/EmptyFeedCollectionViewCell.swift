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

class EmptyFeedCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var userHasNoImagesLabel: UILabel!

    private let kUserHasNoImagesLabelText = NSLocalizedString("Snap a pic or select one from your library!", comment: "message that describes to the user to upload a picture to begin")

    /**
     Method is called when the view wakes from nib
     */
    override func awakeFromNib() {
        super.awakeFromNib()

        userHasNoImagesLabel.text = kUserHasNoImagesLabelText
    }

}
