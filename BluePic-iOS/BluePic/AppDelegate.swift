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
import BluemixAppID
import BMSPush

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    /// Method called when app finishes up launching. In this case we initialize Bluemix App ID SDK for Facebook login and initialize Push
    ///
    /// - parameter application:   UIApplication
    /// - parameter launchOptions: [UIApplicationLaunchOptionsKey: Any]?
    ///
    /// - returns: Bool
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // Kick off push notification registration
        BMSPushClient.sharedInstance.initializeWithAppGUID(appGUID: BluemixDataManager.SharedInstance.bluemixConfig.pushAppGUID, clientSecret: BluemixDataManager.SharedInstance.bluemixConfig.pushClientSecret)

        //pre load the keyboard on the camera confirmayion screen to prevent laggy behavior
        preLoadKeyboardToPreventLaggyKeyboardInCameraConfirmationScreen()

        self.initializeAppIdForAuth()
        return true
    }

    /**
     Method called when the user registers from remote notifications

     - parameter application:
     - parameter deviceToken:
     */
    func application (_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        if BluemixDataManager.SharedInstance.bluemixConfig.isPushConfigured {
            let push =  BMSPushClient.sharedInstance
            push.registerWithDeviceToken(deviceToken: deviceToken) { response, statusCode, error in
                if error.isEmpty {
                    print( "Response during device registration : \(String(describing: response))")
                    print( "status code during device registration : \(String(describing: statusCode))")
                } else {
                    print( "Error during device registration \(error) ")
                    print( "Error during device registration \n  - status code: \(String(describing: statusCode)) \n Error :\(error) \n")
                }
            }
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for push notifications with error: \(error)")
    }

    /**
     Method called when device receives a remote notification

     - parameter application:
     - parameter userInfo:
     - parameter completionHandler:
     */
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        //could not grab instance of tab bar fail silently
        guard let rootViewController = self.window?.rootViewController,
              let tabBarController = rootViewController.childViewControllers.first as? TabBarViewController,
              let feedNav = tabBarController.viewControllers?.first as? FeedNavigationController else {
            completionHandler(UIBackgroundFetchResult.failed)
            return
        }

        //handle a push notification by showing an alert that says your image was processed
        if application.applicationState == UIApplicationState.background || application.applicationState == UIApplicationState.inactive {
            loadImageDetail(userInfo, tabBarController: tabBarController, feedNav: feedNav)
        } else {
            if let aps = userInfo["aps"] as? [AnyHashable: Any], let category = aps["category"] as? String,
            let alert = aps["alert"] as? [AnyHashable: Any], let body = alert["body"] as? String, category == "imageProcessed" {

            let alert = UIAlertController(title: NSLocalizedString(body, tableName: "Server", bundle: Bundle.main, value: "", comment: ""),
                                              message: NSLocalizedString("Would you like to view your image now?", comment: ""),
                                              preferredStyle: UIAlertControllerStyle.alert)

                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.cancel, handler: nil))
                alert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: UIAlertActionStyle.default, handler: { (_) in
                    self.loadImageDetail(userInfo, tabBarController: tabBarController, feedNav: feedNav)
                }))
                feedNav.present(alert, animated: true, completion: nil)
            }
        }
        completionHandler(UIBackgroundFetchResult.newData)
    }

    /**
     Loads image detail view for image mentioned in userInfo dictionary

     - parameter userInfo:         dictionary of info from a push notification
     - parameter tabBarController: primary tab bar controller for application
     - parameter feedNav:          root navigation controller for feed flow
     */
    func loadImageDetail(_ userInfo: [AnyHashable: Any], tabBarController: TabBarViewController, feedNav: FeedNavigationController) {
        if let payload = userInfo["payload"] as? String, let dictionary = Utils.convertStringToDictionary(payload), let image = Image(dictionary),
            let imageDetailVC = Utils.vcWithNameFromStoryboardWithName("ImageDetailViewController", storyboardName: "Feed") as? ImageDetailViewController {

            let imageDetailViewModel = ImageDetailViewModel(image: image)
            imageDetailVC.viewModel = imageDetailViewModel
            tabBarController.selectedIndex = 0
            feedNav.popToRootViewController(animated: false)
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
     Method to initialize Bluemix App ID SDK for Facebook login
     */
    func initializeAppIdForAuth() {

        //Initialize backend
        BluemixDataManager.SharedInstance.initilizeBluemixAppRoute()

        if BluemixDataManager.SharedInstance.bluemixConfig.appIdTenantId != "" {

            let bmsclient = BMSClient.sharedInstance
            bmsclient.initialize(bluemixRegion: BluemixDataManager.SharedInstance.bluemixConfig.appRegion)
            let appid = AppID.sharedInstance
            appid.initialize(tenantId: BluemixDataManager.SharedInstance.bluemixConfig.appIdTenantId,
                             bluemixRegion: BluemixDataManager.SharedInstance.bluemixConfig.appRegion)
            let appIdAuthorizationManager = AppIDAuthorizationManager(appid: appid)
            bmsclient.authorizationManager = appIdAuthorizationManager

            AppID.sharedInstance.initialize(tenantId: BluemixDataManager.SharedInstance.bluemixConfig.appIdTenantId,
                                            bluemixRegion: BluemixDataManager.SharedInstance.bluemixConfig.appRegion)
        } else {
            print("Error: No App ID tenantId, failed to initialize authentication flow.")
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        //FBAppEvents.activateApp()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    /// Method helps finish the login process after Facebook login
    ///
    /// - Parameters:
    ///   - app: UIApplication
    ///   - url: URL
    ///   - options: options for opening the app
    /// - Returns: Bool
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        return AppID.sharedInstance.application(app, open: url, options: options)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}
