//
//  ReplicatorDelegates.swift
//  BluePic
//
//  Created by Rolando Asmat on 12/10/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import Foundation

/**
 * Delegate for Push Replicators.
 */
class PushDelegate:NSObject, CDTReplicatorDelegate {
    
    //var handleAppStartUpResultCallback : ((dataManagerNotification : DataManagerNotification)->())!
    
    
    /**
    * Called when the replicator changes state.
    */
    func replicatorDidChangeState(replicator:CDTReplicator) {
        print("PUSH Replicator changed state.")
    }
    
    /**
     * Called whenever the replicator changes progress
     */
    func replicatorDidChangeProgress(replicator:CDTReplicator) {
        print("PUSH Replicator changed progess.")
    }
    
    /**
     * Called when a state transition to COMPLETE or STOPPED is
     * completed.
     */
    func replicatorDidComplete(replicator:CDTReplicator) {
        print("PUSH Replicator completed.")
        
        
        CameraDataManager.SharedInstance.clearPictureUploadQueue()
        
        DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.CloudantPushDataSuccess)
        //may need to add logic to know when done pushing to hide fb login
    }
    
    /**
     * Called when a state transition to ERROR is completed.
     */
    func replicatorDidError(replicator:CDTReplicator, info:NSError) {
        print("PUSH Replicator ERROR: \(info)")
        //show error when trying to push when creating
        DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.CloudantPushDataFailure)
    }
}

/**
 * Delegate for Pull Replicators.
 */
class PullDelegate:NSObject, CDTReplicatorDelegate {
    
    /**
     * Called when the replicator changes state.
     */
    func replicatorDidChangeState(replicator:CDTReplicator) {
        print("PULL Replicator changed state.")
    }
    
    /**
     * Called whenever the replicator changes progress
     */
    func replicatorDidChangeProgress(replicator:CDTReplicator) {
        print("PULL Replicator changed progess.")
    }
    
    /**
     * Called when a state transition to COMPLETE or STOPPED is
     * completed.
     */
    func replicatorDidComplete(replicator:CDTReplicator) {
        print("PULL Replicator completed.")
        DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.CloudantPullDataSuccess)
    }
    
    /**
     * Called when a state transition to ERROR is completed.
     */
    func replicatorDidError(replicator:CDTReplicator, info:NSError) {
        print("PULL Replicator ERROR: \(info)")
        DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.CloudantPullDataFailure)
    }
    
}

