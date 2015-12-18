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
        self.initializeBackendForFacebookAuth()
                
        return true
    }
    
    
    /**
     Method to initialize Bluemix Mobile Client Access with Facebook
     */
    func initializeBackendForFacebookAuth() {
        //Initialize backend
        let key = Utils.getKeyFromPlist("keys", key: "backend_route")
        let guid = Utils.getKeyFromPlist("keys", key: "GUID")
        IMFClient.sharedInstance().initializeWithBackendRoute(key, backendGUID: guid);
    
        //Initialize Facebook
        IMFFacebookAuthenticationHandler.sharedInstance().registerWithDefaultDelegate()
    
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
        FBAppEvents.activateApp()
    }
    
    
    /**
     Method handles opening a facebook url for facebook login
     
     - parameter application:       UIApplication
     - parameter url:               NSURL
     - parameter sourceApplication: String?
     - parameter annotation:        AnyObject
     
     - returns: Bool
     */
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?,annotation: AnyObject) -> Bool {
        return FBAppCall.handleOpenURL(url, sourceApplication:sourceApplication)
    }
    
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

