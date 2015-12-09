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
    
    let kHeaderViewHeight : CGFloat = 480
    let kHeaderImageViewHeight : CGFloat = 375

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        setupViewModel()
        
        setupCollectionView()
        
        setupHeaderView()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func setupViewModel(){
        
        viewModel = ProfileViewModel(refreshVCCallback: reloadDataInCollectionView)
        
        
    }
    
    func setupHeaderView(){
        
        headerImageView = UIImageView(frame: CGRectMake(0, 0, collectionView.frame.size.width, kHeaderImageViewHeight))
        
        headerImageView.image = UIImage(named: "photo1")
        
        self.view.addSubview(headerImageView)
        self.view.insertSubview(headerImageView, belowSubview: collectionView)
        
    
    }
    
    
    func setupCollectionView(){
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        Utils.registerSupplementaryElementOfKindNibWithCollectionView("ProfileHeaderCollectionReusableView", kind: UICollectionElementKindSectionHeader, collectionView: collectionView)
        
        Utils.registerNibWithCollectionView("ImageFeedCollectionViewCell", collectionView: collectionView)
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: "userTriggeredRefresh", forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl.hidden = true
        
        self.collectionView.addSubview(refreshControl)
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
