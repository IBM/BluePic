//
//  BMSPushRichPushNotificationOptions.swift
//  BMSPush
//
//  Created by Jim Dickens on 12/12/16.
//  Copyright © 2016 IBM Corp. All rights reserved.
//

import Foundation


#if swift(>=3.0)
    import UserNotifications
    import UserNotificationsUI


@available(iOS 10.0, *)
open class BMSPushRichPushNotificationOptions:UNNotificationServiceExtension {
    
    open class func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        
        var bestAttemptContent: UNMutableNotificationContent?
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        let urlString = request.content.userInfo["attachment-url"] as? String
        if let fileUrl = URL(string: urlString! ) {
            // Download the attachment
            URLSession.shared.downloadTask(with: fileUrl) { (location, response, error) in
                if let location = location {
                    // Move temporary file to remove .tmp extension
                    let tmpDirectory = NSTemporaryDirectory()
                    let tmpFile = "file://".appending(tmpDirectory).appending(fileUrl.lastPathComponent)
                    let tmpUrl = URL(string: tmpFile)!
                    try! FileManager.default.moveItem(at: location, to: tmpUrl)
                    
                    // Add the attachment to the notification content
                    if let attachment = try? UNNotificationAttachment(identifier: "video", url: tmpUrl, options:nil) {
                        bestAttemptContent?.attachments = [attachment]
                    }
                }
                // Serve the notification content
                contentHandler(bestAttemptContent!)
                }.resume()
        }
    }
}
#endif