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

class ImageInfoHeaderCollectionReusableView: UICollectionReusableView {

    //label that shows the caption of the image
    @IBOutlet weak var captionLabel: UILabel!

    //label that shows who the image is by - its shows the users name
    @IBOutlet weak var byUserLabel: UILabel!

    //label that shows the city and state of where the image was uploaded
    @IBOutlet weak var cityStateLabel: UILabel!

    //label that shows the coordinates of where the image was uploaded
    @IBOutlet weak var coordinatesLabel: UILabel!

    //label that shows the date the image was taken on
    @IBOutlet weak var dateLabel: UILabel!

    //label that shows the time of day the image was taken at
    @IBOutlet weak var timeLabel: UILabel!

    //imageView that shows a weather icon image for type of weather at the time the image was uploaded
    @IBOutlet weak var weatherImageView: UIImageView!

    //label that shows the temperature at the time the image was uploaded
    @IBOutlet weak var temperatureLabel: UILabel!

    //label that says "Tags"
    @IBOutlet weak var tagsLabel: UILabel!

    //constant that defines the captionLabel letter spacing
    fileprivate let kCaptionLabelLetterSpacing: CGFloat = 1.7

    //constant that defines the captionLabel line spacing
    fileprivate let kCaptionLabelLineSpacing: CGFloat = 10.0

    //prefix used to get the correct name of the weather icon from the image asset folder
    fileprivate let kWeatherIconNamePrefix = "weather_icon_"

    //degree string used for the temperature
    fileprivate let kDegreeSymbolString = "°"

    //prefix string used for the byUserLabel text
    fileprivate let kByUserLabelPrefixString = NSLocalizedString("by", comment: "")

    //prefix for the dateLabel text
    fileprivate let kDateLabelPrefixString = NSLocalizedString("on", comment: "")

    //prefix for the timeLabel text
    fileprivate let kTimeLabelPrefixString = NSLocalizedString("at", comment: "")

    /**
     Method is called when the view wakes from nib
     */
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    /**
     Method sets up the UI with data

     - parameter image: Image?
     */
    func setupWithData(_ image: Image) {

        //setup captionLabel
        setupCaptionLabelWithData(image.caption)

        //setup byUserLabel
        setupByUserLabel(image.user.name)

        //setup locationLabel
        setupCityAndStateLabel(image.location.name)

        //setup coordinatesLabel
        setupCoordinatesLabel(image.location.latitude, longitude: image.location.longitude)

        //setup dateLabel
        setupDateLabelWithData(image.timeStamp as Date)

        //setup timeLabel
        setupTimeLabelWithData(image.timeStamp as Date)

        //setup weatherImageView and Temperature Label
        setupWeatherImageViewAndTemperatureLabel(image.location.weather?.iconId, temperature: image.location.weather?.temperature)

        setupTagsLabel(image.tags)

    }

    /**
     Method sets up the caption label with data

     - parameter caption: String?
     */
    fileprivate func setupCaptionLabelWithData(_ caption: String?) {

        if let imageCaption = caption {

            var cap = ""
            if imageCaption != CameraDataManager.SharedInstance.kEmptyCaptionPlaceHolder {
                cap = caption ?? ""
                cap = cap.uppercased()
            }

            captionLabel.attributedText = NSAttributedString.createAttributedStringWithLetterAndLineSpacingWithCentering(cap, letterSpacing: kCaptionLabelLetterSpacing, lineSpacing: kCaptionLabelLineSpacing, centered: true)

        }
    }

    /**
     Method sets the user label with data

     - parameter userFullName: String?
     */
    fileprivate func setupByUserLabel(_ userFullName: String?) {
        let fullName = userFullName ?? ""
        byUserLabel.text = kByUserLabelPrefixString + " " + fullName
    }

    /**
     Method sets the cityAndStateLabel with data

     - parameter locationName: String?
     */
    fileprivate func setupCityAndStateLabel(_ locationName: String?) {
        cityStateLabel.text = locationName ?? ""
    }


    /**
     Method sets up the date label with data

     - parameter timeStamp: NSDate?
     */
    fileprivate func setupDateLabelWithData(_ timeStamp: Date?) {

        if let date = timeStamp {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = DateFormatter.Style.long
            let locale = LocationDataManager.SharedInstance.getLanguageLocale()
            dateFormatter.locale = Locale(identifier: locale)
            let dateString = dateFormatter.string(from: date)

            dateLabel.text = kDateLabelPrefixString + " " + dateString
        } else {
            dateLabel.text = ""
        }

    }

    /**
     Method sets up the time label with data

     - parameter timeStamp: NSDate?
     */
    fileprivate func setupTimeLabelWithData(_ timeStamp: Date?) {

        if let date = timeStamp {
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .short
            let locale = LocationDataManager.SharedInstance.getLanguageLocale()
            dateFormatter.locale = Locale(identifier: locale)
            let dateString = dateFormatter.string(from: date)
            timeLabel.text = kTimeLabelPrefixString + " " + dateString

        } else {
            timeLabel.text = ""
        }

    }

    /**
     Method sets the coordinatesLabel with data

     - parameter latitude:  String?
     - parameter longitude: String?
     */
    fileprivate func setupCoordinatesLabel(_ latitude: Double?, longitude: Double?) {

        if let latit = latitude,
            let longit = longitude {

            let formattedCordinatesString = Utils.coordinateString(latit, longitude: longit)

            coordinatesLabel.attributedText = NSAttributedString.createAttributedStringWithLetterAndLineSpacingWithCentering(formattedCordinatesString, letterSpacing: 1.4, lineSpacing: 5, centered: true)

        } else {
            coordinatesLabel.text = ""
        }
    }

    /**
     Method sets up the weather image view and temperature label with data

     - parameter weatherIconId: Int?
     - parameter temperature:   Int?
     */
    fileprivate func setupWeatherImageViewAndTemperatureLabel(_ weatherIconId: Int?, temperature: Int?) {

        if let iconId = weatherIconId {
            let imageName = kWeatherIconNamePrefix + "\(iconId)"

            if let image = UIImage(named: imageName) {
                weatherImageView.image = image
            }
        }

        if var temperature = temperature {

            let unitOfMeasure = LocationDataManager.SharedInstance.getUnitsOfMeasurement()
            if unitOfMeasure == kImperialUnitOfMeasurement {
                temperatureLabel.text = "\(temperature)" + kDegreeSymbolString + "F"
            } else if unitOfMeasure == kMetricUnitOfMeasurement {
                temperature = Int(round((Float(temperature) - 32.0) / 1.8))
                temperatureLabel.text = "\(temperature)" + kDegreeSymbolString + "C"
            }
        }

    }

    /**
     Method sets up the tags label

     - parameter tags: [Tag]?
     */
    fileprivate func setupTagsLabel(_ tags: [Tag]?) {

        if let tags = tags {

            if tags.count > 0 {
                tagsLabel.isHidden = false
            } else {
                tagsLabel.isHidden = true
            }
        } else {
            tagsLabel.isHidden = true
        }
    }
}
