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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        setupViewModel()
 
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    func setupViewModel(){
        viewModel = FeedViewModel(passFeedViewModelNotificationToTabBarVCCallback: handleFeedViewModelNotifications)
    }
    
    
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
    
    
    
    func handleFeedViewModelNotifications(feedViewModelNotification : FeedViewModelNotification){
        
        if(feedViewModelNotification == FeedViewModelNotification.RefreshCollectionView){
            
            reloadDataInCollectionView()
        }
        else if(feedViewModelNotification == FeedViewModelNotification.StartLoadingAnimationForAppLaunch){
        
            self.logoImageView.image = UIImage(named: "shutter")
            self.logoImageView.startRotating(1)
        }
    }

    
    func reloadDataInCollectionView(){
        
        collectionView.reloadData()
        logoImageView.stopRotating()
        
    }
    
    
    
    func userTriggeredRefresh(){
        
        logoImageView.startRotating(1)
        self.refreshControl.endRefreshing()
        
        viewModel.repullForNewData()
        
    }

}


extension FeedViewController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return viewModel.setUpCollectionViewCell(indexPath, collectionView : collectionView)
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItemsInSection(section)
    }
    
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return viewModel.numberOfSectionsInCollectionView()
    }
    
}



extension FeedViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

        return viewModel.sizeForItemAtIndexPath(indexPath, collectionView: collectionView)
    }
    
}


