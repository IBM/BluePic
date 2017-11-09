/**
 * Copyright IBM Corporation 2016, 2017
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

//used to inform the Feed View Controller of notifications
enum FeedViewModelNotification {

    //called when there is new data in the pictureDataArray, used to tell the Feed VC to refresh it's data in the table view
    case reloadTableView

    //called when a photo is uploading
    case uploadingPhotoStarted

    //called when no images were pulled from server because there was no connection with server
    case getImagesServerFailure

    //called when there are no search results for a particular searchQuery
    case noSearchResults
}

class FeedViewModel: NSObject {

    //array that holds all the image data objects we used to populate the Feed VC's table view
    var imageDataArray = [Image]()

    //callback used to inform the Feed VC of notifications from its view model
    var notifyFeedVC : ((_ feedViewModelNotification: FeedViewModelNotification) -> Void)!

    //string that holds the search query if it is present, meaning we are looking at search results
    var searchQuery: String?

    //constant that defines the number of cells there is when the user has no photos
    var numberOfCellsWhenUserHasNoPhotos = 0

    //constant that defines the number of sections there are in the table view
    let kNumberOfSectionsInTableView = 2

    /**
      Method called upon init. It sets a callback to inform the VC of new notification

     - parameter notifyFeedVC: ((feedViewModelNotification : FeedViewModelNotification)->()
     - parameter searchQuery:  String?

     - returns: FeedViewModel
     */
    init(notifyFeedVC : @escaping ((_ feedViewModelNotification: FeedViewModelNotification) -> Void), searchQuery: String?) {
        super.init()

        //save callback to notify Feed View Controller of events
        self.notifyFeedVC = notifyFeedVC
        self.searchQuery = searchQuery

        //Fetch images on app launch
        BluemixDataManager.SharedInstance.getImages()

        //if this view controller needs to show search results
        if let query = searchQuery {
            numberOfCellsWhenUserHasNoPhotos = 0
            BluemixDataManager.SharedInstance.getImagesByTags([query], callback: handleSearchResultsResponse)
        }
        //doesn't need to show search results so set up like a normal feed vc
        else {
            //Grab any data from BluemixDataManager if it has any and then tell view controller to reload its table view
            numberOfCellsWhenUserHasNoPhotos = 1
            updateImageDataArrayAndNotifyViewControllerToReloadTableView()
        }

    }

    /**
    Method suscribes to all event notifications that come from the Bluemix DataManager
     */
    func suscribeToBluemixDataManagerNotifications() {

        NotificationCenter.default.addObserver(self, selector: #selector(FeedViewModel.updateImageDataArrayAndNotifyViewControllerToReloadTableView), name: .imagesRefreshed, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(FeedViewModel.repullForNewData), name: .imageUploadSuccess, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(FeedViewModel.notifyViewControllerToTriggerLoadingAnimation), name: .imageUploadBegan, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(FeedViewModel.handleImageUploadFailure), name: .imageUploadFailure, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(FeedViewModel.notifyViewControllerGetImagesServerError), name: .getAllImagesFailure, object: nil)

    }

    func unsubscribeFromBluemixDataManagerNotifications() {
        NotificationCenter.default.removeObserver(self, name: .imagesRefreshed, object: nil)
        NotificationCenter.default.removeObserver(self, name: .imageUploadSuccess, object: nil)
        NotificationCenter.default.removeObserver(self, name: .imageUploadBegan, object: nil)
        NotificationCenter.default.removeObserver(self, name: .imageUploadFailure, object: nil)
        NotificationCenter.default.removeObserver(self, name: .getAllImagesFailure, object: nil)
    }

    /**
     Method will update the image data array and notify the feed vc to refresh if this vc is setup like a normal feed vc and doesn't show search results
     */
    @objc func updateImageDataArrayAndNotifyViewControllerToReloadTableView() {

        if !isShowingSearchResults() {
            self.imageDataArray = BluemixDataManager.SharedInstance.images
            self.notifyViewControllerToTriggerReloadTableView()
        }
    }

    /**
     Method handles if there is an image upload failure if this vc is set up like a normal feed vc and doesn't show search results
     */
    @objc func handleImageUploadFailure() {

        if !isShowingSearchResults() {
            self.notifyViewControllerToTriggerReloadTableView()
        }

    }

}

