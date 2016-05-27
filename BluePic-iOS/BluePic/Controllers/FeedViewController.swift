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

class FeedViewController: UIViewController {

    //represents the inner cicle that spins within the navigation bar on top
    @IBOutlet weak var logoImageView: UIImageView!

    //represents the outer eye of the inner cicle that spins
    @IBOutlet weak var outerEyeImageView: UIImageView!

    //collection view that displays the images in the feed
    @IBOutlet weak var collectionView: UICollectionView!

    //constraint outlet for the outer eye image view's top space
    @IBOutlet weak var outerEyeImageViewTopSpaceConstraint: NSLayoutConstraint!

    //constraint outlet for the collection view's top space
    @IBOutlet weak var collectionViewTopSpaceConstraint: NSLayoutConstraint!

    //top bar that shows on intial load of the app
    @IBOutlet weak var defaultTopBarView: UIView!

    //top bar that shows when displaying search results
    @IBOutlet var searchTopBarView: UIView!

    //label used to show searchQuery
    @IBOutlet weak var wordTagLabel: UILabel!

    //label to give user feedback on the results they wanted
    @IBOutlet weak var noResultsLabel: UILabel!

    //search query parameters that will be sent to the server for results
    var searchQuery: String?

    //view model of the Feed View controller. It will keep track of state and handle data for this view controller
    var viewModel: FeedViewModel!

    //Allows for pull down to refresh
    var refreshControl: UIRefreshControl!

    //Defines the minimum spacing between cells in the collection view
    let kMinimumInterItemSpacingForSectionAtIndex: CGFloat = 0

    /**
     Method called upon view did load. It sets up the collection view, sets up the view model, starts the loading animation at app launch, determines the feed model, and observes when the application becomes active
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        setupViewModel()

        startLoadingAnimationAtAppLaunch()
        determineFeedMode()

        observeWhenApplicationBecomesActive()
    }

    /**
     Method to determine if we should put the search top bar up because we just performed a search query
     */
    func determineFeedMode() {

        if let query = searchQuery {
            searchTopBarView.frame = defaultTopBarView.frame
            defaultTopBarView.hidden = true
            searchTopBarView.hidden = false
            wordTagLabel.text = query.uppercaseString
            Utils.kernLabelString(wordTagLabel, spacingValue: 1.4)
            self.view.addSubview(searchTopBarView)
        }

    }

    /**
     Method observes when the application becomes active. It does this so we can restart the loading animation
     */
    func observeWhenApplicationBecomesActive() {

        let notificationCenter = NSNotificationCenter.defaultCenter()

        notificationCenter.addObserver(self,
                                       selector:#selector(FeedViewController.didBecomeActive),
                                       name:UIApplicationDidBecomeActiveNotification,
                                       object:nil)
    }

    /**
     Method is called when the application did become active. It trys to restart the loading animation
     */
    func didBecomeActive() {
        tryToStartLoadingAnimation()
    }

    /**
     Method called upon view will appear. It trys to start the loading animation if there are any photos in the BluemixDataManager's imagesCurrentlyUploading property. It also sets the status bar to white and sets the navigation bar to hidden

     - parameter animated: Bool
     */
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.Default

