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
    
    
    private let kByUserLabelPrefix = "by"
    private let kDateLabelPrefix = "on"
    private let kTimeLabelPrefix = "at"
    
    
    private let kCaptionLabelLetterSpacing : CGFloat = 1.7
    private let kCaptionLabelLineSpacing : CGFloat = 10.0
    
    var image : Image!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSubviewWithImageData()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
