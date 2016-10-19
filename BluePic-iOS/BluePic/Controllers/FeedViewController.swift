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
import SVProgressHUD

class FeedViewController: UIViewController {

    //represents the inner cicle that spins within the navigation bar on top
    @IBOutlet weak var logoImageView: UIImageView!

    //represents the outer eye of the inner cicle that spins
    @IBOutlet weak var outerEyeImageView: UIImageView!

    @IBOutlet weak var tableView: UITableView!

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
    @IBOutlet weak var alertBannerView: UIView!
    @IBOutlet weak var alertBannerLabel: UILabel!
    @IBOutlet weak var topAlertConstraint: NSLayoutConstraint!

    //search query parameters that will be sent to the server for results
    var searchQuery: String?

    //view model of the Feed View controller. It will keep track of state and handle data for this view controller
    var viewModel: FeedViewModel!

    //Allows for pull down to refresh
    var refreshControl: UIRefreshControl!

    //state variable used to know if we we were unable to present this alert because the FeedViewController wasn't visible
    var failedToPresentImageFeedErrorAlert = false

    //Defines the minimum spacing between cells in the collection view
    let kMinimumInterItemSpacingForSectionAtIndex: CGFloat = 0

    /**
     Method called upon view did load. It sets up the collection view, sets up the view model, starts the loading animation at app launch, determines the feed model, and observes when the application becomes active
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
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
            defaultTopBarView.isHidden = true
            searchTopBarView.isHidden = false
            wordTagLabel.text = query.uppercased()
            Utils.kernLabelString(wordTagLabel, spacingValue: 1.4)
            self.view.addSubview(searchTopBarView)
            alertBannerLabel.text = NSLocalizedString("Error Fetching Images, try again later.", comment: "")
        }

    }

    /**
     Method observes when the application becomes active. It does this so we can restart the loading animation
     */
    func observeWhenApplicationBecomesActive() {

        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(self,
                                       selector:#selector(FeedViewController.didBecomeActive),
                                       name:NSNotification.Name.UIApplicationDidBecomeActive,
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
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.suscribeToBluemixDataManagerNotifications()
        // ensure collection view loads correctly under different circumstances

        if tableView.numberOfRows(inSection: 1) < BluemixDataManager.SharedInstance.images.count {
            logoImageView.startRotating(1)
            viewModel.repullForNewData()
        } else {
            reloadDataInCollectionView()
        }

        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default

        self.navigationController?.setNavigationBarHidden(true, animated: false)
        tryToStartLoadingAnimation()

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if searchQuery != nil && self.isMovingToParentViewController &&
            tableView.numberOfRows(inSection: 1) < 1 && noResultsLabel.isHidden {
            SVProgressHUD.show()
        } else {
            tryToShowImageFeedAlert()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.unsubscribeFromBluemixDataManagerNotifications()
    }

    /**
     Method called as a callback from the OS when the app receives a memory warning from the OS
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
     Method sets up the table view with various initial properties
     */
    func setupTableView() {

        Utils.registerNibWith("ImageFeedTableViewCell", tableView: tableView)

        Utils.registerNibWith("ImagesCurrentlyUploadingImageFeedTableViewCell", tableView: tableView)

        let nib: UINib? = UINib(nibName: "EmptyFeedFooterView", bundle: Bundle.main)
        tableView.register(nib, forHeaderFooterViewReuseIdentifier: "EmptyFeedFooterView")

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 300

        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: #selector(FeedViewController.userTriggeredRefresh), for: UIControlEvents.valueChanged)
        self.refreshControl.isHidden = true
        self.refreshControl.tintColor = UIColor.clear

        self.tableView.addSubview(refreshControl)
    }

    /**
     Method reloads the data in the collection view. It is typically called by its view model when it receives data.
     */
    func reloadDataInCollectionView() {

        tableView.reloadData()
        tryToStopLoadingAnimation()
        self.tableView.setContentOffset(CGPoint.zero, animated: true)

        if viewModel.numberOfItemsInSection(1) > viewModel.numberOfCellsWhenUserHasNoPhotos {
            dismissImageFeedErrorAlert()
        }
    }

    /**
     Method is called when the user triggers a pull to refresh
     */
    func userTriggeredRefresh() {

        dismissImageFeedErrorAlert()
        logoImageView.startRotating(1)
        self.refreshControl.endRefreshing()
        // fixes offset of emptyCollectionViewCell
        tableView.setContentOffset(CGPoint.zero, animated: true)
        viewModel.repullForNewData()

    }

    /**
     Method starts the loading animation at app launch
     */
    func startLoadingAnimationAtAppLaunch() {
        if viewModel.shouldBeginLoadingAtAppLaunch() {
            DispatchQueue.main.async {
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
     Display an error alert when we couldn't fetch images from the server
     */
    func displayImageFeedErrorAlert() {

        if self.isVisible() {

            noResultsLabel.isHidden = true
            self.topAlertConstraint.constant = self.alertBannerView.frame.size.height - 20
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 15, options: UIViewAnimationOptions(), animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
            failedToPresentImageFeedErrorAlert = false

        } else {
            failedToPresentImageFeedErrorAlert = true
        }
    }

    func dismissImageFeedErrorAlert() {
        if self.topAlertConstraint.constant > 0 {
            self.topAlertConstraint.constant = 0
            UIView.animate(withDuration: 0.2, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }


    /**
     Method will be called in viewDidAppear if we were unable to present this alert because the FeedViewController wasn't visible
     */
    fileprivate func tryToShowImageFeedAlert() {

        if failedToPresentImageFeedErrorAlert {
            displayImageFeedErrorAlert()
        }

    }

    /**
     Method is caleld when the search icon in the top right corner is pressed

     - parameter sender: Any
     */
    @IBAction func transitionToSearch(_ sender: Any) {
        if let vc = Utils.vcWithNameFromStoryboardWithName("SearchViewController", storyboardName: "Feed") as? SearchViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    /**
     Method pops the vc on the navigation stack when the back button is pressed when search results are shown

     - parameter sender: Any
     */
    @IBAction func popVC(_ sender: Any) {
        SVProgressHUD.dismiss()
        let _ = self.navigationController?.popViewController(animated: true)
    }
}

extension FeedViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSectionsInCollectionView()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItemsInSection(section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = viewModel.setUpTableViewCell(indexPath, tableView: tableView)
        if let cell = cell as? ImageFeedTableViewCell {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(textViewTapped(sender:)))
            tapGesture.numberOfTapsRequired = 1
            cell.captionTextView.addGestureRecognizer(tapGesture)
        }
        return cell
    }

    func textViewTapped(sender: UITapGestureRecognizer) {

        let tapLocation = sender.location(in: self.tableView)
        if let indexPath = self.tableView.indexPathForRow(at: tapLocation), let cell = self.tableView.cellForRow(at: indexPath) as? ImageFeedTableViewCell {

            var image = viewModel.imageDataArray[indexPath.row]
            image.isExpanded = !image.isExpanded
            viewModel.imageDataArray[indexPath.row] = image
            if cell.setCaptionText(image: image) {

                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }

        }
    }

}

extension FeedViewController: UITableViewDelegate {
    // TODO: move stuff to view model
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        if let imageDetailViewModel = viewModel.prepareImageDetailViewModelForSelectedCellAtIndexPath(indexPath),
            let imageDetailVC = Utils.vcWithNameFromStoryboardWithName("ImageDetailViewController", storyboardName: "Feed") as? ImageDetailViewController {

            imageDetailVC.viewModel = imageDetailViewModel
            self.navigationController?.pushViewController(imageDetailVC, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 1, viewModel.imageDataArray.count == 0, let sectionFooter = tableView.dequeueReusableHeaderFooterView(withIdentifier: "EmptyFeedFooterView") as? EmptyFeedFooterView {
            sectionFooter.userHasNoImagesLabel.text = sectionFooter.kUserHasNoImagesLabelText
            return sectionFooter
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 1, viewModel.imageDataArray.count == 0 {
            return tableView.frame.size.height
        }
        return 0
    }
}

//ViewModel -> ViewController Communication
extension FeedViewController {

    /**
     Method handles view model notifications given to this view controller from its view model

     - parameter feedViewModelNotification: FeedviewModelNotifications
     */
    func handleFeedViewModelNotifications(_ feedViewModelNotification: FeedViewModelNotification) {

        if feedViewModelNotification == FeedViewModelNotification.reloadCollectionView {
            reloadDataInCollectionView()
            if searchQuery != nil {
                SVProgressHUD.dismiss()
            }
        } else if feedViewModelNotification == FeedViewModelNotification.uploadingPhotoStarted {
            tableView.reloadData()
            tableView.contentOffset.y = 0
            dismissImageFeedErrorAlert()
            tryToStartLoadingAnimation()
        } else if feedViewModelNotification == FeedViewModelNotification.noSearchResults {
            SVProgressHUD.dismiss()
            noResultsLabel.isHidden = self.topAlertConstraint.constant > 0
        } else if feedViewModelNotification == FeedViewModelNotification.getImagesServerFailure {
            reloadDataInCollectionView()
            displayImageFeedErrorAlert()
        }

    }
}
