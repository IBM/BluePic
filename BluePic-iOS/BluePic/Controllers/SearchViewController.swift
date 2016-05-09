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

class SearchViewController: UIViewController {
    
    let tempPopularTags = ["MOUNTAIN", "TREES", "SKY", "NATURE", "PEOPLE", "OCEAN", "CITY"]
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var tagsButton: UIButton!
    @IBOutlet weak var tagCollectionView: UICollectionView!
    
    let kCellPadding: CGFloat = 60
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let attributedString = NSMutableAttributedString(string: "TAGS")
        attributedString.addAttribute(NSKernAttributeName, value: CGFloat(1.7), range: NSRange(location: 0, length: attributedString.length))
        tagsButton.titleLabel!.attributedText = attributedString
        
        Utils.registerNibWithCollectionView("TagCollectionViewCell", collectionView: tagCollectionView)

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        searchField.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func popVC(sender: AnyObject) {
        searchField.resignFirstResponder()
        self.navigationController?.popViewControllerAnimated(true)
    }
}

extension SearchViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tempPopularTags.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TagCollectionViewCell", forIndexPath: indexPath) as? TagCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        cell.tagLabel.text = tempPopularTags[indexPath.item]
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let size = NSString(string: tempPopularTags[indexPath.item]).sizeWithAttributes(nil)
        return CGSizeMake(size.width + kCellPadding, 30.0)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        // open feed of items with selected tag
    }
    
}

extension SearchViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
