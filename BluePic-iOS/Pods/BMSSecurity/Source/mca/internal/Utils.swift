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

#if swift (>=3.0)

extension Dictionary where Key : Any {
    subscript(caseInsensitive key : Key) -> Value? {
        get {
            if let stringKey = key as? String {
                let searchKeyLowerCase = stringKey.lowercased()
                for currentKey in self.keys {
                    if let stringCurrentKey = currentKey as? String {
                        let currentKeyLowerCase = stringCurrentKey.lowercased()
                        if currentKeyLowerCase == searchKeyLowerCase {
                            return self[currentKey]
                        }
                    }
                }
            }
            return nil
        }
    }
}

public class Utils {
    internal static func concatenateUrls(_ rootUrl:String, path:String) -> String {
        guard !rootUrl.isEmpty else {
            return path
        }
        
        var retUrl = rootUrl
        if !retUrl.hasSuffix("/") {
            retUrl += "/"
        }
        
        if path.hasPrefix("/") {
            retUrl += path.substring(from: path.index(path.startIndex, offsetBy: 1))
        } else {
            retUrl += path
        }
        
        return retUrl
    }
    
    internal static func getParameterValueFromQuery(_ query:String?, paramName:String, caseSensitive:Bool) -> String? {
        guard let myQuery = query  else {
            return nil
        }
        
        let paramaters = myQuery.components(separatedBy: "&")
        
        for val in paramaters {
            let pairs = val.components(separatedBy: "=")
            
            if (pairs.endIndex != 2) {
                continue
            }
            if(caseSensitive) {
                if let normal = pairs[0].removingPercentEncoding, normal == paramName {
                    return pairs[1].removingPercentEncoding
                }
            } else {
                if let normal = pairs[0].removingPercentEncoding?.lowercased(), normal == paramName.lowercased() {
                    return pairs[1].removingPercentEncoding
                }
            }
        }
        return nil
    }
    
    internal static func JSONStringify(_ value: AnyObject, prettyPrinted:Bool = false) throws -> String{
        
        let options = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization.WritingOptions(rawValue: 0)
        
        
        if JSONSerialization.isValidJSONObject(value) {
            do{
                let data = try JSONSerialization.data(withJSONObject: value, options: options)
                guard let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as? String else {
                    throw JsonUtilsErrors.jsonIsMalformed
                }
                return string
            } catch {
                throw JsonUtilsErrors.jsonIsMalformed
            }
        }
        return ""
    }
    
