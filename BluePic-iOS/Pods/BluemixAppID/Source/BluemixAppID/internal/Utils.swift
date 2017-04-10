/* *     Copyright 2016, 2017 IBM Corp.
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 */

import Foundation
import BMSCore


public class Utils {
    
    
    public static func JSONStringify(_ value: AnyObject, prettyPrinted:Bool = false) throws -> String{
        
        let options = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization.WritingOptions(rawValue: 0)
        
        
        if JSONSerialization.isValidJSONObject(value) {
            do {
                let data = try JSONSerialization.data(withJSONObject: value, options: options)
                guard let string = String(data: data, encoding: String.Encoding.utf8) else {
                    throw AppIDError.jsonUtilsError(msg: "Json is malformed")
                }
                return string
            } catch {
                throw AppIDError.jsonUtilsError(msg: "Json is malformed")
            }
        }
        return ""
    }
    
    public static func parseJsonStringtoDictionary(_ jsonString:String) throws ->[String:Any] {
        do {
            guard let data = jsonString.data(using: String.Encoding.utf8), let responseJson =  try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] else {
                throw AppIDError.jsonUtilsError(msg: "Json is malformed")
            }
            return responseJson as [String:Any]
        }
    }
    
    // TODO: did not delete this method as it is used in appidconstants
    
    //Return the App Name and Version
    internal static func getApplicationDetails() -> (name:String, version:String) {
        var version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        var name = Bundle.main.bundleIdentifier
        if name == nil {
            name = "nil"
        }
        if version == nil {
            version = "nil"
        }
        return (name!, version!)
        
    }
    
        
    /**
     Decode base64 code
     
     - parameter strBase64: strBase64 the String to decode
     
     - returns: return decoded String
     */
    
    public static func decodeBase64WithString(_ strBase64:String, isSafeUrl:Bool) -> Data? {
        
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
            let int8Current = isSafeUrl ?  AppIDConstants.base64DecodingTableUrlSafe[intCurrent] :AppIDConstants.base64DecodingTable[intCurrent]
            
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
        if current == "=" {
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
            switch ctremaining {
            case 1:
                ctcopy = 2
            case 2:
                ctcopy = 3
            default: break
            }
            
            for i in 0..<ctcopy {
                let toAppend = isSafeUrl ? AppIDConstants.base64EncodingTableUrlSafe[output[i]]: AppIDConstants.base64EncodingTable[output[i]]
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
    
    internal static func urlEncode(_ str:String) -> String{
        var encodedString = ""
        var unchangedCharacters = ""
        let FORM_ENCODE_SET = " \"':;<=>@[]^`{}|/\\?#&!$(),~%"
        
        for element: Int in 0x20..<0x7f {
            if !FORM_ENCODE_SET.contains(String(describing: UnicodeScalar(element))) {
                unchangedCharacters += String(Character(UnicodeScalar(element)!))
            }
        }
        
        encodedString = str.trimmingCharacters(in: CharacterSet(charactersIn: "\n\r\t"))
        let charactersToRemove = ["\n", "\r", "\t"]
        for char in charactersToRemove {
            encodedString = encodedString.replacingOccurrences(of: char, with: "")
        }
        if let encodedString = encodedString.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: unchangedCharacters)) {
            return encodedString
        }
        else {
            return "nil"
        }
    }
    
    
    public static func getParamFromQuery(url:URL, paramName: String) -> String? {
        return url.query?.components(separatedBy: "&").filter({(item) in item.hasPrefix(paramName)}).first?.components(separatedBy: "=")[1]
    }
 
    
}
