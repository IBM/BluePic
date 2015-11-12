/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
This sample program is provided AS IS and may be used, executed, copied and modified without royalty payment by customer (a) for its own instruction and study, (b) in order to develop applications designed to run with an IBM product, either for customer's own internal use or for redistribution by customer, as part of such an application, in customer's own products.
*/

import UIKit

class Utils: NSObject {
    
    
    /**
    Method returns the current visible view controller that the user sees
    
    :returns: the visible view controller
    */
    class func visibleViewController() -> UIViewController? {
        return self.visibleViewController(UIApplication.sharedApplication().keyWindow?.rootViewController)
    }
    
    
    /**
    Method returns the current visible view controller that the user sees. Its a helper method to the other visibleViewController method
    
    :param: viewController the rootViewController
    
    :returns: the visible view controller
    */
    private class func visibleViewController(viewController: UIViewController?) -> UIViewController? {
        if viewController?.presentedViewController == nil {
            
            return viewController
        } else if let navigationController = viewController as? UINavigationController {
            return self.visibleViewController(navigationController.topViewController)
        } else if let tabBarController = viewController as? UITabBarController {
            return self.visibleViewController(tabBarController.selectedViewController)
        } else {
            return self.visibleViewController(viewController?.presentedViewController)
        }
    }

    class func getDataAdapterURL() -> String{
        
        let url : String = ""
        let configurationPath = NSBundle.mainBundle().pathForResource("worklight", ofType: "plist")
        
        if((configurationPath) != nil) {
            let configuration = NSDictionary(contentsOfFile: configurationPath!)!
            
            if let adaptorURL = configuration["dataAdapterURL"] as? String{
                return adaptorURL
            }
            
        }
        return url
    }
    
    
    
    
    
    
    class func getBackendGUID() -> String {
        
        let configurationPath = NSBundle.mainBundle().pathForResource("bluemix", ofType: "plist")
        
        if((configurationPath) != nil) {
            let configuration = NSDictionary(contentsOfFile: configurationPath!)!
            
            if let backendGUID = configuration["backendGUID"] as? String{
                return backendGUID
            }
            else{
                return ""
            }
            
        }
        return ""
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
    Method returns an instance of the view controller defined by the name String parameter from the main storyboard
    
    - parameter name: String
    
    - returns: UIViewController?
    */
    class func vcWithName(name: String) -> UIViewController?
    {
        let storyboard = mainStoryboard()
        let viewController: AnyObject! = storyboard.instantiateViewControllerWithIdentifier(name)
        return viewController as? UIViewController
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
    
    
    /**
    Method registers a nib defined by the identifier String parameter and the nibName String parameter with the tableVIew parameter
    
    - parameter identifier: String
    - parameter nibName:    String
    - parameter tableView:  UITableView
    */
    class func registerNibWithTableView(identifier: String, nibName: String, tableView: UITableView){
        tableView.registerNib(UINib(nibName: nibName, bundle: nil), forCellReuseIdentifier: identifier)
    }
    
    
    /**
    Method prints to console using the normal print method and also logs to MQA using the MQALogger
    
    - parameter stringToPrint: String
    */
    class func printMQA(stringToPrint: String) {
        print(stringToPrint)
        MQALogger.log(stringToPrint)
    }
    
    
    /**
    Method obtain file from main bundle by name and fileType
    
    - parameter fileName: String?
    - parameter fileType: String?
    
    - returns: NSURL?
    */
    class func fileFromBundle(fileName: String?, fileType: String?) -> NSURL?
    {
        var url: NSURL?
        
        if let path = NSBundle.mainBundle().pathForResource(fileName, ofType: fileType)
        {
            url = NSURL.fileURLWithPath(path)
        }
        
        return url
        
    }
    
    
    /**
    (Programmatic Container Views) 
    Method adds the childViewController parameter as a childViewController of the parentViewController, adds the childViewController's view to the parentViewController's view, and then sets the parentViewController to be the childViewController's parent view controller.
    
    - parameter childViewController:  UIViewController
    - parameter parentViewController: UIViewController
    */
    class func addChildVCToParentVC(childViewController : UIViewController, parentViewController : UIViewController){
        parentViewController.addChildViewController(childViewController)
        parentViewController.view.addSubview(childViewController.view)
        childViewController.didMoveToParentViewController(parentViewController)
    }
    
    
    /**
    Method returns the instance of the rootViewController. In tab bar applications, typically this rootViewController is a UITabBarViewController
    
    - returns: UIViewController
    */
    class func rootViewController() -> UIViewController{
        let rootViewController = UIApplication.sharedApplication().keyWindow?.rootViewController!
    
        return rootViewController!
    }
    
    
    /**
    Method converts the view parameters origin to the rootViewController view's origin. In tab bar applications, typically this rootViewController is a UITabBarViewController

    
    - parameter view: UIView
    
    - returns: CGPoint
    */
    class func convertViewOriginToRootViewControllersView(view : UIView) -> CGPoint{
        let rootViewController = Utils.rootViewController()
        
        let newOrigin = view.superview?.convertPoint(view.frame.origin, toView: rootViewController.view)
        
        return newOrigin!
    }
    
    
    /**
    Method returns the navigation bar's height depending on what the current phone is
    
    - returns: CGFloat
    */
    class func getNavigationBarHeight()-> CGFloat{
            let iPhone5AND6StatusBarHeight : CGFloat = 20
            let iPhone5AND6NavBarHeight : CGFloat = 44
            
