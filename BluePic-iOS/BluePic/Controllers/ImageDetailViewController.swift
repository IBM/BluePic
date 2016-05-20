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
    @IBOutlet weak var imageDetailInfoView: ImageDetailInfoView!
    @IBOutlet weak var tagCollectionView: UICollectionView!

    private let kCellPadding: CGFloat = 60

    var image : Image!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
    func setupTagCollectionView(){
        
        let layout = KTCenterFlowLayout()
        layout.minimumInteritemSpacing = 10.0
        layout.minimumLineSpacing = 10.0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 15.0, bottom: 0, right: 15.0)
        tagCollectionView.setCollectionViewLayout(layout, animated: false)
        tagCollectionView.delegate = self
        tagCollectionView.dataSource = self

        Utils.registerNibWithCollectionView("TagCollectionViewCell", collectionView: tagCollectionView)
        
    }
    
    func setupSubViews(){
        
        setupImageView()
        setupBlurView()
        setupImageDetailInfoView()
        
        
    }
    
    func setupImageDetailInfoView(){
        
        imageDetailInfoView.setupWithData(image.caption, userFullName: image.user?.name, locationName: image.location?.name, latitude: image.location?.latitude, longitude: image.location?.longitude, timeStamp: image.timeStamp, weatherIconId: image.location?.weather?.iconId, temperature: image.location?.weather?.temperature)
        
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
       
        if let tags = image.tags {
            return tags.count
        }
        else{
            return 0
        }
        
    }
    
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TagCollectionViewCell", forIndexPath: indexPath) as? TagCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let tags = image.tags!
        
        cell.tagLabel.text = tags[indexPath.item].label?.uppercaseString
        return cell
        
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let tags = image.tags!
        
        let size = NSString(string: tags[indexPath.item].label!).sizeWithAttributes(nil)
        return CGSizeMake(size.width + kCellPadding, 30.0)
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