    public static func parseJsonStringtoDictionary(_ jsonString:String) throws ->[String:Any] {
        do {
            guard let data = jsonString.data(using: String.Encoding.utf8), let responseJson =  try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] else {
                throw JsonUtilsErrors.jsonIsMalformed
            }
            return responseJson as [String:Any]
        }
    }
    
    internal static func extractSecureJson(_ response: Response?) throws -> [String:Any?] {
        
        guard let responseText:String = response?.responseText, (responseText.hasPrefix(BMSSecurityConstants.SECURE_PATTERN_START) && responseText.hasSuffix(BMSSecurityConstants.SECURE_PATTERN_END)) else {
            throw JsonUtilsErrors.couldNotExtractJsonFromResponse
        }
        
        let jsonString : String = responseText.substring(with: (responseText.characters.index(responseText.startIndex, offsetBy: BMSSecurityConstants.SECURE_PATTERN_START.characters.count) ..< responseText.characters.index(responseText.endIndex, offsetBy: -BMSSecurityConstants.SECURE_PATTERN_END.characters.count)))
        
        do {
            let responseJson = try parseJsonStringtoDictionary(jsonString)
            return responseJson
        }
    }
    
    //Return the App Name and Version
    internal static func getApplicationDetails() -> (name:String, version:String) {
        var version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        var name = Bundle.main.bundleIdentifier
        if name == nil {
            AuthorizationProcessManager.logger.error(message: "Could not retrieve application name. Application name is set to nil")
            name = "nil"
        }
        if version == nil {
            AuthorizationProcessManager.logger.error(message: "Could not retrieve application version. Application version is set to nil")
            version = "nil"
        }
        return (name!, version!)
        
    }
    
    internal static func getDeviceDictionary() -> [String : Any] {
        let deviceIdentity = MCADeviceIdentity()
        let appIdentity = MCAAppIdentity()
        var device = [String : Any]()
        device[BMSSecurityConstants.JSON_DEVICE_ID_KEY] = deviceIdentity.ID as AnyObject?
        device[BMSSecurityConstants.JSON_MODEL_KEY] =  deviceIdentity.model as AnyObject?
        device[BMSSecurityConstants.JSON_OS_KEY] = deviceIdentity.OS as AnyObject?
        device[BMSSecurityConstants.JSON_APPLICATION_ID_KEY] =  appIdentity.ID as AnyObject?
        device[BMSSecurityConstants.JSON_APPLICATION_VERSION_KEY] =  appIdentity.version as AnyObject?
        device[BMSSecurityConstants.JSON_ENVIRONMENT_KEY] =  BMSSecurityConstants.JSON_IOS_ENVIRONMENT_VALUE as AnyObject?
        
        return device
    }
    
    /**
     Decode base64 code
     
     - parameter strBase64: strBase64 the String to decode
     
     - returns: return decoded String
     */
    
    internal static func decodeBase64WithString(_ strBase64:String) -> Data? {
        
        guard let objPointerHelper = strBase64.cString(using: String.Encoding.ascii), let objPointer = String(validatingUTF8: objPointerHelper) else {
            return nil
        }
        
        let intLengthFixed:Int = (objPointer.characters.count)
        var result:[Int8] = [Int8](repeating: 1, count: intLengthFixed)
        
        var i:Int=0, j:Int=0, k:Int
        var count = 0
        var intLengthMutated:Int = (objPointer.characters.count)
        var current:Character = objPointer[objPointer.characters.index(objPointer.startIndex, offsetBy: count)]
        
        while (current != "\0" && intLengthMutated > 0) {
            intLengthMutated-=1
            
            if current == "=" {
                if  count < intLengthFixed && objPointer[objPointer.characters.index(objPointer.startIndex, offsetBy: count)] != "=" && i%4 == 1 {
                    return nil
                }
                if count == intLengthFixed {
                    break
                }
                current = objPointer[objPointer.characters.index(objPointer.startIndex, offsetBy: count)]
                count+=1
                continue
            }
            let stringCurrent = String(current)
            let singleValueArrayCurrent: [UInt8] = Array(stringCurrent.utf8)
            let intCurrent:Int = Int(singleValueArrayCurrent[0])
            let int8Current = BMSSecurityConstants.base64DecodingTable[intCurrent]
            
            if int8Current == -1 {
                current = objPointer[objPointer.characters.index(objPointer.startIndex, offsetBy: count)]
                count+=1
                continue
            } else if int8Current == -2 {
                return nil
            }
            
            switch (i % 4) {
            case 0:
                result[j] = int8Current << 2
            case 1:
                result[j] |= int8Current >> 4
                j+=1
                result[j] = (int8Current & 0x0f) << 4
            case 2:
                result[j] |= int8Current >> 2
                j+=1
                result[j] = (int8Current & 0x03) << 6
            case 3:
                result[j] |= int8Current
                j+=1
            default:  break
            }
            
            i+=1
            
            if count == intLengthFixed - 1 {
                break
            }
            count+=1
            current = objPointer[objPointer.characters.index(objPointer.startIndex, offsetBy: count)]
        }
        
        // mop things up if we ended on a boundary
        k = j
        if (current == "=") {
            switch (i % 4) {
            case 1:
                // Invalid state
                return nil
            case 2:
                k += 1
                result[k] = 0
            case 3:
                result[k] = 0
            default:
                break
            }
        }
        
        // Setup the return NSData
        return Data(bytes: UnsafeRawPointer(result), count: j)
    }
    
    internal static func base64StringFromData(_ data:Data, length:Int, isSafeUrl:Bool) -> String {
        var ixtext:Int = 0
        var ctremaining:Int
        var input:[Int] = [Int](repeating: 0, count: 3)
        var output:[Int] = [Int](repeating: 0, count: 4)
        var charsonline:Int = 0, ctcopy:Int
        guard data.count >= 1 else {
            return ""
        }
        var result:String = ""
        let count = data.count / MemoryLayout<Int8>.size
        var raw = [Int8](repeating: 0, count: count)
        (data as NSData).getBytes(&raw, length:count * MemoryLayout<Int8>.size)
        while (true) {
            ctremaining = data.count - ixtext
            if ctremaining <= 0 {
                break
            }
            for i in 0..<3 {
                let ix:Int = ixtext + i
                if ix < data.count {
                    input[i] = Int(raw[ix])
                } else {
                    input[i] = 0
                }
            }
            output[0] = (input[0] & 0xFC) >> 2
            output[1] = ((input[0] & 0x03) << 4) | ((input[1] & 0xF0) >> 4)
            output[2] = ((input[1] & 0x0F) << 2) | ((input[2] & 0xC0) >> 6)
            output[3] = input[2] & 0x3F
            ctcopy = 4
            switch (ctremaining) {
            case 1:
                ctcopy = 2
            case 2:
                ctcopy = 3
            default: break
            }
            
            for i in 0..<ctcopy {
                let toAppend = isSafeUrl ? BMSSecurityConstants.base64EncodingTableUrlSafe[output[i]]: BMSSecurityConstants.base64EncodingTable[output[i]]
                result.append(toAppend)
            }
            
            for _ in ctcopy..<4 {
                result += "="
            }
            
            ixtext += 3
            charsonline += 4
            
            if (length > 0) && (charsonline >= length) {
                charsonline = 0
            }
            
        }
        
        return result
    }
    
    internal static func base64StringFromData(_ data:Data, isSafeUrl:Bool) -> String {
        let length = data.count
        return base64StringFromData(data, length: length, isSafeUrl: isSafeUrl)
    }
}
    
