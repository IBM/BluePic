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

//used to inform the Feed View Controller of notifications
enum FeedViewModelNotification {

    //called when there is new data in the pictureDataArray, used to tell the Feed VC to refresh it's data in the collection view
    case reloadCollectionView

    //called when a photo is uploading
    case uploadingPhotoStarted

    //called when no images were pulled from server because there was no connection with server
    case getImagesServerFailure

    //called when there are no search results for a particular searchQuery
    case noSearchResults
}

class FeedViewModel: NSObject {

    //array that holds all the image data objects we used to populate the Feed VC's collection view
    var imageDataArray = [Image]()

    //callback used to inform the Feed VC of notifications from its view model
    var notifyFeedVC : ((_ feedViewModelNotification: FeedViewModelNotification)->())!

    //string that holds the search query if it is present, meaning we are looking at search results
    var searchQuery: String?

    //constant that represents the height of the info view in the collection view cell that shows the photos caption and photographer name
    let kCollectionViewCellInfoViewHeight: CGFloat = 76

    //constant that represents the height of the ImagesCurrentlyUploadingImageFeedCollectionViewCell
    let kPictureUploadCollectionViewCellHeight: CGFloat = 60

    //constant that represents the limit of how tall a collection view cell's height can be
    let kCollectionViewCellHeightLimit: CGFloat = 480

    //constant that represents a value added to the height of the EmptyFeedCollectionViewCell when its given a size in the sizeForItemAtIndexPath method, this value allows the collection view to scroll
    let kEmptyFeedCollectionViewCellBufferToAllowForScrolling: CGFloat = 1

    //constant that defines the number of cells there is when the user has no photos
    var numberOfCellsWhenUserHasNoPhotos = 0

    //constant that defines the number of sections there are in the collection view
    let kNumberOfSectionsInCollectionView = 2


