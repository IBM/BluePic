/**
 * Copyright IBM Corporation 2015
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

class Utils: NSObject {
    
    
    /**
     Method gets a key from a plist, both specified in parameters
     
     - parameter plist: String!
     - parameter key:   String!
     
     - returns: String
     */
    class func getKeyFromPlist (plist: String!, key: String!) -> String {
        let path: String = NSBundle.mainBundle().pathForResource(plist, ofType: "plist")!
        let keyList = NSDictionary(contentsOfFile: path)
        return keyList!.objectForKey(key) as! String
    }
    
    
    /**
    Method returns an instance of the Main.storyboard
    
    - returns: UIStoryboard
    */
    class func mainStoryboard() -> UIStoryboard
    {
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        return storyboard
    }
    
    
    /**
    Method returns an instance of the storyboard defined by the storyboardName String parameter
    
    - parameter storyboardName: UString
    
    - returns: UIStoryboard
    */
    class func storyboardBoardWithName(storyboardName : String) -> UIStoryboard {
        let storyboard = UIStoryboard(name: storyboardName, bundle: NSBundle.mainBundle())
        return storyboard
    }
    
 
    /**
    Method returns an instance of the view controller defined by the vcName paramter from the storyboard defined by the storyboardName parameter
    
    - parameter vcName:         String
    - parameter storyboardName: String
    
    - returns: UIViewController?
    */
    class func vcWithNameFromStoryboardWithName(vcName : String, storyboardName : String) -> UIViewController?{
        let storyboard = storyboardBoardWithName(storyboardName)
        let viewController: AnyObject! = storyboard.instantiateViewControllerWithIdentifier(vcName)
        return viewController as? UIViewController
    }
    
    
    /**
    Method returns an instance of a nib defined by the name String parameter
    
    - parameter name: String
    
    - returns: UINib?
    */
    class func nib(name: String) -> UINib?
    {
        let nib: UINib? = UINib(nibName: name, bundle: NSBundle.mainBundle());
        return nib
    }
    
    
    /**
    Method registers a nib name defined by the nibName String parameter with the collectionView given by the collectionView parameter
    
    - parameter nibName:        String
    - parameter collectionView: UICollectionView
    */
    class func registerNibWithCollectionView(nibName : String, collectionView : UICollectionView){
        let nib = Utils.nib(nibName)
        collectionView.registerNib(nib, forCellWithReuseIdentifier: nibName)
    }
    
    
    /**
    Method registers a supplementary element of kind nib defined by the nibName String parameter and the kind String parameter with the collectionView parameter
    
    - parameter nibName:        String
    - parameter kind:           String
    - parameter collectionView: UICollectionView
    */
    class func registerSupplementaryElementOfKindNibWithCollectionView(nibName : String, kind : String, collectionView : UICollectionView){
        
        let nib = Utils.nib(nibName)
        
        collectionView.registerNib(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: nibName)
    }
    
    
}
