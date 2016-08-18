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
import BMSSecurity
import BMSPush

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    /**
     Method called when app finishes up launching. In this case we initialize Bluemix Mobile Client Access with Facebook

     - parameter application:   UIApplication.
     - parameter launchOptions: [NSObject: Anyobject]?

     - returns: Bool
     */
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        //register for remote notifications aka prompt user to give permission for notifications
        let notificationTypes: UIUserNotificationType = [UIUserNotificationType.Badge, UIUserNotificationType.Alert, UIUserNotificationType.Sound]
        let notificationSettings: UIUserNotificationSettings = UIUserNotificationSettings(forTypes: notificationTypes, categories: nil)
        application.registerUserNotificationSettings(notificationSettings)
        application.registerForRemoteNotifications()

        //pre load the keyboard on the camera confirmayion screen to prevent laggy behavior
        preLoadKeyboardToPreventLaggyKeyboardInCameraConfirmationScreen()

        //inialialize Bluemix Mobile Client Access to allow for facebook Authentication
        return self.initializeBackendForFacebookAuth(application, launchOptions: launchOptions)
    }

    /**
     Method called when the user registers from remote notifications

     - parameter application:
     - parameter deviceToken:
     */
    func application (application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        if BluemixDataManager.SharedInstance.bluemixConfig.pushAppGUID != "" {
            let push =  BMSPushClient.sharedInstance
            push.initializeWithAppGUID(BluemixDataManager.SharedInstance.bluemixConfig.pushAppGUID)
            push.registerWithDeviceToken(deviceToken) { (response, statusCode, error) in
                if error.isEmpty {
                    print( "Response during device registration : \(response)")
                    print( "status code during device registration : \(statusCode)")
                } else {
                    print( "Error during device registration \(error) ")
                    print( "Error during device registration \n  - status code: \(statusCode) \n Error :\(error) \n")
                }
            }
        }
    }

    /**
     Method called when device receives a remote notification

     - parameter application:
     - parameter userInfo:
     - parameter completionHandler:
     */
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {

        //could not grab instance of tab bar fail silently
        guard let tabBarController = self.window?.rootViewController as? TabBarViewController, feedNav = tabBarController.viewControllers?.first as? FeedNavigationController else {
            completionHandler(UIBackgroundFetchResult.Failed)
            return
        }

        //handle a push notification by showing an alert that says your image was processed
        if application.applicationState == UIApplicationState.Background || application.applicationState == UIApplicationState.Inactive {
            loadImageDetail(userInfo, tabBarController: tabBarController, feedNav: feedNav)
        } else {
          if let aps = userInfo["aps"], category = aps["category"] as? String,
            alert = aps["alert"] as? [String:AnyObject], body = alert["body"] as? String where category == "imageProcessed" {

            let alert = UIAlertController(title: NSLocalizedString(body, tableName: "Server", bundle: NSBundle.mainBundle(), value: "", comment: ""),
                                              message: NSLocalizedString("Would you like to view your image now?", comment: ""),
                                              preferredStyle: UIAlertControllerStyle.Alert)

                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.Cancel, handler: nil))
                alert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: UIAlertActionStyle.Default, handler: { (action) in
                    self.loadImageDetail(userInfo, tabBarController: tabBarController, feedNav: feedNav)
                }))
                feedNav.presentViewController(alert, animated: true, completion: nil)
            }
        }
        completionHandler(UIBackgroundFetchResult.NewData)
    }

    /**
     Loads image detail view for image mentioned in userInfo dictionary

     - parameter userInfo:         dictionary of info from a push notification
     - parameter tabBarController: primary tab bar controller for application
     - parameter feedNav:          root navigation controller for feed flow
     */
    func loadImageDetail(userInfo: [NSObject : AnyObject], tabBarController: TabBarViewController, feedNav: FeedNavigationController) {
        if let payload = userInfo["payload"] as? String, dictionary = Utils.convertStringToDictionary(payload), image = Image(dictionary),
            imageDetailVC = Utils.vcWithNameFromStoryboardWithName("ImageDetailViewController", storyboardName: "Feed") as? ImageDetailViewController {

            let imageDetailViewModel = ImageDetailViewModel(image: image)
            imageDetailVC.viewModel = imageDetailViewModel
            tabBarController.selectedIndex = 0
            feedNav.popToRootViewControllerAnimated(false)
            feedNav.pushViewController(imageDetailVC, animated: true)
        }
    }

    /**
     Method preloads keyboard to prevent the keyboard on the camera confirmation screen to be laggy when touching the text field for the first time
     */
    func preLoadKeyboardToPreventLaggyKeyboardInCameraConfirmationScreen() {

        let lagFreeField = UITextField()
        self.window?.addSubview(lagFreeField)
        lagFreeField.becomeFirstResponder()
        lagFreeField.resignFirstResponder()
        lagFreeField.removeFromSuperview()

    }

    /**
     Method to initialize Bluemix Mobile Client Access with Facebook
     */
    func initializeBackendForFacebookAuth(application: UIApplication, launchOptions: [NSObject: AnyObject]?) -> Bool {
        //Initialize backend
        BluemixDataManager.SharedInstance.initilizeBluemixAppRoute()

        //Initialize Facebook
        MCAAuthorizationManager.sharedInstance.setAuthorizationPersistencePolicy(PersistencePolicy.ALWAYS)
        BMSClient.sharedInstance.authorizationManager = MCAAuthorizationManager.sharedInstance
        FacebookAuthenticationManager.sharedInstance.register()

        return FacebookAuthenticationManager.sharedInstance.onFinishLaunching(application, withOptions:  launchOptions)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        //FBAppEvents.activateApp()
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
    }

    /**
     Method handles opening a facebook url for facebook login

     - parameter application:       UIApplication
     - parameter url:               NSURL
     - parameter sourceApplication: String?
     - parameter annotation:        AnyObject

     - returns: Bool
     */
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FacebookAuthenticationManager.sharedInstance.onOpenURL(application, url: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}