            return iPhone5AND6NavBarHeight + iPhone5AND6StatusBarHeight
    }
    
    
    /**
    Method performs a custom cross fade segue
    
    - parameter navigationController:      UINavigationController
    - parameter destinationViewController: UIViewController
    */
    class func performCrossFadeSegue(navigationController: UINavigationController, destinationViewController : UIViewController){
        
        let transition = CATransition()
        
        transition.duration = 1.0
        transition.type = kCATransitionFade
        
        navigationController.view.layer.addAnimation(transition, forKey: kCATransition)
        
        navigationController.pushViewController(destinationViewController, animated: false)
 
    }
    
    
    /**
    Method perfrosma a custom pop cross fade segue
    
    - parameter navigationController: UINavigationController
    - parameter toViewController:     UIViewController
    */
    class func popCrossFadeSegue(navigationController: UINavigationController, toViewController: UIViewController){
        
        let transition = CATransition()
        
        transition.duration = 0.4
        transition.type = kCATransitionFade
        
        navigationController.view.layer.addAnimation(transition, forKey: kCATransition)
        
        navigationController.popToViewController(toViewController, animated: true)
        
    }
    
    
    /**
    Method reads from the GoogleService-Info plist and returns a string representing the Google Analytics Tracking Id
    
    - returns: String
    */
    class func getGoogleAnalyticsTrackingId() -> String{
        
        var id : String = ""
        let configurationPath = NSBundle.mainBundle().pathForResource("GoogleService-Info", ofType: "plist")
        
        if((configurationPath) != nil) {
            let configuration = NSDictionary(contentsOfFile: configurationPath!)!
            
            if let trackingId = configuration["TRACKING_ID"] as? String{
               id = trackingId
            }
            
        }
        return id
    }
    
    
    /**
    Method reads from the mqa.plist file and returns a string representing the MQA App key
    
    - returns: String
    */
    class func getMQAAppKey() -> String {
        
        var appKey : String = ""
        let configurationPath = NSBundle.mainBundle().pathForResource("mqa", ofType: "plist")
        
        if((configurationPath) != nil) {
            let configuration = NSDictionary(contentsOfFile: configurationPath!)!
            
            if let applicationKey = configuration["applicationKey"] as? String{
                appKey = applicationKey
            }
            
        }
        return appKey
    }
    
    
    /**
    Method takes in a double parameter and returns a string version of this double without the trailing 0 after the decimal point
    
    - parameter double: Double
    
    - returns: String
    */
    class func removeTailingZero(double: Double) -> String{
        let string = String(format: "%g", double)
        return string
    }

    
    /**
    Method takes in a Int parameter and converts this to a string that represents how expense something is, ie. "€€€"
    
    - parameter number: Int
    
    - returns: String
    */
    class func generateExpensiveString(number : Int) -> String {
        let moneySign = LocalizationUtils.getLocalizedCurrencySymbol()
        var string = ""
        var i = 0
        while( i < number) {
            string = string + moneySign
            i++
        }
        
        return string
    }
    
    
    /**
    Method sets up a startStackView with the number of stars defined by the numberOfStars parameter
    
    - parameter numberOfStars: Double
    - parameter starStackView: UIStackView
    */
    class func setUpStarStackView(numberOfStars : Double, starStackView : UIStackView){
        let floorStars = floor(numberOfStars)
        
        let remainder = numberOfStars - floorStars
        
        for (index, element) in starStackView.subviews.enumerate() {
            
            if(index < Int(floorStars)){
                (element as! UIImageView).image = UIImage(named: "Star")
            }
            else if(remainder > 0 && index == Int(floorStars)){
                (element as! UIImageView).image = UIImage(named: "Star_half")
            }
            else{
                (element as! UIImageView).image = UIImage(named: "Star_empty")
            }
        }
    }
    
    
    /**
    Method takes a string and strikes through this string returning an NSMutableAttributedString
    
    - parameter text: String
    
    - returns: NSMutableAttributedString
    */
    class func strikeThroughString(text: String) -> NSMutableAttributedString {
        
        let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: text)
        attributeString.addAttribute(NSStrikethroughStyleAttributeName, value: 2, range: NSMakeRange(0, attributeString.length))
        
        return attributeString
    }
    
    
    /**
    Method that takes in a price Double parameter and an originalPrice Double parameter and returns a percentage off string
    
    - parameter price:         Double
    - parameter originalPrice: Double
    
    - returns: String
    */
    class func percentageOffString(price : Double, originalPrice : Double) -> String {
        
        let invertedDecimal = price/originalPrice
        let decimal = 1-invertedDecimal
        let percent = decimal * 100
        
        let off = NSLocalizedString("Off", comment: "")
        
        let percentageOffString = "\(self.removeTailingZero(percent))% \(off)"
        
        return percentageOffString
        
    }
    
    
    /**
    Method that takes in a weather condition represented by a string and returns a UIImage representing this weather condition
    
    - parameter condition: String
    
    - returns: UIImage?
    */
    class func getWeatherConditionIcon(condition: String) -> UIImage? {
        
        switch condition {
        case "Clear":
            return UIImage(named: "Weather_sunny")
        case "Rain":
            return UIImage(named: "Weather_rain")
        case "Partly Cloudy":
            return UIImage(named: "Weather_cloudy")
        case "Chance of Rain":
            return UIImage(named: "Weather_shower")
        default:
            return UIImage(named: "Weather_Clearnight")
            
        }
    }

}
