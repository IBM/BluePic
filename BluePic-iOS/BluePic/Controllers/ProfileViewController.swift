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

class ProfileViewController: UIViewController {

    //the collection view that displays images for the user
    @IBOutlet weak var collectionView: UICollectionView!

    //view model that will keep state and handle data for the ProfileViewController
    var viewModel: ProfileViewModel!

    //this is the header view that represents the user's "cover photo" at the top of the view
    var headerImageView: UIImageView!

    //view that is shown when the status bar starts to overlap with the user's profile picture
    var statusBarBackgroundView: UIView!

    //constant represents the height of the "info view" - the view that says the user's name and number of photos
    let kHeaderViewInfoViewHeight: CGFloat = 105

    //constant that represents the height of the image view that represents the user's "cover photo"
    let kHeaderImageViewHeight: CGFloat = 375

    //constant that represents the rate that the scroll view scrolls
    let kParalaxImageViewScrollRate: CGFloat = 0.50

    //constant that represents the duration it takes to fade the statusBarBackgroundView in
    let kStatusBarBackgroundViewFadeDuration: NSTimeInterval = 0.3

    //constant that represents the height of the profile picture image view
    let kHeightOfProfilePictureImageView: CGFloat = 75

    /**
     Method called upon view did load. It sets up the view model, sets up the colleciton view, sets up the head view, and sets up the status bar background view
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        setupViewModel()

        setupCollectionView()

        setupHeaderView()

        setupStatusBarBackgroundView()

    }

    /**
     Method called upon view will appear, it sets the status bar to black

     - parameter animated: Bool
     */
    override func viewWillAppear(animated: Bool) {
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.Default
    }


    /**
     Method called when the app receives a memory warning from the OS
     */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    /**
     Method called sets up the viewModel and passes it a method to call when there is new data and we need to reload the collection view of the profile vc
     */
    func setupViewModel() {
        viewModel = ProfileViewModel(refreshVCCallback: reloadDataInCollectionView)
    }

    /**
     Method sets up the status bar background view
     */
    func setupStatusBarBackgroundView() {

        let effect = UIBlurEffect(style: UIBlurEffectStyle.Light)

        let viewWithBlurredBackground = UIVisualEffectView(effect: effect)
        viewWithBlurredBackground.frame = UIApplication.sharedApplication().statusBarFrame
        viewWithBlurredBackground.alpha = 1.0

        statusBarBackgroundView = UIView(frame: UIApplication.sharedApplication().statusBarFrame)
        statusBarBackgroundView .backgroundColor = UIColor.clearColor()
        statusBarBackgroundView .alpha = 0.0
        statusBarBackgroundView .addSubview(viewWithBlurredBackground)

        self.view.addSubview(statusBarBackgroundView)

    }

    /**
     Method animates in the status bar background view

     - parameter isInOrOut: Bool
     */
    func animateInStatusBarBackgroundView(isInOrOut: Bool) {

        var alpha: CGFloat = 0.0

        if isInOrOut {
            alpha = 1.0
        }

        UIView.animateWithDuration(kStatusBarBackgroundViewFadeDuration, animations: {
            self.statusBarBackgroundView.alpha = alpha
        })

    }

    /**
    Method sets up the header view with initial properties
     */
    func setupHeaderView() {

        headerImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: kHeaderImageViewHeight))

        headerImageView.contentMode = UIViewContentMode.ScaleAspectFill

        headerImageView.image = UIImage(named: "photo1")

        headerImageView.clipsToBounds = true

        self.view.addSubview(headerImageView)
        self.view.insertSubview(headerImageView, belowSubview: collectionView)

    }

    /**
     Method sets up the collection view with initial properties
     */
    func setupCollectionView() {

        collectionView.delegate = self
        collectionView.dataSource = self

        Utils.registerSupplementaryElementOfKindNibWithCollectionView("ProfileHeaderCollectionReusableView", kind: UICollectionElementKindSectionHeader, collectionView: collectionView)

        Utils.registerNibWithCollectionView("EmptyFeedCollectionViewCell", collectionView: collectionView)

        Utils.registerNibWithCollectionView("ProfileCollectionViewCell", collectionView: collectionView)

    }

    /**
     Method reloads the data in the collection view
     */
    func reloadDataInCollectionView() {
        collectionView.reloadData()
    }

}

extension ProfileViewController: UICollectionViewDataSource {

