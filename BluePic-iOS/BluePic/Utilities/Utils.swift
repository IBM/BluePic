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

     - returns: String?
     */
    class func getKeyFromPlist(plist: String, key: String) -> String? {
        if let path: String = NSBundle.mainBundle().pathForResource(plist, ofType: "plist"),
            keyList = NSDictionary(contentsOfFile: path),
            key = keyList.objectForKey(key) as? String {
            return key
        }
        return nil
    }

    /**
     Method gets a key from a plist, both specified in parameters

     - parameter plist: String
     - parameter key:   String

     - returns: Bool?
     */
    class func getBoolValueWithKeyFromPlist(plist: String, key: String) -> Bool? {
        if let path: String = NSBundle.mainBundle().pathForResource(plist, ofType: "plist"),
            keyList = NSDictionary(contentsOfFile: path),
            key = keyList.objectForKey(key) as? Bool {
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
    class func getStringValueWithKeyFromPlist(plist: String, key: String) -> String? {
        if let path: String = NSBundle.mainBundle().pathForResource(plist, ofType: "plist"),
            keyList = NSDictionary(contentsOfFile: path),
            key = keyList.objectForKey(key) as? String {
            return key
        }
        return nil
    }


    /**
    Method returns an instance of the Main.storyboard

    - returns: UIStoryboard
    */
    class func mainStoryboard() -> UIStoryboard {
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        return storyboard
    }


    /**
    Method returns an instance of the storyboard defined by the storyboardName String parameter

    - parameter storyboardName: UString

    - returns: UIStoryboard
    */
    class func storyboardBoardWithName(storyboardName: String) -> UIStoryboard {
        let storyboard = UIStoryboard(name: storyboardName, bundle: NSBundle.mainBundle())
        return storyboard
    }


    /**
    Method returns an instance of the view controller defined by the vcName paramter from the storyboard defined by the storyboardName parameter

    - parameter vcName:         String
    - parameter storyboardName: String

    - returns: UIViewController?
    */
    class func vcWithNameFromStoryboardWithName(vcName: String, storyboardName: String) -> UIViewController? {
        let storyboard = storyboardBoardWithName(storyboardName)
        let viewController: AnyObject = storyboard.instantiateViewControllerWithIdentifier(vcName)
        return viewController as? UIViewController
    }


    /**
    Method returns an instance of a nib defined by the name String parameter

    - parameter name: String

    - returns: UINib?
    */
    class func nib(name: String) -> UINib? {
        let nib: UINib? = UINib(nibName: name, bundle: NSBundle.mainBundle())
        return nib
    }


    /**
    Method registers a nib name defined by the nibName String parameter with the collectionView given by the collectionView parameter

    - parameter nibName:        String
    - parameter collectionView: UICollectionView
    */
    class func registerNibWithCollectionView(nibName: String, collectionView: UICollectionView) {
        let nib = Utils.nib(nibName)
        collectionView.registerNib(nib, forCellWithReuseIdentifier: nibName)
    }


    /**
    Method registers a supplementary element of kind nib defined by the nibName String parameter and the kind String parameter with the collectionView parameter

    - parameter nibName:        String
    - parameter kind:           String
    - parameter collectionView: UICollectionView
    */
    class func registerSupplementaryElementOfKindNibWithCollectionView(nibName: String, kind: String, collectionView: UICollectionView) {

        let nib = Utils.nib(nibName)

        collectionView.registerNib(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: nibName)
    }


    class func convertStringToDictionary(text: String) -> [String:AnyObject]? {
        if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? [String:AnyObject]
                return json
            } catch {
                print("Error converting string to Dictionary")
            }
        }
        return nil
    }




    class func convertResponseToDictionary(response: Response?) -> [String : AnyObject]? {

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

    // Kerning helper method
    class func kernLabelString(label: UILabel, spacingValue: CGFloat) {
        if let text = label.text {
            let attributedString = NSMutableAttributedString(string: text)
            attributedString.addAttribute(NSKernAttributeName, value: spacingValue, range: NSRange(location: 0, length: attributedString.length))
            label.attributedText = attributedString
        }
    }


    class func coordinateString(latitude: Double, longitude: Double) -> String {
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
                      abs(latDegrees),
                      latMinutes,
                      latSeconds, {return latDegrees >= 0 ? NSLocalizedString("N", comment: "first letter of the word North") : NSLocalizedString("S", comment: "first letter of the word South")}(),
                      abs(longDegrees),
                      longMinutes,
                      longSeconds, {return longDegrees >= 0 ? NSLocalizedString("E", comment: "first letter of the word East") : NSLocalizedString("W", comment: "first letter of the word West")}() )
    }



}
