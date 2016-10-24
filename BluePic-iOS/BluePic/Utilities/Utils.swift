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
import BMSCore

class Utils: NSObject {

    /**
     Method gets a key from a plist, both specified in parameters

     - parameter plist: String
     - parameter key:   String

     - returns: Bool?
     */
    class func getBoolValueWithKeyFromPlist(_ plist: String, key: String) -> Bool? {
        if let path: String = Bundle.main.path(forResource: plist, ofType: "plist"),
            let keyList = NSDictionary(contentsOfFile: path),
            let key = keyList.object(forKey: key) as? Bool {
            return key
        }
        return nil
    }

    /**
     Method gets a key from a plist, both specified in parameters

     - parameter plist: String
     - parameter key:   String

     - returns: String
     */
    class func getStringValueWithKeyFromPlist(_ plist: String, key: String) -> String? {
        if let path: String = Bundle.main.path(forResource: plist, ofType: "plist"),
            let keyList = NSDictionary(contentsOfFile: path),
            let key = keyList.object(forKey: key) as? String {
            return key
        }
        return nil
    }

    /**
    Method returns an instance of the Main.storyboard

    - returns: UIStoryboard
    */
    class func mainStoryboard() -> UIStoryboard {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        return storyboard
    }

    /**
    Method returns an instance of the storyboard defined by the storyboardName String parameter

    - parameter storyboardName: UString

    - returns: UIStoryboard
    */
    class func storyboardBoardWithName(_ storyboardName: String) -> UIStoryboard {
        let storyboard = UIStoryboard(name: storyboardName, bundle: Bundle.main)
        return storyboard
    }

    /**
    Method returns an instance of the view controller defined by the vcName paramter from the storyboard defined by the storyboardName parameter

    - parameter vcName:         String
    - parameter storyboardName: String

    - returns: UIViewController?
    */
    class func vcWithNameFromStoryboardWithName(_ vcName: String, storyboardName: String) -> UIViewController? {
        let storyboard = storyboardBoardWithName(storyboardName)
        return storyboard.instantiateViewController(withIdentifier: vcName)
    }

    /**
    Method returns an instance of a nib defined by the name String parameter

    - parameter name: String

    - returns: UINib?
    */
    class func nib(_ name: String) -> UINib? {
        let nib: UINib? = UINib(nibName: name, bundle: Bundle.main)
        return nib
    }

    /**
    Method registers a nib name defined by the nibName String parameter with the collectionView given by the collectionView parameter

    - parameter nibName:        String
    - parameter collectionView: UICollectionView
    */
    class func registerNibWith(_ nibName: String, collectionView: UICollectionView) {
        let nib = Utils.nib(nibName)
        collectionView.register(nib, forCellWithReuseIdentifier: nibName)
    }

    class func registerNibWith(_ nibName: String, tableView: UITableView) {
        let nib = Utils.nib(nibName)
        tableView.register(nib, forCellReuseIdentifier: nibName)
    }

    /**
    Method registers a supplementary element of kind nib defined by the nibName String parameter and the kind String parameter with the collectionView parameter

    - parameter nibName:        String
    - parameter kind:           String
    - parameter collectionView: UICollectionView
    */
    class func registerSupplementaryElementOfKindNibWithCollectionView(_ nibName: String, kind: String, collectionView: UICollectionView) {

        let nib = Utils.nib(nibName)

        collectionView.register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: nibName)
    }


    /**
     Method converts a string to a dictionary

     - parameter text: String

     - returns: [String : Any]?
     */
    class func convertStringToDictionary(_ text: String) -> [String : Any]? {
        if let data = text.data(using: String.Encoding.utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String : Any]
                return json
            } catch {
                print(NSLocalizedString("Convert String To Dictionary Error", comment: ""))
            }
        }
        return nil
    }



    /**
     Method converts a response to a dictionary

     - parameter response: Response?

     - returns: [String : Any]
     */
    class func convertResponseToDictionary(_ response: Response?) -> [String : Any]? {

        if let resp = response {
            if let responseText = resp.responseText {
                return convertStringToDictionary(responseText)
            } else {
                return nil
            }
        } else {
            return nil
        }

    }

    /**
     Method takes in a label and a spacing value and kerns the labels text to this value

     - parameter label:        UILabel
     - parameter spacingValue: CGFloat
     */
    class func kernLabelString(_ label: UILabel, spacingValue: CGFloat) {
        if let text = label.text {
            let attributedString = NSMutableAttributedString(string: text)
            attributedString.addAttribute(NSKernAttributeName, value: spacingValue, range: NSRange(location: 0, length: attributedString.length))
            label.attributedText = attributedString
        }
    }

    /**
     Method takes in latitude and longitude and formats these coordinates into a fancy format

     - parameter latitude:  Double
     - parameter longitude: Double

     - returns: String
     */
    class func coordinateString(_ latitude: Double, longitude: Double) -> String {
        var latSeconds = Int(latitude * 3600)
        let latDegrees = latSeconds / 3600
        latSeconds = abs(latSeconds % 3600)
        let latMinutes = latSeconds / 60
        latSeconds %= 60
        var longSeconds = Int(longitude * 3600)
        let longDegrees = longSeconds / 3600
        longSeconds = abs(longSeconds % 3600)
        let longMinutes = longSeconds / 60
        longSeconds %= 60
        return String(format:"%d° %d' %d\" %@, %d° %d' %d\" %@",
                      latDegrees,
                      latMinutes,
                      latSeconds, {return latDegrees >= 0 ? NSLocalizedString("N", comment: "first letter of the word North") : NSLocalizedString("S", comment: "first letter of the word South")}(),
                      longDegrees,
                      longMinutes,
                      longSeconds, {return longDegrees >= 0 ? NSLocalizedString("E", comment: "first letter of the word East") : NSLocalizedString("W", comment: "first letter of the word West")}() )
    }


}