    /**
     Method setups up the viewForSupplementaryElementOfKind by asking the viewModel to set it up. This specifically sets up a header view on the top of the collection view to be clear so you can see the image view at the top of the collection view that is actually below the collection view.

     - parameter collectionView:
     - parameter kind:
     - parameter indexPath:

     - returns:
     */
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        return viewModel.setUpSectionHeaderViewForIndexPath(
            indexPath,
            kind: kind,
            collectionView: collectionView
        )
    }

    /**
     Method sets up the cell for item at indexPath by asking the view model to set up the cell for item at indexPath

     - parameter collectionView: UICollectionView
     - parameter indexPath:      NSIndexPath

     - returns: UICollectionViewCell
     */
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return viewModel.setUpCollectionViewCell(indexPath, collectionView : collectionView)
    }

    /**
     Method sets the number of items in a section by asking the view model for the number of items in the section

     - parameter collectionView: UICollectionView
     - parameter section:        Int

     - returns: Int
     */
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItemsInSection(section)
    }

    /**
     Method sets the number of sections in the collection view by asking the view model for the number of sections in the collection view

     - parameter collectionView: UIcollectionView

     - returns: Int
     */
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return viewModel.numberOfSectionsInCollectionView()
    }

}

extension ProfileViewController: UICollectionViewDelegateFlowLayout {

    /**
     Method sets the size of the section header at indexpath depending on what section it is.

     - parameter collectionView:
     - parameter collectionViewLayout:
     - parameter section:

     - returns:
     */
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        let collectionWidth = collectionView.frame.size.width

        if section == 0 {
            return CGSize(width: collectionWidth, height: self.view.frame.size.height/2 + kHeaderViewInfoViewHeight) //kHeaderViewHeight
        } else {
            return CGSize(width: collectionWidth, height: 0)
        }
    }

    /**
     Method sets the size for item at indexpath, either for the empty feed colelction view cell or the profile collection cell by asking its view model for the size

     - parameter collectionView:       UICollectionview
     - parameter collectionViewLayout: UICollectionviewLayout
     - parameter indexPath:            NSIndexPath

     - returns: CGSize
     */
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

        let heightForEmptyProfileCollectionViewCell = self.view.frame.size.height - (self.view.frame.size.height/2 + kHeaderViewInfoViewHeight)

        return viewModel.sizeForItemAtIndexPath(indexPath, collectionView: collectionView, heightForEmptyProfileCollectionViewCell: heightForEmptyProfileCollectionViewCell)
    }

}

extension ProfileViewController : UIScrollViewDelegate {

    /**
     Method is called upon when a cell in the collection view is selected. It this case we segue to the image detail, first asking the view model to set up the view model of the image detail vc were about to segue to

     - parameter collectionView: UICollectionView
     - parameter indexPath:      NSIndexPath
     */
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        if let imageDetailViewModel = viewModel.prepareImageDetailViewModelForSelectedCellAtIndexPath(indexPath),
            imageDetailVC = Utils.vcWithNameFromStoryboardWithName("ImageDetailViewController", storyboardName: "Feed") as? ImageDetailViewController {

            imageDetailVC.viewModel = imageDetailViewModel
            self.navigationController?.pushViewController(imageDetailVC, animated: true)
        }

    }

    /**
     Method that is called when the scrollView scrolls. When the scrollView scrolls we call the updateImageViewFrameWithScrollViewDidScroll method

     - parameter scrollView:
     */
    func scrollViewDidScroll(scrollView: UIScrollView) {

        checkOffSetForStatusBarBackgroundViewVisability(scrollView.contentOffset.y)
        updateImageViewFrameWithScrollViewDidScroll(scrollView.contentOffset.y)
    }

    /**
     Method is called in the scrollViewDidScroll method. It allows for paralax scrolling or the image view to stretch.

     - parameter scrollViewContentOffset:
     */
    func updateImageViewFrameWithScrollViewDidScroll(scrollViewContentOffset: CGFloat) {

        if scrollViewContentOffset >= 0 {
            headerImageView.frame.origin.y = -(scrollViewContentOffset * kParalaxImageViewScrollRate)
        } else {
            headerImageView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: kHeaderImageViewHeight - scrollViewContentOffset)
        }
    }

    /**
     Method sets the status bar to be a frosted class effect when the profile image touches the status bar

     - parameter scrollViewContentOffset: CGFloat
     */
    func checkOffSetForStatusBarBackgroundViewVisability(scrollViewContentOffset: CGFloat) {

        let headerImageViewHeight = self.view.frame.size.height/2

        let magicLine = headerImageViewHeight - kHeightOfProfilePictureImageView/2 - UIApplication.sharedApplication().statusBarFrame.size.height

        if scrollViewContentOffset >= magicLine {
            animateInStatusBarBackgroundView(true)
        } else {
            animateInStatusBarBackgroundView(false)
        }
    }
}
