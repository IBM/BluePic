/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
This sample program is provided AS IS and may be used, executed, copied and modified without royalty payment by customer (a) for its own instruction and study, (b) in order to develop applications designed to run with an IBM product, either for customer's own internal use or for redistribution by customer, as part of such an application, in customer's own products.
*/

import UIKit


/// MARK: Static Methods
extension LoadingViewManager {
    
    
    /**
    Method that creates the view
    
    - returns: LoadingView?
    */
    func createView() -> LoadingView? {
        
        let returnView: LoadingView?
        
        returnView = LoadingView.instanceFromNib()
        returnView?.addImagesToArray()
        
        return returnView
    }
    
}

/// Loading view manager
class LoadingViewManager: NSObject {
    
    /// Shared instance
    static let SharedInstance: LoadingViewManager = {
        let instance = LoadingViewManager()
        return instance
        }()
    
    /// loading view
    var loadingView: LoadingView!
    
    /// callback
    var callback: (()->())!
    
    
    /**
    show the loading view for a certain number of seconds with a title. if seconds is 0, will animate until dismissLoadingView is called
    
    - parameter seconds:        seconds to show
    - parameter title:          title label
    - parameter callbackMethod: callback to execute when finished
    */
    func showLoadingViewforSecondsWithText(seconds: NSTimeInterval!, title: String!, callbackMethod: (()->())?) {
        
        let rootVC = Utils.rootViewController()
        
        self.loadingView = createView()
        
        self.loadingView.frame = CGRect(
            x: 0,
            y: 0,
            width: rootVC.view.frame.width,
            height: rootVC.view.frame.height
        )
        
        rootVC.view.addSubview(loadingView)
        
        //set text
        self.loadingView.titleLabel.text = title
        
        //set callback
        if let cb = callbackMethod {
            self.callback = cb
        }
        
        self.loadingView.animationTime = seconds
        
        if (seconds != 0) { //set time to hide after
            
            self.loadingView.startLoadingAnimation()
            
            var _ = NSTimer.scheduledTimerWithTimeInterval(seconds, target: self, selector: Selector("dismissLoadingView"), userInfo: nil, repeats: false)
            
        } else { //show forever and hide later on manually by calling dismissLoadingView()
            
            self.loadingView.startLoadingAnimation()
            
        }
        
    }
    
    /**
    Method to dismiss and stop the loading animation
    */
    func dismissLoadingView() {

        self.loadingView.stopLoadingAnimation()
        self.loadingView.removeFromSuperview()
        if let _ = self.callback {
            self.callback()
        }
    }
    
}