#else

extension Dictionary where Key : Any {
    subscript(caseInsensitive key : Key) -> Value? {
        get {
            if let stringKey = key as? String {
                let searchKeyLowerCase = stringKey.lowercaseString
                for currentKey in self.keys {
                    if let stringCurrentKey = currentKey as? String {
                        let currentKeyLowerCase = stringCurrentKey.lowercaseString
                        if currentKeyLowerCase == searchKeyLowerCase {
                            return self[currentKey]
                        }
                    }
                }
            }
            return nil
        }
    }
}

public class Utils {
    
    
    internal static func concatenateUrls(rootUrl:String, path:String) -> String {
        guard !rootUrl.isEmpty else {
            return path
        }
        
        var retUrl = rootUrl
        if !retUrl.hasSuffix("/") {
            retUrl += "/"
        }
        
        if path.hasPrefix("/") {
            retUrl += path.substringWithRange(Range<String.Index>(start: path.startIndex.advancedBy(1), end: path.endIndex))
        } else {
            retUrl += path
        }
        
        return retUrl
    }
    
    internal static func getParameterValueFromQuery(query:String?, paramName:String, caseSensitive:Bool) -> String? {
        guard let myQuery = query  else {
            return nil
        }
        
        let paramaters = myQuery.componentsSeparatedByString("&")
        
        for val in paramaters {
            let pairs = val.componentsSeparatedByString("=")
            
            if (pairs.endIndex != 2) {
                continue
            }
            if(caseSensitive) {
                if let normal = pairs[0].stringByRemovingPercentEncoding where normal == paramName {
                    return pairs[1].stringByRemovingPercentEncoding
                }
            } else {
                if let normal = pairs[0].stringByRemovingPercentEncoding?.lowercaseString where normal == paramName.lowercaseString {
                    return pairs[1].stringByRemovingPercentEncoding
                }
            }
        }
        return nil
    }
    
