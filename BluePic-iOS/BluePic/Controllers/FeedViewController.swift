/**
 * Copyright IBM Corporation 2015
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
    
    //view model of the Feed View controller. It will keep track of state and handle data for this view controller
    var viewModel : FeedViewModel!
    
    //Allows for pull down to refresh
    var refreshControl:UIRefreshControl!
    
    //Defines the minimum spacing between cells in the collection view
    let kMinimumInterItemSpacingForSectionAtIndex : CGFloat = 0
    
    
    /**
     Method called upon view did load. It sets up the collection view and sets up the view model
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        setupViewModel()
 
    }

    /**
     Method called as a callback from the OS when the app receives a memeory warning from the OS
     */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    /**
     Method sets up the view model, passes the callback we want ot be called when there are notifications from the feed view model
     */
    func setupViewModel(){
        viewModel = FeedViewModel(passFeedViewModelNotificationToFeedVCCallback: handleFeedViewModelNotifications)
    }
    
    
    /**
     Method sets up the collection view with various initial properties
     */
    func setupCollectionView(){
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        Utils.registerNibWithCollectionView("EmptyFeedCollectionViewCell", collectionView: collectionView)
        
        Utils.registerNibWithCollectionView("ImageFeedCollectionViewCell", collectionView: collectionView)
        
        Utils.registerNibWithCollectionView("PictureUploadQueueImageFeedCollectionViewCell", collectionView: collectionView)
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: "userTriggeredRefresh", forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl.hidden = true
        self.refreshControl.tintColor = UIColor.clearColor()
        
        self.collectionView.addSubview(refreshControl)
    }
    
    
    /**
     Method handles view model notifications given to this view controller from its view model
     
     - parameter feedViewModelNotification: FeedviewModelNotifications
     */
    func handleFeedViewModelNotifications(feedViewModelNotification : FeedViewModelNotification){
        
        if(feedViewModelNotification == FeedViewModelNotification.RefreshCollectionView){
            
            reloadDataInCollectionView()
        }
        else if(feedViewModelNotification == FeedViewModelNotification.StartLoadingAnimationForAppLaunch){
        
            self.logoImageView.image = UIImage(named: "shutter")
            self.logoImageView.startRotating(1)
        }
        else if(feedViewModelNotification == FeedViewModelNotification.UploadingPhotoStarted){
            
            dispatch_async(dispatch_get_main_queue()) {
                self.logoImageView.startRotating(1)
            }
        }
        else if(feedViewModelNotification == FeedViewModelNotification.UploadingPhotoFinished){
            self.logoImageView.stopRotating()
        }
        
    }

    
    /**
     Method reloads the data in the collection view. It is typically called by its view model when it receives data.
     */
    func reloadDataInCollectionView(){
        
        collectionView.reloadData()
        tryToStopLoadingAnimation()
        
        self.collectionView.setContentOffset(CGPoint.zero, animated: true)
    }
    
    
    /**
     Method is called when the user triggers a pull to refresh
     */
    func userTriggeredRefresh(){
        
        logoImageView.startRotating(1)
        self.refreshControl.endRefreshing()
        
        viewModel.repullForNewData()
        
    }
    
    
    func tryToStopLoadingAnimation(){
        
        if(CameraDataManager.SharedInstance.pictureUploadQueue.count == 0){
            
            logoImageView.stopRotating()
            
        } 
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


