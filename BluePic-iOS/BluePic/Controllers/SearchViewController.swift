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

    //string property that holds the popular tags of BluePic
    var popularTags = [String]()

    //search text field that the user can type searches in
    @IBOutlet weak var searchField: UITextField!

    //tags button that just says tags, has no fuction at this time
    @IBOutlet weak var tagsButton: UIButton!

    //collection view that displays the popular tags
    @IBOutlet weak var tagCollectionView: UICollectionView!

    //constraint outlet for the bottom of the collection view
    @IBOutlet weak var bottomCollectionViewConstraint: NSLayoutConstraint!

    //padding used for the width of the collection view cell in sizeForItemAtIndexPath method
    let kCellPadding: CGFloat = 30

    /**
     Method called upon view did load. It sets up the popular tags collection view, observes when the keyboard is shown, and begins the fetch of popular tags
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        setupPopularTags()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        initializeDataRetrieval()
    }

    /**
     Method sets up the popular tags collection view
     */
    func setupPopularTags() {

        let layout = KTCenterFlowLayout()
        layout.leftAlignedLayout = true
        layout.minimumInteritemSpacing = 10.0
        layout.minimumLineSpacing = 10.0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 15.0, bottom: 0, right: 15.0)
        tagCollectionView.setCollectionViewLayout(layout, animated: false)

        if let label = tagsButton.titleLabel {
            Utils.kernLabelString(label, spacingValue: 1.7)
        }
        Utils.registerNibWith("TagCollectionViewCell", collectionView: tagCollectionView)
    }

    /**
     Method called upon view will appear. It sets the search text field to become a first responder so it becomes selected and the keyboard shows

     - parameter animated: Bool
     */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchField.becomeFirstResponder()
    }

    /**
     Method called by the OS when the application receieves a memory warning
     */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    /**
     Method to make sure keyboard doesn't hide parts of the collectionView

     - parameter n: Notification
     */
    func keyboardWillShow(_ n: Notification) {
        let userInfo = n.userInfo

        if let info = userInfo, let keyboardRect = info[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let rectValue = keyboardRect.cgRectValue
            bottomCollectionViewConstraint.constant = rectValue.height - 40 // with offset
        }
    }

    /**
     Method called when the back button is pressed

     - parameter sender: Any
     */
    @IBAction func popVC(_ sender: Any) {
        searchField.resignFirstResponder()
        _ = self.navigationController?.popViewController(animated: true)
    }

}

// MARK: - extension to separate out data handling code
extension SearchViewController {

    /**
     Method initializes data retrieval by observing the PopularTagsReceieved notification of the BluemixDataManager, and starting the fetch to get popular tags

     - returns:
     */
    func initializeDataRetrieval() {

        NotificationCenter.default.addObserver(self, selector: #selector(updateWithTagData), name: .popularTagsReceived, object: nil)

        BluemixDataManager.SharedInstance.getPopularTags()
    }

    /**
     Method is called when the BluemixDataManager has successfully received tags. It updates the tag collection view with this new data
     */
    func updateWithTagData() {
        DispatchQueue.main.async(execute: {
            self.popularTags = BluemixDataManager.SharedInstance.tags
            self.tagCollectionView.performBatchUpdates({
                self.tagCollectionView.reloadSections(IndexSet(integer: 0))
            }, completion: nil)
        })
    }

}

extension SearchViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    /**
     Method returns the number of items in each section

     - parameter collectionView: UICollectionView
     - parameter section:        Int

     - returns: Int
     */
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return popularTags.count
    }

    /**
     Method sets up the cell for item at indexPath

     - parameter collectionView: UICollectionView
     - parameter indexPath:      IndexPath

     - returns: UICollectionViewCell
     */
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagCollectionViewCell", for: indexPath) as? TagCollectionViewCell else {
            return UICollectionViewCell()
        }

        cell.tagLabel.text = popularTags[indexPath.item]
        return cell
    }

    /**
     Method returns the size for item at indexPath

     - parameter collectionView:       UICollectionVIew
     - parameter collectionViewLayout: UICollectionViewLayout
     - parameter indexPath:            IndexPath

     - returns: CGSize
     */
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = NSString(string: popularTags[indexPath.item].uppercased()).size(attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 13.0)])
        return CGSize(width: size.width + kCellPadding, height: 30.0)
    }

    /**
     Method is called when a cell in the collection view is selected. In this case we segue to the feed vc with search results for that tag

     - parameter collectionView: UICollectionView
     - parameter indexPath:      IndexPath
     */
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        // open feed of items with selected tag
        if let vc = Utils.vcWithNameFromStoryboardWithName("FeedViewController", storyboardName: "Feed") as? FeedViewController {
            vc.searchQuery = popularTags[indexPath.item]
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

}

extension SearchViewController: UITextFieldDelegate {

    /**
     Method defines the action taken when the return key of the keyboard is pressed

     - parameter textField: UITextField

     - returns: Bool
     */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        if let query = textField.text, let vc = Utils.vcWithNameFromStoryboardWithName("FeedViewController", storyboardName: "Feed") as? FeedViewController, query.characters.count > 0 {

            vc.searchQuery = query

            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            print(NSLocalizedString("Invalid search query", comment: ""))
            textField.shakeView()
        }

        return true
    }

    /**
     Method limits the amount of characters that can be entered in the search text field

     - parameter textField: UITextField
     - parameter range:     NSRange
     - parameter string:    String

     - returns: Bool
     */
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text, text.characters.count + string.characters.count <= 40 {
            return true
        }
        return false
    }

}
