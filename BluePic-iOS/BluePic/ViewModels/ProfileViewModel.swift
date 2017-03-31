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

class ProfileViewModel: NSObject {

    //array that holds all that pictures that are displayed in the table view
    var imageDataArray = [Image]()

    //callback used to tell the ProfileViewController when to refresh its table view
    fileprivate var refreshVCCallback : (() -> Void)!

    //constant that represents the number of sections in the table view
    fileprivate let kNumberOfSectionsInTableView = 1

    //constant represents the height of the "info view" - the view that says the user's name and number of photos
    fileprivate let kHeaderViewInfoViewHeight: CGFloat = 105

    /**
     Method called upon init, it sets up the method used to inform the profile vc of events, suscribes to BlueMixDataManager notifications, and updates the image data araay and tells the profile vc to reload its table view

     - parameter refreshVCCallback: (()->())

     - returns:
     */
    init(refreshVCCallback : @escaping (() -> Void)) {
       super.init()

        self.refreshVCCallback  = refreshVCCallback

        suscribeToBluemixDataManagerNotifications()

        updateImageArrayAndNotifyViewControllerToReloadTableView()

    }

    /**
     Method suscribes to the event notifications from the BluemixDataManager
     */
    func suscribeToBluemixDataManagerNotifications() {

         NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewModel.updateImageArrayAndNotifyViewControllerToReloadTableView), name: .imagesRefreshed, object: nil)

    }

    /**
     Method updates the imageDataArray to the latest currentUserImages from the BluemixDataManager and then tells the profile vc to reload its table view
     */
    func updateImageArrayAndNotifyViewControllerToReloadTableView() {

        self.imageDataArray = BluemixDataManager.SharedInstance.currentUserImages

        self.callRefreshCallBack()

    }

    /**
     Method tells the profile view controller to reload its tableView
     */
    func callRefreshCallBack() {
        if let callback = refreshVCCallback {
            DispatchQueue.main.async {
                callback()
            }
        }
    }

}

//View Controller -> View Model Communication
extension ProfileViewModel {

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

        if imageDataArray.count == 0 {
            return 0
        }
        return imageDataArray.count
    }

    /// Sets up table view cell, populating with image data
    ///
    /// - parameter indexPath: indexPath for cell in tableView
    /// - parameter tableView: tableView to put cell in
    ///
    /// - returns: populated table view cell
    func setUpTableViewCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {

            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileTableViewCell", for: indexPath) as? ProfileTableViewCell else {
                return UITableViewCell()
            }

            let image = imageDataArray[indexPath.row]

            cell.setupDataWith(image)

            cell.layer.shouldRasterize = true
            cell.layer.rasterizationScale = UIScreen.main.scale
            cell.backgroundColor = UIColor.clear

            return cell

    }

    /// Generates view for header containing profile view and photo count
    ///
    /// - parameter section:   section for header
    /// - parameter tableView: tableview for header
    ///
    /// - returns: A view if applicable
    func viewForHeaderInSection(_ section: Int, tableView: UITableView) -> UIView? {
        if let sectionHeader = tableView.dequeueReusableHeaderFooterView(withIdentifier: "ProfileHeaderView") as? ProfileHeaderView {
            sectionHeader.setupData(CurrentUser.fullName, numberOfShots: imageDataArray.count, profilePictureURL: CurrentUser.facebookProfilePictureURL)
            sectionHeader.contentView.backgroundColor = UIColor.clear
            return sectionHeader
        }
        return nil
    }

    /// Generates height for header view
    ///
    /// - parameter section:   section to display view in
    /// - parameter tableView: tableView to place view on.
    ///
    /// - returns: height as CGFloat
    func heightForHeaderInSection(_ section: Int, tableView: UITableView) -> CGFloat {
        return tableView.frame.size.height / 2 + kHeaderViewInfoViewHeight
    }

    /// Creates footer view to show when there is no image data
    ///
    /// - parameter section:   section to display view in
    /// - parameter tableView: tableView to place view on.
    ///
    /// - returns: A view if applicable
    func viewForFooterInSection(_ section: Int, tableView: UITableView) -> UIView? {
        if BluemixDataManager.SharedInstance.hasReceievedInitialImages, imageDataArray.count == 0, let sectionFooter = tableView.dequeueReusableHeaderFooterView(withIdentifier: "EmptyFeedFooterView") as? EmptyFeedFooterView {
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
        if BluemixDataManager.SharedInstance.hasReceievedInitialImages, imageDataArray.count == 0 {
            return tableView.frame.size.height / 2 - kHeaderViewInfoViewHeight
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
        }
        return nil
    }
}
