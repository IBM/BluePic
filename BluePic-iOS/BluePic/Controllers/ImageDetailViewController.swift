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

class ImageDetailViewController: UIViewController {

    //Image view that shows the image
    @IBOutlet weak var imageView: UIImageView!

    //dim view that dims the images with a see-through black view
    @IBOutlet weak var dimView: UIView!

    //back button that when pressed pops the vc on the navigation stack
    @IBOutlet weak var backButton: UIButton!

    //colection view that shows the tags for the current image displayed
    @IBOutlet weak var tagCollectionView: UICollectionView!

    //view model that will keep all state and data handling for the image detail vc
    var viewModel: ImageDetailViewModel!


    /**
     Method called upon view did load. It sets up the subviews and the tag collection view
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        setupSubViews()
        setupTagCollectionView()
    }

    /**
     Method called upon view will appear. It sets the status bar to be white color

     - parameter animated: Bool
     */
    override func viewWillAppear(animated: Bool) {
        UIApplication.sharedApplication().statusBarStyle = .LightContent
    }

    /**
     Method called by the OS when the application receieves a memory warning
     */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }



    /**
     Method is called when the back button is pressed

     - parameter sender: AnyObject
     */
    @IBAction func backButtonAction(sender: AnyObject) {

        self.navigationController?.popViewControllerAnimated(true)

    }

}


//UI Setup Methods
extension ImageDetailViewController {

    /**
     Method sets up the tag collection view
     */
    func setupTagCollectionView() {

        let layout = KTCenterFlowLayout()
        layout.minimumInteritemSpacing = 10.0
        layout.minimumLineSpacing = 10.0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 15.0, bottom: 0, right: 15.0)
        tagCollectionView.setCollectionViewLayout(layout, animated: false)
        tagCollectionView.delegate = self
        tagCollectionView.dataSource = self

        Utils.registerSupplementaryElementOfKindNibWithCollectionView("ImageInfoHeaderCollectionReusableView", kind: UICollectionElementKindSectionHeader, collectionView: tagCollectionView)

        Utils.registerNibWithCollectionView("TagCollectionViewCell", collectionView: tagCollectionView)

    }

    /**
     Method sets up subviews
     */
    func setupSubViews() {

        setupImageView()
        setupBlurView()

    }


    /**
     Method sets up the image view
     */
    func setupImageView() {

        if let urlString = viewModel.getImageURLString() {
            let nsurl = NSURL(string: urlString)
            imageView.sd_setImageWithURL(nsurl)
        }
    }

    /**
     Method sets up the blur view
     */
    func setupBlurView() {

        dimView.hidden = true

        let blurViewFrame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)

        let blurViewHolderView = UIView(frame: blurViewFrame)

        let darkBlur = UIBlurEffect(style: UIBlurEffectStyle.Dark)

        let blurView = UIVisualEffectView(effect: darkBlur)
        blurView.frame = blurViewFrame
        blurViewHolderView.alpha = 0.90

        blurViewHolderView.addSubview(blurView)

        imageView.addSubview(blurViewHolderView)

    }

}

extension ImageDetailViewController : UICollectionViewDataSource {


    /**
     Method asks the view model for the number of items in the section

     - parameter collectionView: UICollectionView
     - parameter section:        Int

     - returns: Int
     */
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItemsInSection(section)
    }

    /**
     Method asks the viewModel for the number of sections in the collection view

     - parameter collectionView: UICollectionView

     - returns: Int
     */
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return viewModel.numberOfSectionsInCollectionView()
    }

    /**
     Method asks the view model to set up the view for supplementary element of kind, aka the header view

     - parameter collectionView: UICollectionView
     - parameter kind:           String
     - parameter indexPath:      NSIndexPath

     - returns: UICollectionReusableView
     */
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        return viewModel.setUpSectionHeaderViewForIndexPath(
            indexPath,
            kind: kind,
            collectionView: collectionView
        )
    }

    /**
     Method asks the viewModel to set up the collection view for indexPath

     - parameter collectionView: UICollectionView
     - parameter indexPath:      NSIndexPath

     - returns: UICollectionViewCell
     */
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return viewModel.setUpCollectionViewCell(indexPath, collectionView: collectionView)
    }

}

extension ImageDetailViewController: UICollectionViewDelegateFlowLayout {

    /**
     Method asks the viewModel for the size for item at indexPath

     - parameter collectionView:       UICollectionView
     - parameter collectionViewLayout: UICollectionViewLayout
     - parameter indexPath:            NSIndexPath

     - returns: CGSize
     */
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

        return viewModel.sizeForItemAtIndexPath(indexPath, collectionView: collectionView)
    }

    /**
     Method asks the viewMOdel for the reference size for header in section

     - parameter collectionView:       UICollectionView
     - parameter collectionViewLayout: UICollectionViewLayout
     - parameter section:              Int

     - returns: CGSize
     */
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

       return viewModel.referenceSizeForHeaderInSection(collectionView, layout: collectionViewLayout, section: section, superViewHeight: self.view.frame.size.height)
    }

}

extension ImageDetailViewController : UICollectionViewDelegate {

    /**
     Method is called when a cell in the collection view is selected

     - parameter collectionView: UICollectionView
     - parameter indexPath:      NSIndexPath
     */
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let vc = viewModel.getFeedViewControllerForTagSearchAtIndexPath(indexPath) {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

}
