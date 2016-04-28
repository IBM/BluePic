/*
*     Copyright 2015 IBM Corp.
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
import BMSCore

//AuthorizationRequest is used internally to send authorization requests.
internal class AuthorizationRequest : BaseRequest {
    
    internal func send(completionHandler: BmsCompletionHandler?) {
        sendWithCompletionHandler(completionHandler)
    }
    
    //Add new header
    internal func addHeader(key:String, val:String) {
        headers[key] = val
    }
    
    //Iterate and add all new headers
    internal func addHeaders(newHeaders: [String:String]) {
        for (key,value) in newHeaders {
            addHeader(key, val: value)
        }
    }
    
    internal init(url:String, method:HttpMethod) {
        super.init(url: url, headers: nil, queryParameters: nil, method: method, timeout: 0)
        allowRedirects = false
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = timeout
        networkSession = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    /**
     * Send this resource request asynchronously, with the given form parameters as the request body.
     * This method will set the content type header to "application/x-www-form-urlencoded".
     *
     * @param formParameters The parameters to put in the request body
     * @param listener       The listener whose onSuccess or onFailure methods will be called when this request finishes.
     */
    internal func sendWithCompletionHandler(formParamaters : [String : String], callback: BmsCompletionHandler?) {
        headers[BaseRequest.CONTENT_TYPE] = "application/x-www-form-urlencoded"
        var body = ""
        var i = 0
        //creating body params
        for (key, val) in formParamaters {
            body += "\(urlEncode(key))=\(urlEncode(val))"
            if i < formParamaters.count - 1 {
                body += "&"
            }
            i+=1
        }
        sendString(body, completionHandler: callback)
    }
    private func urlEncode(str:String) -> String{
        var encodedString = ""
        var unchangedCharacters = ""
        let FORM_ENCODE_SET = " \"':;<=>@[]^`{}|/\\?#&!$(),~%"
        let range = NSMakeRange(0x20, 0x5f).toRange()!
        range.forEach({(element:Int) in
            if !FORM_ENCODE_SET.containsString(String(UnicodeScalar(element))) {
                unchangedCharacters += String(Character(UnicodeScalar(element)))
            }
        })
        encodedString = str.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "\n\r\t"))
        let charactersToRemove = ["\n", "\r", "\t"]
        for char in charactersToRemove {
            encodedString = encodedString.stringByReplacingOccurrencesOfString(char, withString: "")
        }
        if let encodedString = encodedString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet(charactersInString: unchangedCharacters)) {
            return encodedString
        }
        else {
            return "nil"
        }
    }
}