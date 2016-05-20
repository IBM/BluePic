//
//  ImageDetailViewController.swift
//  BluePic
//
//  Created by Alex Buck on 5/11/16.
//  Copyright © 2016 MIL. All rights reserved.
//

import UIKit

class ImageDetailViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var dimView: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var tagCollectionView: UICollectionView!
    
    let kHeaderViewInfoViewHeight : CGFloat = 105

    var image : Image!
    
    var viewModel : ImageDetailViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViewModel()
        setupSubViews()
        setupTagCollectionView()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        UIApplication.sharedApplication().statusBarStyle = .LightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func setupViewModel(){
        viewModel = ImageDetailViewModel()
        viewModel.image = image
    }
    
    func setupTagCollectionView(){
        
        let layout = KTCenterFlowLayout()
        layout.minimumInteritemSpacing = 10.0
        layout.minimumLineSpacing = 10.0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 15.0, bottom: 0, right: 15.0)
        tagCollectionView.setCollectionViewLayout(layout, animated: false)
        tagCollectionView.delegate = self
        tagCollectionView.dataSource = self
        
        Utils.registerSupplementaryElementOfKindNibWithCollectionView("ImageInfoHeaderCollectionReusableView", kind: UICollectionElementKindSectionHeader, collectionView: tagCollectionView)

        Utils.registerNibWithCollectionView("TagCollectionViewCell", collectionView: tagCollectionView)
        
    }
    
    func setupSubViews(){
        
        setupImageView()
        setupBlurView()
        setupImageDetailInfoView()
        
        
    }
    
    func setupImageDetailInfoView(){
        
//        imageDetailInfoView.setupWithData(image.caption, userFullName: image.user?.name, locationName: image.location?.name, latitude: image.location?.latitude, longitude: image.location?.longitude, timeStamp: image.timeStamp, weatherIconId: image.location?.weather?.iconId, temperature: image.location?.weather?.temperature)
        
    }
    
    func setupImageView(){
        
        if let urlString = image.url {
            let nsurl = NSURL(string: urlString)
            imageView.sd_setImageWithURL(nsurl)
        }
    }

    @IBAction func backButtonAction(sender: AnyObject) {
        
        self.navigationController?.popViewControllerAnimated(true)
  
    }
   
}


//UI Setup Methods
extension ImageDetailViewController {
    
    func setupBlurView(){
        
        dimView.hidden = true
        
        let blurViewFrame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        
        let blurViewHolderView = UIView(frame: blurViewFrame)
        
        let darkBlur = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        
        let blurView = UIVisualEffectView(effect: darkBlur)
        blurView.frame = blurViewFrame
        blurViewHolderView.alpha = 0.90
        
        blurViewHolderView.addSubview(blurView)
        
        imageView.addSubview(blurViewHolderView)
        
    }
  
}


extension ImageDetailViewController : UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItemsInSection(section)
    }
    
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return viewModel.numberOfSectionsInCollectionView()
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        return viewModel.setUpSectionHeaderViewForIndexPath(
            indexPath,
            kind: kind,
            collectionView: collectionView
        )
    }

    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return viewModel.setUpCollectionViewCell(indexPath, collectionView: collectionView)
    }
    
    
    
    
    

}


extension ImageDetailViewController: UICollectionViewDelegateFlowLayout {
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return viewModel.sizeForItemAtIndexPath(indexPath, collectionView: collectionView)
        
    }
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
        
        let collectionWidth = collectionView.frame.size.width
        
        if(section == 0){
            return CGSizeMake(collectionWidth, self.view.frame.size.height/2 + kHeaderViewInfoViewHeight) //kHeaderViewHeight
        }
        else{
            return CGSizeMake(collectionWidth, 0)
        }
        
    }
    
    
}


extension ImageDetailViewController : UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let tag = image.tags![indexPath.row]
        
        let vc = Utils.vcWithNameFromStoryboardWithName("FeedViewController", storyboardName: "Feed") as! FeedViewController
        vc.searchQuery = tag.label!
        self.navigationController?.pushViewController(vc, animated: true)
  
    }

}
