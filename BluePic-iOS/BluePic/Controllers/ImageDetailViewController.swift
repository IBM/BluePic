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

    private let kWeatherIconNamePrefix = "weather_icon_"
    private let kDegreeSymbolString = "°"
    
    private let kByUserLabelPrefixString = NSLocalizedString("by", comment: "")
    private let kDateLabelPrefixString = NSLocalizedString("on", comment: "")
    private let kTimeLabelPrefixString = NSLocalizedString("at", comment: "")
    
    
    private let kCellPadding: CGFloat = 60
    
    
    
    
    private let kCaptionLabelLetterSpacing : CGFloat = 1.7
    private let kCaptionLabelLineSpacing : CGFloat = 10.0
    
    var image : Image!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        setupSubviewsWithImageData()
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
        
        //Utils.kernLabelString(tagsButton.titleLabel!, spacingValue: 1.7)
        Utils.registerNibWithCollectionView("TagCollectionViewCell", collectionView: tagCollectionView)
        
    }
    
    func setupSubviewsWithImageData(){
        
        if let urlString = image.url {
            
            let nsurl = NSURL(string: urlString)
            
            imageView.sd_setImageWithURL(nsurl)
        }
        
        setupBlurView()
        
        //setup captionLabel
        setupCaptionLabelWithData()
    
        //setup byUserLabel
        let userFullName = image.user?.name ?? ""
        byUserLabel.text = kByUserLabelPrefixString + " " + userFullName
    
        //setup locationLabel
        let locationName = image.location?.name ?? ""
        cityStateLabel.text = locationName
        
        //setup coordinatesLabel
        setupCoordintesLabel()
    
        //setup dateLabel
        setupDateLabelWithData()
        
        //setup timeLabel
        setupTimeLabelWithData()
        
        //setup weatherImageView and Temperature Label
        setupWeatherImageViewAndTemperatureLabel()
        
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
    
    func setupCaptionLabelWithData(){
        
        let caption = image.caption?.uppercaseString ?? ""
        
        captionLabel.attributedText = NSAttributedString.createAttributedStringWithLetterAndLineSpacingWithCentering(caption, letterSpacing: kCaptionLabelLetterSpacing, lineSpacing: kCaptionLabelLineSpacing, centered: true)
        
    }
    
    func setupDateLabelWithData(){
        
        if let date = image.timeStamp {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
            let locale = LocationDataManager.SharedInstance.getLanguageLocale()
            dateFormatter.locale = NSLocale(localeIdentifier: locale)
            let dateString = dateFormatter.stringFromDate(date)
            
            dateLabel.text = kDateLabelPrefixString + " " + dateString
        }
        else{
            dateLabel.text = ""
        }
        
    }
    
    func setupTimeLabelWithData(){
        
        if let date = image.timeStamp {
            let dateFormatter = NSDateFormatter()
            dateFormatter.timeStyle = .ShortStyle
            let locale = LocationDataManager.SharedInstance.getLanguageLocale()
            dateFormatter.locale = NSLocale(localeIdentifier: locale)
            //dateFormatter.dateFormat = "h:mm a"
            let dateString = dateFormatter.stringFromDate(date)
            timeLabel.text = kTimeLabelPrefixString + " " + dateString
   
        }
        else{
            timeLabel.text = ""
        }
        
    }
    
    
    func setupCoordintesLabel(){
        
        if let latitude = image.location?.latitude,
        let longitude = image.location?.longitude,
        let lat = Double(latitude),
        let long = Double(longitude) {
            
            let formattedCordinatesString = Utils.coordinateString(lat, longitude: long)
            
            coordinatesLabel.attributedText = NSAttributedString.createAttributedStringWithLetterAndLineSpacingWithCentering(formattedCordinatesString, letterSpacing: 1.4, lineSpacing: 5, centered: true)
       
        }
        else{
            coordinatesLabel.text = ""
        }
    }
    
    func setupWeatherImageViewAndTemperatureLabel(){
        
        if let iconId = image.location?.weather?.iconId {
            let imageName = kWeatherIconNamePrefix + "\(iconId)"
            
            if let image = UIImage(named: imageName){
                weatherImageView.image = image
            }
 
        }
        
        if let temperature = image.location?.weather?.temperature {
            
            temperatureLabel.text = "\(temperature)" + kDegreeSymbolString
        
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
