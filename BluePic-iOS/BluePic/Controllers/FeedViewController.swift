/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/


import UIKit

class FeedViewController: UIViewController {
    
    @IBOutlet weak var logoImageView: UIImageView!

    @IBOutlet weak var outerEyeImageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var outerEyeImageViewTopSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewTopSpaceConstraint: NSLayoutConstraint!
    
    var viewModel : FeedViewModel!
    var refreshControl:UIRefreshControl!
    
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
        // Dispose of any resources that can be recreated.
    }
    
    
    /**
     Method sets up the view model
     */
    func setupViewModel(){
        viewModel = FeedViewModel(passFeedViewModelNotificationToTabBarVCCallback: handleFeedViewModelNotifications)
    }
    
    
    /**
     Method sets up the collection view with various initial properties
     */
    func setupCollectionView(){
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        Utils.registerNibWithCollectionView("EmptyFeedCollectionViewCell", collectionView: collectionView)
        
        Utils.registerNibWithCollectionView("ImageFeedCollectionViewCell", collectionView: collectionView)
        
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
    }

    
    /**
     Method reloads the data in the collection view. It is typically called by its view model when it receives data.
     */
    func reloadDataInCollectionView(){
        
        collectionView.reloadData()
        logoImageView.stopRotating()
        
    }
    
    
    /**
     Method is called when the user triggers a pull to refresh
     */
    func userTriggeredRefresh(){
        
        logoImageView.startRotating(1)
        self.refreshControl.endRefreshing()
        
        viewModel.repullForNewData()
        
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


