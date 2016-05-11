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
    @IBOutlet weak var bottomCollectionViewConstraint: NSLayoutConstraint!
    
    let kCellPadding: CGFloat = 60
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPopularTags()
    }
    
    func setupPopularTags() {
        
        let layout = KTCenterFlowLayout()
        layout.minimumInteritemSpacing = 12.0
        layout.minimumLineSpacing = 10.0
        tagCollectionView.setCollectionViewLayout(layout, animated: false)
        
        Utils.kernLabelString(tagsButton.titleLabel!, spacingValue: 1.7)
        Utils.registerNibWithCollectionView("TagCollectionViewCell", collectionView: tagCollectionView)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        searchField.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /// Method to make sure keyboard doesn't hide parts of the collectionView
    func keyboardWillShow(n: NSNotification) {
        let userInfo = n.userInfo

        if let info = userInfo, keyboardRect = info[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let rectValue = keyboardRect.CGRectValue()
            bottomCollectionViewConstraint.constant = rectValue.height - 40 // with offset
        }
    }

    @IBAction func popVC(sender: AnyObject) {
        searchField.resignFirstResponder()
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    deinit {
        BluemixDataManager.SharedInstance.searchResultImages.removeAll()
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
        let vc = Utils.vcWithNameFromStoryboardWithName("FeedViewController", storyboardName: "Feed") as! FeedViewController
        vc.searchQuery = tempPopularTags[indexPath.item]
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension SearchViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if let query = textField.text where !query.containsString(" ") && query.characters.count > 0 {
        
            let vc = Utils.vcWithNameFromStoryboardWithName("FeedViewController", storyboardName: "Feed") as! FeedViewController
            vc.searchQuery = textField.text
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            print("Invalid search query")
        }
        
        return true
    }
    
}
