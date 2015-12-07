//
//  FeedViewController.swift
//  BluePic
//
//  Created by Nathan Hekman on 11/23/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit

class FeedViewController: UIViewController {
    
    @IBOutlet weak var logoImageView: UIImageView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var viewModel : FeedViewModel!
    
    let kMinimumInterItemSpacingForSectionAtIndex : CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        setupViewModel()
       
    }
    
    override func viewDidAppear(animated: Bool) {
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupViewModel(){
        viewModel = FeedViewModel(refreshCallback: reloadDataInCollectionView)
    }
    
    func setupCollectionView(){
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        Utils.registerNibWithCollectionView("ImageFeedCollectionViewCell", collectionView: collectionView)
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


extension FeedViewController: UICollectionViewDelegate {
    
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    
            print(indexPath.row)
        
    }
    
    
}


extension FeedViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

        return viewModel.sizeForItemAtIndexPath(indexPath, collectionView: collectionView)
    }



}