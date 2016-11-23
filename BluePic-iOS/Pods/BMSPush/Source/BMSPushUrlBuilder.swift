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

import UIKit
import BMSCore

#if swift(>=3.0)
    
    internal class BMSPushUrlBuilder: NSObject {
        
        internal  let FORWARDSLASH = "/";
        internal  let IMFPUSH = "imfpush";
        internal  let V1 = "v1";
        internal  let APPS = "apps";
        internal  let AMPERSAND = "&";
        internal  let QUESTIONMARK = "?";
        internal  let SUBZONE = "subzone";
        internal  let EQUALTO = "=";
        internal  let SUBSCRIPTIONS = "subscriptions";
        internal  let MESSAGES = "messages";
        internal  let TAGS = "tags";
        internal  let DEVICES = "devices";
        internal  let TAGNAME = "tagName";
        internal  let DEVICEID = "deviceId";
        internal  let defaultProtocol = "https";
        
        internal final var pwUrl_ = String()
        internal final var reWritedomain = String()
        internal final var clientSecretHeader = String()

        init(applicationID:String, clientSecret:String) {
            
            if !(clientSecret.isEmpty) {
                clientSecretHeader = clientSecret
            }
            
            if(!BMSPushClient.overrideServerHost.isEmpty){
                pwUrl_ += BMSPushClient.overrideServerHost
            }
            else {
                pwUrl_ += defaultProtocol
                pwUrl_ += "://"
                
                if BMSClient.sharedInstance.bluemixRegion?.contains("stage1-test") == true || BMSClient.sharedInstance.bluemixRegion?.contains("stage1-dev") == true {
                    
                    pwUrl_ += IMFPUSH
                    pwUrl_ += ".stage1.mybluemix.net"
                    if BMSClient.sharedInstance.bluemixRegion?.contains("stage1-test") == true {
                        
                        reWritedomain = "stage1-test.ng.bluemix.net"
                    }
                    else{
                        reWritedomain = "stage1-dev.ng.bluemix.net"
                    }
                }
                else{
                    pwUrl_ += IMFPUSH
                    pwUrl_ += BMSClient.sharedInstance.bluemixRegion!
                    reWritedomain = ""
                }
            }
            pwUrl_ += FORWARDSLASH
            pwUrl_ += IMFPUSH
            pwUrl_ += FORWARDSLASH
            pwUrl_ += V1
            pwUrl_ += FORWARDSLASH
            pwUrl_ += APPS
            pwUrl_ += FORWARDSLASH
            pwUrl_ += applicationID
            pwUrl_ += FORWARDSLASH
        }
        
        func addHeader() -> [String: String] {
            
            if reWritedomain.isEmpty {
                if(clientSecretHeader.isEmpty){
                    return [IMFPUSH_CONTENT_TYPE_KEY:IMFPUSH_CONTENT_TYPE_JSON]
                }
                return [IMFPUSH_CONTENT_TYPE_KEY:IMFPUSH_CONTENT_TYPE_JSON, IMFPUSH_CLIENT_SECRET:clientSecretHeader]
            }
            else{
                if clientSecretHeader.isEmpty {
                    return [IMFPUSH_CONTENT_TYPE_KEY:IMFPUSH_CONTENT_TYPE_JSON, IMFPUSH_X_REWRITE_DOMAIN:reWritedomain]
                }
                return [IMFPUSH_CONTENT_TYPE_KEY:IMFPUSH_CONTENT_TYPE_JSON, IMFPUSH_X_REWRITE_DOMAIN:reWritedomain, IMFPUSH_CLIENT_SECRET:clientSecretHeader]
            }
            
        }

        
        func getSubscribedDevicesUrl(devID:String) -> String {
            
            var deviceIdUrl:String = getDevicesUrl()
            deviceIdUrl += FORWARDSLASH
            deviceIdUrl += devID
            return deviceIdUrl
        }
        
        func getDevicesUrl() -> String {
            
            return getCollectionUrl(collectionName: DEVICES)
        }
        
        func getTagsUrl() -> String {
            
            return getCollectionUrl(collectionName: TAGS)
        }
        
        func getSubscriptionsUrl() -> String {
            
            return getCollectionUrl(collectionName: SUBSCRIPTIONS)
        }
        
        func getAvailableSubscriptionsUrl(deviceId : String) -> String {
            
            var subscriptionURL = getCollectionUrl(collectionName: SUBSCRIPTIONS)
            subscriptionURL += QUESTIONMARK
            subscriptionURL += "deviceId=\(deviceId)"
            
            return subscriptionURL;
        }
        
        func getUnSubscribetagsUrl() -> String {
            
            var unSubscriptionURL = getCollectionUrl(collectionName: SUBSCRIPTIONS)
            unSubscriptionURL += QUESTIONMARK
            unSubscriptionURL += IMFPUSH_ACTION_DELETE
            
            return unSubscriptionURL
        }
        
        func getUnregisterUrl (deviceId : String) -> String {
            
            var deviceUnregisterUrl:String = getDevicesUrl()
            deviceUnregisterUrl += FORWARDSLASH
            deviceUnregisterUrl += deviceId
            
            return deviceUnregisterUrl
        }
        
        func getSendMessageDeliveryStatus (messageId : String) -> String {
            
            var sendMessageDeliveryStatusUrl:String = getCollectionUrl(collectionName: MESSAGES)
            sendMessageDeliveryStatusUrl += FORWARDSLASH
            sendMessageDeliveryStatusUrl += messageId
            return sendMessageDeliveryStatusUrl
        }
        
        
        internal func getCollectionUrl (collectionName:String) -> String {
            
            var collectionUrl:String = pwUrl_
            collectionUrl += collectionName
            
            return collectionUrl
        }
    }

    