//methods related to if we have to display search results
extension FeedViewModel {

    /**
     Method returns true if the feed vc is showing search results, false if it is set up like a normal feed vc

     - returns: Bool
     */
    fileprivate func isShowingSearchResults() -> Bool {

        if searchQuery != nil {
            return true
        } else {
            return false
        }
    }

    /**
     Method is called when there is a response receieving for search for images by tags. This method handles this response and will either trigger the "there are no images found" message or update the imageDataArray with the search results and tell the feed vc to reload its table view

     - parameter images: [Image]?
     */
    fileprivate func handleSearchResultsResponse(_ images: [Image]?) {

        if let images = images {
            imageDataArray = images

            if imageDataArray.count < 1 {
                self.notifiyViewControllerToTriggerAlert()
            } else {
                self.notifyViewControllerToTriggerReloadTableView()
            }
        } else {
            self.notifiyViewControllerToTriggerAlert()
        }

    }

}

//ViewController -> ViewModel Communication
extension FeedViewModel {

    func shouldStartLoadingAnimation() -> Bool {

        if BluemixDataManager.SharedInstance.imagesCurrentlyUploading.count > 0 || !BluemixDataManager.SharedInstance.hasReceievedInitialImages {
            return true
        } else {
            return false
        }

    }

    func shouldStopLoadingAnimation() -> Bool {

        if BluemixDataManager.SharedInstance.imagesCurrentlyUploading.count == 0 {
            return true
        } else {
            return false
        }

    }

    /**
     Method returns if the feed vc should begin loading or not upon app launch

     - returns: Bool
     */
    func shouldBeginLoadingAtAppLaunch() -> Bool {
        return !BluemixDataManager.SharedInstance.hasReceievedInitialImages
    }

    /**
     Method will either research for images by tag or get all images depending on if the feed vc is setup like a normal feed vc or to show search results
     */
    @objc func repullForNewData() {
        if let query = self.searchQuery {
            BluemixDataManager.SharedInstance.getImagesByTags([query], callback: handleSearchResultsResponse)
        } else {
            BluemixDataManager.SharedInstance.getImages()
        }
    }

    /**
     Method returns the number of sections in the table view

     - returns: Int
     */
    func numberOfSectionsInTableView() -> Int {
        return kNumberOfSectionsInTableView
    }

    /**
     Method returns the number of items in a section

     - parameter section: Int

     - returns: Int
     */
    func numberOfItemsInSection(_ section: Int) -> Int {
        //if the section is 0, then it depends on how many items are in imagesCurrentlyUploading array of the BluemixDataManager
        if section == 0 {
            if isShowingSearchResults() {
                return 0
            } else {
                return BluemixDataManager.SharedInstance.imagesCurrentlyUploading.count
            }
        }
            // if the section is 1, then it depends how many items are in the imageDataArray
        else {

            if(imageDataArray.count == 0) && BluemixDataManager.SharedInstance.hasReceievedInitialImages {
                return numberOfCellsWhenUserHasNoPhotos
            } else {
                return imageDataArray.count
            }
        }
    }

