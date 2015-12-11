//
//  ProfileViewController.swift
//  BluePic
//
//  Created by Nathan Hekman on 11/23/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    var viewModel : ProfileViewModel!
    var refreshControl: UIRefreshControl!
    
    var headerImageView : UIImageView!
    
    var statusBarBackgroundView : UIView!
    
    let kHeaderViewHeight : CGFloat = 480
    let kHeaderImageViewHeight : CGFloat = 375
    let kStatusBarMagicLine : CGFloat = 100
    let kParalaxImageViewScrollRate : CGFloat = 0.50
    let kStatusBarBackgroundViewFadeDuration : NSTimeInterval = 0.3
    let kHeightOfProfilePictureImageView : CGFloat = 75

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        setupViewModel()
        
        setupCollectionView()
        
        setupHeaderView()
        
        setupStatusBarBackgroundView()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func setupViewModel(){
        
        viewModel = ProfileViewModel(refreshVCCallback: reloadDataInCollectionView)
        
        
    }
    
    
    func setupStatusBarBackgroundView(){
        
        let effect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        
        let viewWithBlurredBackground = UIVisualEffectView(effect: effect)
        viewWithBlurredBackground.frame = UIApplication.sharedApplication().statusBarFrame
        viewWithBlurredBackground.alpha = 1.0
        
        statusBarBackgroundView = UIView(frame: UIApplication.sharedApplication().statusBarFrame)
        statusBarBackgroundView .backgroundColor = UIColor.clearColor()
        statusBarBackgroundView .alpha = 0.0
        statusBarBackgroundView .addSubview(viewWithBlurredBackground)
        
        self.view.addSubview(statusBarBackgroundView)
   
    }
    
    func animateInStatusBarBackgroundView(isInOrOut : Bool){
    
        var alpha : CGFloat = 0.0
        
        if(isInOrOut == true){
          
            alpha = 1.0
            
        }
        else{
            
            alpha = 0.0
            
        }
        
        UIView.animateWithDuration(kStatusBarBackgroundViewFadeDuration, animations: {
            self.statusBarBackgroundView.alpha = alpha
        })
        
    }
    
    
    func setupHeaderView(){
        
        headerImageView = UIImageView(frame: CGRectMake(0, 0, view.frame.width, kHeaderImageViewHeight))
        headerImageView.contentMode = UIViewContentMode.ScaleAspectFill
        
        headerImageView.image = UIImage(named: "photo1")
        
        
        headerImageView.clipsToBounds = true
        
        self.view.addSubview(headerImageView)
        self.view.insertSubview(headerImageView, belowSubview: collectionView)
        
    
    }
    
    
    func setupCollectionView(){
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        Utils.registerSupplementaryElementOfKindNibWithCollectionView("ProfileHeaderCollectionReusableView", kind: UICollectionElementKindSectionHeader, collectionView: collectionView)
        
        Utils.registerNibWithCollectionView("ProfileCollectionViewCell", collectionView: collectionView)
        
    }
    
    
    func userTriggeredRefresh(){
        
        
        self.refreshControl.endRefreshing()
        
        viewModel.repullForNewData()
        
    }
    
    
    func reloadDataInCollectionView(){
        
        collectionView.reloadData()
        
        
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}



extension ProfileViewController: UICollectionViewDataSource {
    
    
    /**
     Method setups up the viewForSupplementaryElementOfKind by asking the viewModel to set it up. This specifically sets up a header view on the top of the collection view to be clear so you can see the image view at the top of the collection view that is actually below the collection view.
     
     - parameter collectionView:
     - parameter kind:
     - parameter indexPath:
     
     - returns:
     */
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        return viewModel.setUpSectionHeaderViewForIndexPath(
            indexPath,
            kind: kind,
            collectionView: collectionView
        )
    }
    
    
    
    
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


extension ProfileViewController: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print(indexPath.row)
    }
    
}


extension ProfileViewController: UICollectionViewDelegateFlowLayout {
    
    /**
     Method sets the size of the section header at indexpath depending on what section it is.
     
     - parameter collectionView:
     - parameter collectionViewLayout:
     - parameter section:
     
     - returns:
     */
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
        
        let collectionWidth = collectionView.frame.size.width
        
        if(section == 0){
            return CGSizeMake(collectionWidth, kHeaderViewHeight)
        }
        else{
            return CGSizeMake(collectionWidth, 0)
        }
        
    }
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return viewModel.sizeForItemAtIndexPath(indexPath, collectionView: collectionView)
    }
    
    
    
}



extension ProfileViewController : UIScrollViewDelegate {


    /**
     Method that is called when the scrollView scrolls. When the scrollView scrolls we call the updateImageViewFrameWithScrollViewDidScroll method
     
     - parameter scrollView:
     */
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        print(scrollView.contentOffset.y)
        checkOffSetForStatusBarBackgroundViewVisability(scrollView.contentOffset.y)
        updateImageViewFrameWithScrollViewDidScroll(scrollView.contentOffset.y)
    }
    
    /**
     Method is called in the scrollViewDidScrgyoll method. This method is the secret sauce to getting the image at the top to lock to the navigation bar or to get the image to stretch.
     
     - parameter scrollViewContentOffset:
     */
    func updateImageViewFrameWithScrollViewDidScroll(scrollViewContentOffset : CGFloat) {
        
        if scrollViewContentOffset >= 0 {
            headerImageView.frame.origin.y = -(scrollViewContentOffset * kParalaxImageViewScrollRate)
        } else {
            headerImageView.frame = CGRectMake(0, 0, view.frame.width, kHeaderImageViewHeight - scrollViewContentOffset)
        }
    }
    
    
    func checkOffSetForStatusBarBackgroundViewVisability(scrollViewContentOffset : CGFloat){
        
        let magicLine = kHeaderImageViewHeight - kHeightOfProfilePictureImageView/2 - UIApplication.sharedApplication().statusBarFrame.size.height
        
        if(scrollViewContentOffset >= magicLine){
            animateInStatusBarBackgroundView(true)
        }
        else{
            animateInStatusBarBackgroundView(false)
        }
   
    }
    

}