    internal static func JSONStringify(value: AnyObject, prettyPrinted:Bool = false) throws -> String{
        
        let options = prettyPrinted ? NSJSONWritingOptions.PrettyPrinted : NSJSONWritingOptions(rawValue: 0)
        
        
        if NSJSONSerialization.isValidJSONObject(value) {
            do{
                let data = try NSJSONSerialization.dataWithJSONObject(value, options: options)
                guard let string = NSString(data: data, encoding: NSUTF8StringEncoding) as? String else {
                    throw JsonUtilsErrors.JsonIsMalformed
                }
                return string
            } catch {
                throw JsonUtilsErrors.JsonIsMalformed
            }
        }
        return ""
    }
    
    public static func parseJsonStringtoDictionary(jsonString:String) throws ->[String:AnyObject] {
        do {
            guard let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding), responseJson =  try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject] else {
                throw JsonUtilsErrors.JsonIsMalformed
            }
            return responseJson as [String:AnyObject]
        }
    }
    
    internal static func extractSecureJson(response: Response?) throws -> [String:AnyObject?] {
        
        guard let responseText:String = response?.responseText where (responseText.hasPrefix(BMSSecurityConstants.SECURE_PATTERN_START) && responseText.hasSuffix(BMSSecurityConstants.SECURE_PATTERN_END)) else {
            throw JsonUtilsErrors.CouldNotExtractJsonFromResponse
        }
        
        let jsonString : String = responseText.substringWithRange(Range<String.Index>(start: responseText.startIndex.advancedBy(BMSSecurityConstants.SECURE_PATTERN_START.characters.count), end: responseText.endIndex.advancedBy(-BMSSecurityConstants.SECURE_PATTERN_END.characters.count)))
        
        do {
            let responseJson = try parseJsonStringtoDictionary(jsonString)
            return responseJson
        }
    }
    
    //Return the App Name and Version
    internal static func getApplicationDetails() -> (name:String, version:String) {
        var version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String
        var name = NSBundle.mainBundle().bundleIdentifier
        if name == nil {
            AuthorizationProcessManager.logger.error(message: "Could not retrieve application name. Application name is set to nil")
            name = "nil"
        }
        if version == nil {
            AuthorizationProcessManager.logger.error(message: "Could not retrieve application version. Application version is set to nil")
            version = "nil"
        }
        return (name!, version!)
        
    }
    
    internal static func getDeviceDictionary() -> [String : AnyObject] {
        let deviceIdentity = MCADeviceIdentity()
        let appIdentity = MCAAppIdentity()
        var device = [String : AnyObject]()
        device[BMSSecurityConstants.JSON_DEVICE_ID_KEY] = deviceIdentity.ID
        device[BMSSecurityConstants.JSON_MODEL_KEY] =  deviceIdentity.model
        device[BMSSecurityConstants.JSON_OS_KEY] = deviceIdentity.OS
        device[BMSSecurityConstants.JSON_APPLICATION_ID_KEY] =  appIdentity.ID
        device[BMSSecurityConstants.JSON_APPLICATION_VERSION_KEY] =  appIdentity.version
        device[BMSSecurityConstants.JSON_ENVIRONMENT_KEY] =  BMSSecurityConstants.JSON_IOS_ENVIRONMENT_VALUE
        
        return device
    }
    
    /**
     Decode base64 code
     
     - parameter strBase64: strBase64 the String to decode
     
     - returns: return decoded String
     */
    
    internal static func decodeBase64WithString(strBase64:String) -> NSData? {
        
        guard let objPointerHelper = strBase64.cStringUsingEncoding(NSASCIIStringEncoding), objPointer = String(UTF8String: objPointerHelper) else {
            return nil
        }
        
        let intLengthFixed:Int = (objPointer.characters.count)
        var result:[Int8] = [Int8](count: intLengthFixed, repeatedValue : 1)
        
        var i:Int=0, j:Int=0, k:Int
        var count = 0
        var intLengthMutated:Int = (objPointer.characters.count)
        var current:Character
        
        for current = objPointer[objPointer.startIndex.advancedBy(count++)] ; current != "\0" && intLengthMutated-- > 0 ; current = objPointer[objPointer.startIndex.advancedBy(count++)]  {
            
            if current == "=" {
                if  count < intLengthFixed && objPointer[objPointer.startIndex.advancedBy(count)] != "=" && i%4 == 1 {
                    
                    return nil
                }
                if count == intLengthFixed {
                    break
                }
                
                continue
            }
            let stringCurrent = String(current)
            let singleValueArrayCurrent: [UInt8] = Array(stringCurrent.utf8)
            let intCurrent:Int = Int(singleValueArrayCurrent[0])
            let int8Current = BMSSecurityConstants.base64DecodingTable[intCurrent]
            
            if int8Current == -1 {
                continue
            } else if int8Current == -2 {
                return nil
            }
            
            switch (i % 4) {
            case 0:
                result[j] = int8Current << 2
            case 1:
                result[j] |= int8Current >> 4
                j += 1
                result[j] = (int8Current & 0x0f) << 4
            case 2:
                result[j] |= int8Current >> 2
                j += 1
                result[j] = (int8Current & 0x03) << 6
            case 3:
                result[j] |= int8Current
                j += 1
            default:  break
            }
            i += 1
            
            if count == intLengthFixed {
                break
            }
            
        }
        
        // mop things up if we ended on a boundary
        k = j
        if (current == "=") {
            switch (i % 4) {
            case 1:
                // Invalid state
                return nil
            case 2:
                k += 1
                result[k] = 0
            case 3:
                result[k] = 0
            default:
                break
            }
        }
        
        // Setup the return NSData
        return NSData(bytes: result, length: j)
    }
    internal static func base64StringFromData(data:NSData, length:Int, isSafeUrl:Bool) -> String {
        var ixtext:Int = 0
        var ctremaining:Int
        var input:[Int] = [Int](count: 3, repeatedValue: 0)
        var output:[Int] = [Int](count: 4, repeatedValue: 0)
        var charsonline:Int = 0, ctcopy:Int
        guard data.length >= 1 else {
            return ""
        }
        var result:String = ""
        let count = data.length / sizeof(Int8)
        var raw = [Int8](count: count, repeatedValue: 0)
        data.getBytes(&raw, length:count * sizeof(Int8))
        while (true) {
            ctremaining = data.length - ixtext
            if ctremaining <= 0 {
                break
            }
            
            for i in 0..<3 {
                let ix:Int = ixtext + i
                if ix < data.length {
                    input[i] = Int(raw[ix])
                } else {
                    input[i] = 0
                }
            }
            output[0] = (input[0] & 0xFC) >> 2
            output[1] = ((input[0] & 0x03) << 4) | ((input[1] & 0xF0) >> 4)
            output[2] = ((input[1] & 0x0F) << 2) | ((input[2] & 0xC0) >> 6)
            output[3] = input[2] & 0x3F
            ctcopy = 4
            switch (ctremaining) {
            case 1:
                ctcopy = 2
            case 2:
                ctcopy = 3
            default: break
            }
            
            for i in 0..<ctcopy {
                let toAppend = isSafeUrl ? BMSSecurityConstants.base64EncodingTableUrlSafe[output[i]]: BMSSecurityConstants.base64EncodingTable[output[i]]
                result.append(toAppend)
            }
            for _ in ctcopy..<4 {
                result += "="
            }
            
            ixtext += 3
            charsonline += 4
            
            if (length > 0) && (charsonline >= length) {
                charsonline = 0
            }
            
        }
        
        return result
    }
    
    internal static func base64StringFromData(data:NSData, isSafeUrl:Bool) -> String {
        let length = data.length
        return base64StringFromData(data, length: length, isSafeUrl: isSafeUrl)
    }
}
    
#endif