        self.navigationController?.setNavigationBarHidden(true, animated: false)
        tryToStartLoadingAnimation()

    }

    /**
     Method called as a callback from the OS when the app receives a memeory warning from the OS
     */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    /**
     Method sets up the view model, passes the callback we want to be called when there are notifications from the feed view model
     */
    func setupViewModel() {
        viewModel = FeedViewModel(notifyFeedVC: handleFeedViewModelNotifications, searchQuery: searchQuery)
    }

    /**
     Method sets up the collection view with various initial properties
     */
    func setupCollectionView() {

        collectionView.delegate = self
        collectionView.dataSource = self

        Utils.registerNibWithCollectionView("EmptyFeedCollectionViewCell", collectionView: collectionView)

        Utils.registerNibWithCollectionView("ImageFeedCollectionViewCell", collectionView: collectionView)

        Utils.registerNibWithCollectionView("ImagesCurrentlyUploadingImageFeedCollectionViewCell", collectionView: collectionView)

        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: #selector(FeedViewController.userTriggeredRefresh), forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl.hidden = true
        self.refreshControl.tintColor = UIColor.clearColor()

        self.collectionView.addSubview(refreshControl)
    }

    /**
     Method reloads the data in the collection view. It is typically called by its view model when it receives data.
     */
    func reloadDataInCollectionView() {

        collectionView.reloadData()
        tryToStopLoadingAnimation()

        self.collectionView.setContentOffset(CGPoint.zero, animated: true)
    }

    /**
     Method is called when the user triggers a pull to refresh
     */
    func userTriggeredRefresh() {

        logoImageView.startRotating(1)
        self.refreshControl.endRefreshing()

        viewModel.repullForNewData()

    }

    /**
     Method starts the loading animation at app launch
     */
    func startLoadingAnimationAtAppLaunch() {
        if viewModel.shouldBeginLoadingAtAppLaunch() {
            dispatch_async(dispatch_get_main_queue()) {
                self.logoImageView.startRotating(1)
            }
        }
    }

    /**
     Method will try to start the loading animation if there are any images in the imagesCurrentlyUploading property of the BluemixDataManager. This allows for the loading animation to start up again if the user switches between the image feed and profile vc
     */
    func tryToStartLoadingAnimation() {

        if viewModel.shouldStartLoadingAnimation() {
            logoImageView.startRotating(1)
        }

    }


    /**
     Method will only allow the loading animation of the eye to stop if the imagesCurrentlyUploading property of the BluemixDataManager is empty. This is because if the imagesCurrentlyUploading has picture in it, then we want to ensure the eye continues to spin until all the images in the imagesCurrentlyUploading property have finished uploading
     */
    func tryToStopLoadingAnimation() {

        if viewModel.shouldStopLoadingAnimation() {

            logoImageView.stopRotating()

        }
    }

    /**
     Method is caleld when the search icon in the top right corner is pressed

     - parameter sender: AnyObject
     */
    @IBAction func transitionToSearch(sender: AnyObject) {
        if let vc = Utils.vcWithNameFromStoryboardWithName("SearchViewController", storyboardName: "Feed") as? SearchViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    /**
     Method pops the vc on the navigation stack when the back button is pressed when search results are shown

     - parameter sender: AnyObject
     */
    @IBAction func popVC(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }

    /**
     Method scrolls the collection view to the top
     */
    func scrollCollectionViewToTop() {

        collectionView.contentOffset.y = 0

    }

}

extension FeedViewController: UICollectionViewDataSource {


    /**
     Method sets up the cell for item at indexPath by asking the view model to set up the collection view cell

     - parameter collectionView: UICollectionView
     - parameter indexPath:      NSIndexpath

     - returns: UICollectionViewCell
     */
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return viewModel.setUpCollectionViewCell(indexPath, collectionView : collectionView)
    }

    /**
     Method sets the number of items in a section by asking the view model how many items are in this section

     - parameter collectionView: UICollectionView
     - parameter section:        Int

     - returns: Int
     */
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItemsInSection(section)
    }


    /**
     Method returns the number of sections in the collection view by asking its view moddel how many sections are in the collection view

     - parameter collectionView: UICollectionview

     - returns: Int
     */
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return viewModel.numberOfSectionsInCollectionView()
    }

}

extension FeedViewController: UICollectionViewDelegate {

    /**
     Method is called when a cell in the collection view is selected

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

}


extension FeedViewController: UICollectionViewDelegateFlowLayout {

    /**
     Method returns the size for item at indexPath by asking the view Model for the size for item at indexPath

     - parameter collectionView:       UICollectionView
     - parameter collectionViewLayout: UICollectionViewLayout
     - parameter indexPath:            NSIndexPath

     - returns: CGSize
     */
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

        return viewModel.sizeForItemAtIndexPath(indexPath, collectionView: collectionView)
    }

}

//ViewModel -> ViewController Communication
extension FeedViewController {

    /**
     Method handles view model notifications given to this view controller from its view model

     - parameter feedViewModelNotification: FeedviewModelNotifications
     */
    func handleFeedViewModelNotifications(feedViewModelNotification: FeedViewModelNotification) {

        if feedViewModelNotification == FeedViewModelNotification.ReloadCollectionView {
            reloadDataInCollectionView()
        } else if feedViewModelNotification == FeedViewModelNotification.UploadingPhotoStarted {
            collectionView.reloadData()
            scrollCollectionViewToTop()
            tryToStartLoadingAnimation()
        } else if feedViewModelNotification == FeedViewModelNotification.NoSearchResults {
            // do alert
            noResultsLabel.hidden = false
        }

    }
}
