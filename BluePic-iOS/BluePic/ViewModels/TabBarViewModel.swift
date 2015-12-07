//
//  TabBarViewModel.swift
//  BluePic
//
//  Created by Alex Buck on 12/7/15.
//  Copyright © 2015 MIL. All rights reserved.
//


class TabBarViewModel: NSObject {

    /// Boolean if showLoginScreen() has been called yet this app launch (should only try to show login once)
    var hasTriedToPresentLoginThisAppLaunch = false
    
    
    
    
    func getHasTriedToPresentLoginThisAppLaunch() -> Bool{
        
        return hasTriedToPresentLoginThisAppLaunch
        
    }
    
    
    func setHasTriedToPresentLoginThisAppLaunchToTrue(){
        
        hasTriedToPresentLoginThisAppLaunch = true
        
    }

    
    
    
    
    
    
    
    
    
    
}