    /// Method to build UITableViewCells, either a currently uploading cell or a standard image feed cell
    ///
    /// - parameter indexPath: indexPath of cell to load
    /// - parameter tableView: tableView cell will be placed on
    ///
    /// - returns: a tableview cell
    func setUpTableViewCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {

        //Section 0 corresponds to showing ImagesCurrentlyUploadingImageFeedTableViewCell table view cells. These cells show when there are images in the imagesCurrentlyUploading array of the BluemixDataManager
        if indexPath.section == 0 {

            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ImagesCurrentlyUploadingImageFeedTableViewCell", for: indexPath) as? ImagesCurrentlyUploadingImageFeedTableViewCell else {
                return UITableViewCell()
            }

            let image = BluemixDataManager.SharedInstance.imagesCurrentlyUploading[indexPath.row]

            cell.setupData(image.image, caption: image.caption)

            return cell

        }
        //section 1 corresponds to showing image feed cells
        else if imageDataArray.count != 0 {

            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ImageFeedTableViewCell", for: indexPath) as? ImageFeedTableViewCell else {
                return UITableViewCell()
            }

            let image = imageDataArray[indexPath.row]
            cell.setupDataWith(image)

            cell.layer.shouldRasterize = true
            cell.layer.rasterizationScale = UIScreen.main.scale

            return cell
        } else {
            return UITableViewCell()
        }
    }

    /// Creates footer view to show when there is no image data
    ///
    /// - parameter section:   section to display view in
    /// - parameter tableView: tableView to place view on.
    ///
    /// - returns: A view if applicable
    func viewForFooterInSection(_ section: Int, tableView: UITableView) -> UIView? {
        if section == 1, BluemixDataManager.SharedInstance.hasReceievedInitialImages, imageDataArray.count == 0, searchQuery == nil, let sectionFooter = tableView.dequeueReusableHeaderFooterView(withIdentifier: "EmptyFeedFooterView") as? EmptyFeedFooterView {
            sectionFooter.userHasNoImagesLabel.text = sectionFooter.kUserHasNoImagesLabelText
            return sectionFooter
        }
        return nil
    }

    /// Generates height for footer view
    ///
    /// - parameter section:   section to display view in
    /// - parameter tableView: tableView to place view on.
    ///
    /// - returns: height as CGFloat
    func heightForFooterInSection(_ section: Int, tableView: UITableView) -> CGFloat {
        if section == 1, BluemixDataManager.SharedInstance.hasReceievedInitialImages, imageDataArray.count == 0, searchQuery == nil {
            return tableView.frame.size.height
        }
        return 0
    }

    /**
     Method return an ImageDetailViewModel for the image at the indexPath parameter

     - parameter indexPath: IndexPath

     - returns: ImageDetailViewModel?
     */
    func prepareImageDetailViewModelForSelectedCellAtIndexPath(_ indexPath: IndexPath) -> ImageDetailViewModel? {

        if (imageDataArray.count - 1 ) >= indexPath.row {

            let viewModel = ImageDetailViewModel(image: imageDataArray[indexPath.row])

            return viewModel

        } else {
            return nil
        }
    }

}

//View Model -> ViewController Communication
extension FeedViewModel {

    /**
     Method notifies the feed vc to trigger the loading aniamtion when an image has began uploading
     */
    @objc func notifyViewControllerToTriggerLoadingAnimation() {

        if !isShowingSearchResults() {
            DispatchQueue.main.async {
                self.notifyFeedVC(FeedViewModelNotification.uploadingPhotoStarted)
            }
        }
    }

    /**
     Method notifies the feed vc to reload the table view
     */
    func notifyViewControllerToTriggerReloadTableView() {
        DispatchQueue.main.async {
            self.notifyFeedVC(FeedViewModelNotification.reloadTableView)
        }
    }

    /**
     Method notifies the feed vc that app failed to get images from server, handle appropriately
     */
    @objc func notifyViewControllerGetImagesServerError() {
        DispatchQueue.main.async {
            self.notifyFeedVC(FeedViewModelNotification.getImagesServerFailure)
        }
    }

    /**
     Method notifies the feed vc that there were no search results
     */
    func notifiyViewControllerToTriggerAlert() {
        DispatchQueue.main.async {
            self.notifyFeedVC(FeedViewModelNotification.noSearchResults)
        }
    }
}
