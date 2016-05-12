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
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var byUserLabel: UILabel!
    @IBOutlet weak var cityStateLabel: UILabel!
    @IBOutlet weak var coordinatesLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var weatherImageView: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!

    @IBOutlet weak var tagCollectionView: UICollectionView!
    
    
    private let kByUserLabelPrefix = "by"
    private let kDateLabelPrefix = "on"
    private let kTimeLabelPrefix = "at"
    
    private let kCellPadding: CGFloat = 60
    
    
    private let kCaptionLabelLetterSpacing : CGFloat = 1.7
    private let kCaptionLabelLineSpacing : CGFloat = 10.0
    
    var image : Image!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSubviewWithImageData()
        setupTagCollectionView()
        
        UIApplication.sharedApplication().statusBarStyle = .LightContent

        // Do any additional setup after loading the view.
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
        
        //Utils.kernLabelString(tagsButton.titleLabel!, spacingValue: 1.7)
        Utils.registerNibWithCollectionView("TagCollectionViewCell", collectionView: tagCollectionView)
        
    }
    
    func setupSubviewWithImageData(){
        
        if let urlString = image.url {
            
            let nsurl = NSURL(string: urlString)
            
            imageView.sd_setImageWithURL(nsurl)
        }
        
        //setup captionLabel
        setupCaptionLabelWithData()
    
        //setup byUserLabel
        let userFullName = image.user?.name ?? ""
        byUserLabel.text = kByUserLabelPrefix + " " + userFullName
    
        //setup locationLabel
        let locationName = image.location?.name ?? ""
        cityStateLabel.text = locationName
        
        //setup coordinatesLabel
        setupCoordintesLabel()
    
        //setup dateLabel
        setupDateLabelWithData()
        
        //setup timeLabel
        setupTimeLabelWithData()
        
        
  
    }
    
    
    
    
    
    @IBAction func backButtonAction(sender: AnyObject) {
        
        self.navigationController?.popViewControllerAnimated(true)
        
        
        
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


//UI Setup Methods
extension ImageDetailViewController {
    
    func setupCaptionLabelWithData(){
        
        let caption = image.caption?.uppercaseString ?? ""
        
        captionLabel.attributedText = NSAttributedString.createAttributedStringWithLetterAndLineSpacingWithCentering(caption, letterSpacing: kCaptionLabelLetterSpacing, lineSpacing: kCaptionLabelLineSpacing, centered: true)
        
    }
    
    func setupDateLabelWithData(){
        
        if let date = image.timeStamp {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
            let dateString = dateFormatter.stringFromDate(date)
            
            dateLabel.text = kDateLabelPrefix + " " + dateString
        }
        else{
            dateLabel.text = ""
        }
        
    }
    
    func setupTimeLabelWithData(){
        
        if let date = image.timeStamp {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "h:mm a"
            let dateString = dateFormatter.stringFromDate(date)
            timeLabel.text = kTimeLabelPrefix + " " + dateString
   
        }
        else{
            timeLabel.text = ""
        }
        
    }
    
    
    func setupCoordintesLabel(){
        
        if let latitude = image.location?.latitude,
            let longitude = image.location?.longitude {
            
            let formattedCordinatesString = Utils.coordinateString(Double(latitude), longitude: Double(longitude))
            
            coordinatesLabel.attributedText = NSAttributedString.createAttributedStringWithLetterAndLineSpacingWithCentering(formattedCordinatesString, letterSpacing: 1.4, lineSpacing: 5, centered: true)
       
        }
        else{
            coordinatesLabel.text = ""
        }
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
        
        cell.tagLabel.text = tags[indexPath.item].label
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
        
        
        
        
        
    }
    
    
    
}