    /**
      Method called upon init. It sets a callback to inform the VC of new notification

     - parameter notifyFeedVC: ((feedViewModelNotification : FeedViewModelNotification)->()
     - parameter searchQuery:  String?

     - returns: FeedViewModel
     */
    init(notifyFeedVC : @escaping ((_ feedViewModelNotification: FeedViewModelNotification)->()), searchQuery: String?) {
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
            //Grab any data from BluemixDataManager if it has any and then tell view controller to reload its collection view
            numberOfCellsWhenUserHasNoPhotos = 1
            updateImageDataArrayAndNotifyViewControllerToReloadCollectionView()
        }

    }

    /**
    Method suscribes to all event notifications that come from the Bluemix DataManager
     */
    func suscribeToBluemixDataManagerNotifications() {

        NotificationCenter.default.addObserver(self, selector: #selector(FeedViewModel.updateImageDataArrayAndNotifyViewControllerToReloadCollectionView), name: NSNotification.Name(rawValue: BluemixDataManagerNotification.ImagesRefreshed.rawValue), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(FeedViewModel.repullForNewData), name: NSNotification.Name(rawValue: BluemixDataManagerNotification.ImageUploadSuccess.rawValue), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(FeedViewModel.notifyViewControllerToTriggerLoadingAnimation), name: NSNotification.Name(rawValue: BluemixDataManagerNotification.ImageUploadBegan.rawValue), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(FeedViewModel.handleImageUploadFailure), name: NSNotification.Name(rawValue: BluemixDataManagerNotification.ImageUploadFailure.rawValue), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(FeedViewModel.notifyViewControllerGetImagesServerError), name: NSNotification.Name(rawValue: BluemixDataManagerNotification.GetAllImagesFailure.rawValue), object: nil)

    }

    func unsubscribeFromBluemixDataManagerNotifications() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: BluemixDataManagerNotification.ImagesRefreshed.rawValue), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: BluemixDataManagerNotification.ImageUploadSuccess.rawValue), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: BluemixDataManagerNotification.ImageUploadBegan.rawValue), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: BluemixDataManagerNotification.ImageUploadFailure.rawValue), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: BluemixDataManagerNotification.GetAllImagesFailure.rawValue), object: nil)
    }

    /**
     Method will update the image data array and notify the feed vc to refresh if this vc is setup like a normal feed vc and doesn't show search results
     */
    func updateImageDataArrayAndNotifyViewControllerToReloadCollectionView() {

        if !isShowingSearchResults() {
            self.imageDataArray = BluemixDataManager.SharedInstance.images
            self.notifyViewControllerToTriggerReloadCollectionView()
        }
    }

    /**
     Method handles if there is an image upload failure if this vc is set up like a normal feed vc and doesn't show search results
     */
    func handleImageUploadFailure() {

        if !isShowingSearchResults() {
            self.notifyViewControllerToTriggerReloadCollectionView()
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
     Method is called when there is a response receieving for search for images by tags. This method handles this response and will either trigger the "there are no images found" message or update the imageDataArray with the search results and tell the feed vc to reload its collection view

     - parameter images: [Image]?
     */
    fileprivate func handleSearchResultsResponse(_ images: [Image]?) {

        if let images = images {
            imageDataArray = images

            if imageDataArray.count < 1 {
                self.notifiyViewControllerToTriggerAlert()
            } else {
                self.notifyViewControllerToTriggerReloadCollectionView()
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
    func repullForNewData() {
        if let query = self.searchQuery {
            BluemixDataManager.SharedInstance.getImagesByTags([query], callback: handleSearchResultsResponse)
        } else {
            BluemixDataManager.SharedInstance.getImages()
        }
    }

    /**
     Method returns the number of sections in the collection view

     - returns: Int
     */
    func numberOfSectionsInCollectionView() -> Int {
        return kNumberOfSectionsInCollectionView
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

    /**
     Method returns the size for item at index path

     - parameter indexPath: NSIndexPath
     - parameter collectionView: UICollectionViewcell

     - returns: CGSize
     */
    func sizeForItemAtIndexPath(_ indexPath: IndexPath, collectionView: UICollectionView) -> CGSize {

        //Section 0 corresponds to showing ImagesCurrentlyUploadingImageFeedCollectionViewCell collection view cells. These cells show when there are images in the imagesCurrentlyUploading array of the BluemixDataManager
        if (indexPath as NSIndexPath).section == 0 {
            return CGSize(width: collectionView.frame.width, height: kPictureUploadCollectionViewCellHeight)
        }
            //section 1 corresponds to either the empty feed collection view cell or the standard image feed collection view cell depending on how many images are in the image data array
        else {

            //return size for empty feed collection view cell
            if imageDataArray.count == 0 {
                return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
            }
                //return size for image feed collection view cell
            else {

                let image = imageDataArray[(indexPath as NSIndexPath).row]

                let ratio = image.height / image.width

                var height = collectionView.frame.width * ratio

                if height > kCollectionViewCellHeightLimit {
                    height = kCollectionViewCellHeightLimit
                }

                return CGSize(width: collectionView.frame.width, height: height + kCollectionViewCellInfoViewHeight)

            }
        }
    }

    /**
     Method sets up the collection view for indexPath. If the the imgageDataArray is 0, then it shows the EmptyFeedCollectionViewCell

     - parameter indexPath:      indexPath
     - parameter collectionView: UICollectionView

     - returns: UICollectionViewCell
     */
    func setUpCollectionViewCell(_ indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {

        //Section 0 corresponds to showing ImagesCurrentlyUploadingImageFeedCollectionViewCell collection view cells. These cells show when there are images in the imagesCurrentlyUploading array of the BluemixDataManager
        if (indexPath as NSIndexPath).section == 0 {

            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImagesCurrentlyUploadingImageFeedCollectionViewCell", for: indexPath) as? ImagesCurrentlyUploadingImageFeedCollectionViewCell else {
                return UICollectionViewCell()
            }

            let image = BluemixDataManager.SharedInstance.imagesCurrentlyUploading[(indexPath as NSIndexPath).row]

            cell.setupData(image.image, caption: image.caption)

            return cell

        }
            //section 1 corresponds to either the empty feed collection view cell or the standard image feed collection view cell depending on how many images are in the image data array
        else {

            if imageDataArray.count == 0 && searchQuery == nil {

                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmptyFeedCollectionViewCell", for: indexPath) as? EmptyFeedCollectionViewCell else {
                    return UICollectionViewCell()
                }

                return cell

            } else {

                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageFeedCollectionViewCell", for: indexPath) as? ImageFeedCollectionViewCell else {
                    return UICollectionViewCell()
                }

                let image = imageDataArray[(indexPath as NSIndexPath).row]
                cell.setupDataWith(image)

                cell.layer.shouldRasterize = true
                cell.layer.rasterizationScale = UIScreen.main.scale

                return cell
            }
        }
    }


    /**
     Method return an ImageDetailViewModel for the image at the indexPath parameter

     - parameter indexPath: NSIndexPath

     - returns: ImageDetailViewModel?
     */
    func prepareImageDetailViewModelForSelectedCellAtIndexPath(_ indexPath: IndexPath) -> ImageDetailViewModel? {

        if (imageDataArray.count - 1 ) >= (indexPath as NSIndexPath).row {

            let viewModel = ImageDetailViewModel(image: imageDataArray[(indexPath as NSIndexPath).row])

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
    func notifyViewControllerToTriggerLoadingAnimation() {

        if !isShowingSearchResults() {
            DispatchQueue.main.async {
                self.notifyFeedVC(FeedViewModelNotification.uploadingPhotoStarted)
            }
        }
    }

    /**
     Method notifies the feed vc to reload the collection view
     */
    func notifyViewControllerToTriggerReloadCollectionView() {
        DispatchQueue.main.async {
            self.notifyFeedVC(FeedViewModelNotification.reloadCollectionView)
        }
    }

    /**
     Method notifies the feed vc that app failed to get images from server, handle appropriately
     */
    func notifyViewControllerGetImagesServerError() {
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
