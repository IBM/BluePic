/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import UIKit

class ImageInfoHeaderCollectionReusableView: UICollectionReusableView{

    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var byUserLabel: UILabel!
    @IBOutlet weak var cityStateLabel: UILabel!
    @IBOutlet weak var coordinatesLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var weatherImageView: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var tagsLabel: UILabel!
    
    private let kCaptionLabelLetterSpacing : CGFloat = 1.7
    private let kCaptionLabelLineSpacing : CGFloat = 10.0
    
    private let kWeatherIconNamePrefix = "weather_icon_"
    private let kDegreeSymbolString = "°"
    private let kByUserLabelPrefixString = NSLocalizedString("by", comment: "")
    private let kDateLabelPrefixString = NSLocalizedString("on", comment: "")
    private let kTimeLabelPrefixString = NSLocalizedString("at", comment: "")
    
    
    /**
     Method is called when the view wakes from nib
     */
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setupWithData(caption : String?, userFullName : String?, locationName : String?, latitude : String?, longitude : String?, timeStamp : NSDate?, weatherIconId : Int?, temperature : Int?, tags : [Tag]?){
  
        //setup captionLabel
        setupCaptionLabelWithData(caption)
        
        //setup byUserLabel
        setupByUserLabel(userFullName)
        
        //setup locationLabel
        setupCityAndStateLabel(locationName)
        
        //setup coordinatesLabel
        setupCoordintesLabel(latitude, longitude: longitude)
        
        //setup dateLabel
        setupDateLabelWithData(timeStamp)
        
        //setup timeLabel
        setupTimeLabelWithData(timeStamp)
        
        //setup weatherImageView and Temperature Label
        setupWeatherImageViewAndTemperatureLabel(weatherIconId, temperature: temperature)
        
        setupTagsLabel(tags)
        
    }

    
    private func setupCaptionLabelWithData(caption : String?){
        
        if let imageCaption = caption {
            
            var cap = ""
            if (imageCaption != CameraDataManager.SharedInstance.kEmptyCaptionPlaceHolder){
                cap = caption ?? ""
                cap = cap.uppercaseString
            }
            
            captionLabel.attributedText = NSAttributedString.createAttributedStringWithLetterAndLineSpacingWithCentering(cap, letterSpacing: kCaptionLabelLetterSpacing, lineSpacing: kCaptionLabelLineSpacing, centered: true)
            
        }
    }
    
    
    private func setupByUserLabel(userFullName : String?){
        let fullName = userFullName ?? ""
        byUserLabel.text = kByUserLabelPrefixString + " " + fullName
    }
    
    private func setupCityAndStateLabel(locationName : String?){
        cityStateLabel.text = locationName ?? ""
    }
    
    
    private func setupDateLabelWithData(timeStamp : NSDate?){
        
        if let date = timeStamp {
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
    
    
    private func setupTimeLabelWithData(timeStamp : NSDate?){
        
        if let date = timeStamp {
            let dateFormatter = NSDateFormatter()
            dateFormatter.timeStyle = .ShortStyle
            let locale = LocationDataManager.SharedInstance.getLanguageLocale()
            dateFormatter.locale = NSLocale(localeIdentifier: locale)
            let dateString = dateFormatter.stringFromDate(date)
            timeLabel.text = kTimeLabelPrefixString + " " + dateString
            
        }
        else{
            timeLabel.text = ""
        }
        
    }
    
    
    private func setupCoordintesLabel(latitude : String?, longitude : String?){
        
        if let latit = latitude,
            let longit = longitude,
            let lat = Double(latit),
            let long = Double(longit) {
            
            let formattedCordinatesString = Utils.coordinateString(lat, longitude: long)
            
            coordinatesLabel.attributedText = NSAttributedString.createAttributedStringWithLetterAndLineSpacingWithCentering(formattedCordinatesString, letterSpacing: 1.4, lineSpacing: 5, centered: true)
            
        }
        else{
            coordinatesLabel.text = ""
        }
    }

    
    private func setupWeatherImageViewAndTemperatureLabel(weatherIconId : Int?, temperature : Int?){
        
        if let iconId = weatherIconId {
            let imageName = kWeatherIconNamePrefix + "\(iconId)"
            
            if let image = UIImage(named: imageName){
                weatherImageView.image = image
            }
        }
        
        if let temperature = temperature {
            temperatureLabel.text = "\(temperature)" + kDegreeSymbolString
        }
        
    }
    
    private func setupTagsLabel(tags : [Tag]?){
        
        if let tags = tags {
            
            if tags.count > 0 {
                tagsLabel.hidden = false
            }
            else{
                tagsLabel.hidden = true
            }
        }
        else{
            tagsLabel.hidden = true
        }

    }


}
