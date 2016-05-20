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
    
    var popularTags = [String]()
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var tagsButton: UIButton!
    @IBOutlet weak var tagCollectionView: UICollectionView!
    @IBOutlet weak var bottomCollectionViewConstraint: NSLayoutConstraint!
    
    let kCellPadding: CGFloat = 60
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPopularTags()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        initializeDataRetrieval()
    }
    
    func setupPopularTags() {
        
        let layout = KTCenterFlowLayout()
        layout.leftAlignedLayout = true
        layout.minimumInteritemSpacing = 10.0
        layout.minimumLineSpacing = 10.0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 15.0, bottom: 0, right: 15.0)
        tagCollectionView.setCollectionViewLayout(layout, animated: false)
        
        Utils.kernLabelString(tagsButton.titleLabel!, spacingValue: 1.7)
        Utils.registerNibWithCollectionView("TagCollectionViewCell", collectionView: tagCollectionView)
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

// extension to separate out data handling code
extension SearchViewController {
    
    func initializeDataRetrieval() {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateWithTagData), name: BluemixDataManagerNotification.PopularTagsReceived.rawValue, object: nil)
        
        BluemixDataManager.SharedInstance.getPopularTags()
    }
    
    func updateWithTagData() {
        dispatch_async(dispatch_get_main_queue(),{
            self.popularTags = BluemixDataManager.SharedInstance.tags
            self.tagCollectionView.performBatchUpdates({
                self.tagCollectionView.reloadSections(NSIndexSet(index: 0))
            }, completion: nil)
        })
    }
    
}

extension SearchViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return popularTags.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TagCollectionViewCell", forIndexPath: indexPath) as? TagCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        cell.tagLabel.text = popularTags[indexPath.item]
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let size = NSString(string: popularTags[indexPath.item]).sizeWithAttributes(nil)
        return CGSizeMake(size.width + kCellPadding, 30.0)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        // open feed of items with selected tag
        let vc = Utils.vcWithNameFromStoryboardWithName("FeedViewController", storyboardName: "Feed") as! FeedViewController
        vc.searchQuery = popularTags[indexPath.item]
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension SearchViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if let query = textField.text where query.characters.count > 0 {
        
            let vc = Utils.vcWithNameFromStoryboardWithName("FeedViewController", storyboardName: "Feed") as! FeedViewController
            vc.searchQuery = textField.text
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            print("Invalid search query")
            textField.shakeView()
        }
        
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if string.containsString(" ") {
            return false
        }
        return true
    }
    
}