#else
    
    internal class BMSPushUrlBuilder: NSObject {
    
    internal  let FORWARDSLASH = "/";
    internal  let IMFPUSH = "imfpush";
    internal  let V1 = "v1";
    internal  let APPS = "apps";
    internal  let AMPERSAND = "&";
    internal  let QUESTIONMARK = "?";
    internal  let SUBZONE = "subzone";
    internal  let EQUALTO = "=";
    internal  let SUBSCRIPTIONS = "subscriptions";
    internal  let MESSAGES = "messages";
    internal  let TAGS = "tags";
    internal  let DEVICES = "devices";
    internal  let TAGNAME = "tagName";
    internal  let DEVICEID = "deviceId";
    internal  let defaultProtocol = "https";
    
    internal final var pwUrl_ = String()
    internal final var reWritedomain = String()
    internal final var clientSecretHeader = String()
    
        init(applicationID:String, clientSecret:String) {
            
            if !(clientSecret.isEmpty) {
                clientSecretHeader = clientSecret
            }
            if(!BMSPushClient.overrideServerHost.isEmpty){
                pwUrl_ += BMSPushClient.overrideServerHost
            }
            else {
                pwUrl_ += defaultProtocol
                pwUrl_ += "://"
                
                if BMSClient.sharedInstance.bluemixRegion?.containsString("stage1-test") == true || BMSClient.sharedInstance.bluemixRegion?.containsString("stage1-dev") == true {
                    
                    pwUrl_ += IMFPUSH
                    pwUrl_ += ".stage1.mybluemix.net"
                    if BMSClient.sharedInstance.bluemixRegion?.containsString("stage1-test") == true {
                        
                        reWritedomain = "stage1-test.ng.bluemix.net"
                    }
                    else{
                        reWritedomain = "stage1-dev.ng.bluemix.net"
                    }
                }
                else{
                    pwUrl_ += IMFPUSH
                    pwUrl_ += BMSClient.sharedInstance.bluemixRegion!
                    reWritedomain = ""
                }
            }
            pwUrl_ += FORWARDSLASH
            pwUrl_ += IMFPUSH
            pwUrl_ += FORWARDSLASH
            pwUrl_ += V1
            pwUrl_ += FORWARDSLASH
            pwUrl_ += APPS
            pwUrl_ += FORWARDSLASH
            pwUrl_ += applicationID
            pwUrl_ += FORWARDSLASH
        }
        
        func addHeader() -> [String: String] {
            
            if reWritedomain.isEmpty {
                if(clientSecretHeader.isEmpty){
                    return [IMFPUSH_CONTENT_TYPE_KEY:IMFPUSH_CONTENT_TYPE_JSON]
                }
                return [IMFPUSH_CONTENT_TYPE_KEY:IMFPUSH_CONTENT_TYPE_JSON, IMFPUSH_CLIENT_SECRET:clientSecretHeader]
            }
            else{
                if clientSecretHeader.isEmpty {
                    return [IMFPUSH_CONTENT_TYPE_KEY:IMFPUSH_CONTENT_TYPE_JSON, IMFPUSH_X_REWRITE_DOMAIN:reWritedomain]
                }
                return [IMFPUSH_CONTENT_TYPE_KEY:IMFPUSH_CONTENT_TYPE_JSON, IMFPUSH_X_REWRITE_DOMAIN:reWritedomain, IMFPUSH_CLIENT_SECRET:clientSecretHeader]
            }
            
        }
        
        func getSubscribedDevicesUrl(devID:String) -> String {
            
            var deviceIdUrl:String = getDevicesUrl()
            deviceIdUrl += FORWARDSLASH
            deviceIdUrl += devID
            return deviceIdUrl
        }
        
        func getDevicesUrl() -> String {
            
            return getCollectionUrl(DEVICES)
        }
        
        func getTagsUrl() -> String {
            
            return getCollectionUrl(TAGS)
        }
        
        func getSubscriptionsUrl() -> String {
            
            return getCollectionUrl(SUBSCRIPTIONS)
        }
        
        func getAvailableSubscriptionsUrl(deviceId : String) -> String {
            
            var subscriptionURL = getCollectionUrl(SUBSCRIPTIONS)
            subscriptionURL += QUESTIONMARK
            subscriptionURL += "deviceId=\(deviceId)"
            
            return subscriptionURL;
        }
        
        func getUnSubscribetagsUrl() -> String {
            
            var unSubscriptionURL = getCollectionUrl(SUBSCRIPTIONS)
            unSubscriptionURL += QUESTIONMARK
            unSubscriptionURL += IMFPUSH_ACTION_DELETE
            
            return unSubscriptionURL
        }
        
        func getUnregisterUrl (deviceId : String) -> String {
            
            var deviceUnregisterUrl:String = getDevicesUrl()
            deviceUnregisterUrl += FORWARDSLASH
            deviceUnregisterUrl += deviceId
            
            return deviceUnregisterUrl
        }
    
        func getSendMessageDeliveryStatus (messageId : String) -> String {
            
            var sendMessageDeliveryStatusUrl:String = getCollectionUrl(MESSAGES)
            sendMessageDeliveryStatusUrl += FORWARDSLASH
            sendMessageDeliveryStatusUrl += messageId
            return sendMessageDeliveryStatusUrl
        }

    
        internal func getCollectionUrl (collectionName:String) -> String {
            
            var collectionUrl:String = pwUrl_
            collectionUrl += collectionName
            
            return collectionUrl
        }
    }

    
#endif
