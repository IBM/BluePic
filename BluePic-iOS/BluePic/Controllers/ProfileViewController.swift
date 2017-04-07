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

    //the table view that displays images for the user
    @IBOutlet weak var tableView: UITableView!

    //view model that will keep state and handle data for the ProfileViewController
    var viewModel: ProfileViewModel!

    //this is the header view that represents the user's "cover photo" at the top of the view
    var headerImageView: UIImageView!

    //view that is shown when the status bar starts to overlap with the user's profile picture
    var statusBarBackgroundView: UIView!

    //constant that represents the height of the image view that represents the user's "cover photo"
    let kHeaderImageViewHeight: CGFloat = 375

    //constant that represents the rate that the scroll view scrolls
    let kParalaxImageViewScrollRate: CGFloat = 0.50

    //constant that represents the duration it takes to fade the statusBarBackgroundView in
    let kStatusBarBackgroundViewFadeDuration: TimeInterval = 0.3

    //constant that represents the height of the profile picture image view
    let kHeightOfProfilePictureImageView: CGFloat = 75

    /**
     Method called upon view did load. It sets up the view model, sets up the table view, sets up the head view, and sets up the status bar background view
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        setupViewModel()

        setupTableView()

        setupHeaderView()

        setupStatusBarBackgroundView()

    }

    /**
     Method called upon view will appear, it sets the status bar to black

     - parameter animated: Bool
     */
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default
    }

    /**
     Method called when the app receives a memory warning from the OS
     */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    /**
     Method called sets up the viewModel and passes it a method to call when there is new data and we need to reload the table view of the profile vc
     */
    func setupViewModel() {
        viewModel = ProfileViewModel(refreshVCCallback: reloadDataInTableView)
    }

    /**
     Method sets up the status bar background view
     */
    func setupStatusBarBackgroundView() {

        let effect = UIBlurEffect(style: UIBlurEffectStyle.light)

        let viewWithBlurredBackground = UIVisualEffectView(effect: effect)
        viewWithBlurredBackground.frame = UIApplication.shared.statusBarFrame
        viewWithBlurredBackground.alpha = 1.0

        statusBarBackgroundView = UIView(frame: UIApplication.shared.statusBarFrame)
        statusBarBackgroundView .backgroundColor = UIColor.clear
        statusBarBackgroundView .alpha = 0.0
        statusBarBackgroundView .addSubview(viewWithBlurredBackground)

        self.view.addSubview(statusBarBackgroundView)

    }

    /**
     Method animates in the status bar background view

     - parameter isInOrOut: Bool
     */
    func animateInStatusBarBackgroundView(_ isInOrOut: Bool) {

        var alpha: CGFloat = 0.0

        if isInOrOut {
            alpha = 1.0
        }

        UIView.animate(withDuration: kStatusBarBackgroundViewFadeDuration, animations: {
            self.statusBarBackgroundView.alpha = alpha
        })

    }

    /**
    Method sets up the header view with initial properties
     */
    func setupHeaderView() {

        headerImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: kHeaderImageViewHeight))

        headerImageView.contentMode = UIViewContentMode.scaleAspectFill

        headerImageView.image = UIImage(named: "profileBackground")

        headerImageView.clipsToBounds = true

        self.view.addSubview(headerImageView)
        self.view.insertSubview(headerImageView, belowSubview: tableView)

    }

    /**
     Method sets up the table view with various initial properties
     */
    func setupTableView() {

        Utils.registerNibWith("ProfileTableViewCell", tableView: tableView)

        let nibHeader: UINib? = UINib(nibName: "ProfileHeaderView", bundle: Bundle.main)
        tableView.register(nibHeader, forHeaderFooterViewReuseIdentifier: "ProfileHeaderView")

        let nibFooter: UINib? = UINib(nibName: "EmptyFeedFooterView", bundle: Bundle.main)
        tableView.register(nibFooter, forHeaderFooterViewReuseIdentifier: "EmptyFeedFooterView")

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 300
        tableView.backgroundColor = UIColor.clear
    }

    /**
     Method reloads the data in the table view
     */
    func reloadDataInTableView() {
        if viewModel.imageDataArray.count == 0 {
            tableView.isScrollEnabled = false
        } else {
            tableView.isScrollEnabled = true
        }
        tableView.reloadData()
    }

}

extension ProfileViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = viewModel.setUpTableViewCell(indexPath, tableView: tableView)
        if let cell = cell as? ProfileTableViewCell {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(textViewTapped(sender:)))
            tapGesture.numberOfTapsRequired = 1
            cell.captionTextView.addGestureRecognizer(tapGesture)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItemsInSection(section)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSectionsInTableView()
    }

    /// Method responsible for expanding text view if more content is present
    ///
    /// - parameter sender: tapgesture calling method
    func textViewTapped(sender: UITapGestureRecognizer) {

        let tapLocation = sender.location(in: self.tableView)
        if let indexPath = self.tableView.indexPathForRow(at: tapLocation), let cell = self.tableView.cellForRow(at: indexPath) as? ProfileTableViewCell {

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

extension ProfileViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if let imageDetailViewModel = viewModel.prepareImageDetailViewModelForSelectedCellAtIndexPath(indexPath),
            let imageDetailVC = Utils.vcWithNameFromStoryboardWithName("ImageDetailViewController", storyboardName: "Feed") as? ImageDetailViewController {

            imageDetailVC.viewModel = imageDetailViewModel
            self.navigationController?.pushViewController(imageDetailVC, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return viewModel.viewForHeaderInSection(section, tableView: tableView)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return viewModel.heightForHeaderInSection(section, tableView: tableView)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return viewModel.viewForFooterInSection(section, tableView: tableView)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return viewModel.heightForFooterInSection(section, tableView: tableView)
    }
}

extension ProfileViewController : UIScrollViewDelegate {

    /**
     Method that is called when the scrollView scrolls. When the scrollView scrolls we call the updateImageViewFrameWithScrollViewDidScroll method

     - parameter scrollView:
     */
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        checkOffSetForStatusBarBackgroundViewVisability(scrollView.contentOffset.y)
        updateImageViewFrameWithScrollViewDidScroll(scrollView.contentOffset.y)
    }

    /**
     Method is called in the scrollViewDidScroll method. It allows for paralax scrolling or the image view to stretch.

     - parameter scrollViewContentOffset:
     */
    func updateImageViewFrameWithScrollViewDidScroll(_ scrollViewContentOffset: CGFloat) {

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
    func checkOffSetForStatusBarBackgroundViewVisability(_ scrollViewContentOffset: CGFloat) {

        let headerImageViewHeight = self.view.frame.size.height/2

        let magicLine = headerImageViewHeight - kHeightOfProfilePictureImageView/2 - UIApplication.shared.statusBarFrame.size.height

        if scrollViewContentOffset >= magicLine {
            animateInStatusBarBackgroundView(true)
        } else {
            animateInStatusBarBackgroundView(false)
        }
    }
}
