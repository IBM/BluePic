/*
 *     Copyright 2016 IBM Corp.
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 */


import Foundation


#if swift(>=3.0)
    import UserNotifications
    import UserNotificationsUI

/// Class to Handle iOS10 Rich push notifications.
@available(iOS 10.0, *)
open class BMSPushRichPushNotificationOptions:UNNotificationServiceExtension {
    
    // MARK: - Public method
    
    /**
     didReceive method is used inside notification extensions.
     
     - Parameter request: pass the `UNNotificationRequest` from extension
     - Parameter contentHandler: pass the `UNNotificationContent` from extension.
    */
    open class func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        
        var bestAttemptContent: UNMutableNotificationContent?
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
       if let urlString = request.content.userInfo["attachment-url"] as? String, urlString != "" {
            
            if let fileUrl = URL(string: urlString ) {
                // Download the attachment
                URLSession.shared.downloadTask(with: fileUrl) { (location, response, error) in
                    if let location = location {
                        // Move temporary file to remove .tmp extension
                        let tmpDirectory = NSTemporaryDirectory()
                        let tmpFile = "file://".appending(tmpDirectory).appending(fileUrl.lastPathComponent)
                        let tmpUrl = URL(string: tmpFile)!
                        try! FileManager.default.moveItem(at: location, to: tmpUrl)
                        
                        // Add the attachment to the notification content
                        if let attachment = try? UNNotificationAttachment(identifier: "", url: tmpUrl, options:nil) {

                            bestAttemptContent?.attachments = [attachment]
                        }
                    }
                    // Serve the notification content
                    contentHandler(bestAttemptContent!)
                    }.resume()
            }
            
        } else {
             contentHandler(bestAttemptContent!)
        }
    }
}
#endif
