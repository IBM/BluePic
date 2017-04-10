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


internal class SecurityUtils {
    
       private static func getKeyBitsFromKeyChain(_ tag:String) throws -> Data {
        let keyAttr : [NSString:AnyObject] = [
            kSecClass : kSecClassKey,
            kSecAttrApplicationTag: tag as AnyObject,
            kSecAttrKeyType : kSecAttrKeyTypeRSA,
            kSecReturnData : true as AnyObject
        ]
        var result: AnyObject?
        
        let status = SecItemCopyMatching(keyAttr as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw AppIDError.generalError
        }
        return result as! Data
        
    }
    
    internal static func generateKeyPair(_ keySize:Int, publicTag:String, privateTag:String) throws {
        //make sure keys are deleted
        _ = SecurityUtils.deleteKeyFromKeyChain(publicTag)
        _ = SecurityUtils.deleteKeyFromKeyChain(privateTag)
        
        var status:OSStatus = noErr
        var privateKey:SecKey?
        var publicKey:SecKey?
        
        let privateKeyAttr : [NSString:AnyObject] = [
            kSecAttrIsPermanent : true as AnyObject,
            kSecAttrApplicationTag : privateTag as AnyObject,
            kSecAttrKeyClass : kSecAttrKeyClassPrivate
        ]
        
        let publicKeyAttr : [NSString:AnyObject] = [
            kSecAttrIsPermanent : true as AnyObject,
            kSecAttrApplicationTag : publicTag as AnyObject,
            kSecAttrKeyClass : kSecAttrKeyClassPublic,
            ]
        
        let keyPairAttr : [NSString:AnyObject] = [
            kSecAttrKeyType : kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits : keySize as AnyObject,
            kSecPublicKeyAttrs : publicKeyAttr as AnyObject,
            kSecPrivateKeyAttrs : privateKeyAttr as AnyObject
        ]
        
        status = SecKeyGeneratePair(keyPairAttr as CFDictionary, &publicKey, &privateKey)
        if (status != errSecSuccess) {
            throw AppIDError.generalError
        }
    }
    
    private static func getKeyRefFromKeyChain(_ tag:String) throws -> SecKey {
        let keyAttr : [NSString:AnyObject] = [
            kSecClass : kSecClassKey,
            kSecAttrApplicationTag: tag as AnyObject,
            kSecAttrKeyType : kSecAttrKeyTypeRSA,
            kSecReturnRef : kCFBooleanTrue
        ]
        var result: AnyObject?
        
        let status = SecItemCopyMatching(keyAttr as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw AppIDError.generalError
        }
        
        return result as! SecKey
        
    }
    
    
    internal static func getItemFromKeyChain(_ label:String) ->  String? {
        let query: [NSString: AnyObject] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: label as AnyObject,
            kSecReturnData: kCFBooleanTrue
        ]
        var results: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &results)
        if status == errSecSuccess {
            let data = results as! Data
            let password = String(data: data, encoding: String.Encoding.utf8)!
            
            return password
        }
        
        return nil
    }
    
    
    public static func getJWKSHeader() throws ->[String:Any] {
        
        let publicKey = try? SecurityUtils.getKeyBitsFromKeyChain(AppIDConstants.publicKeyIdentifier)
    
        
        guard let unWrappedPublicKey = publicKey, let pkModulus : Data = getPublicKeyMod(unWrappedPublicKey), let pkExponent : Data = getPublicKeyExp(unWrappedPublicKey) else {
            throw AppIDError.generalError
        }
        
        let mod:String = Utils.base64StringFromData(pkModulus, isSafeUrl: true)
        
        let exp:String = Utils.base64StringFromData(pkExponent, isSafeUrl: true)
        
        let publicKeyJSON : [String:Any] = [
            "e" : exp as AnyObject,
            "n" : mod as AnyObject,
            "kty" : AppIDConstants.JSON_RSA_VALUE
        ]
        
        return publicKeyJSON

    }
    
    private static func getPublicKeyMod(_ publicKeyBits: Data) -> Data? {
        var iterator : Int = 0
        iterator += 1 // TYPE - bit stream - mod + exp
        _ = derEncodingGetSizeFrom(publicKeyBits, at:&iterator) // Total size
        
        iterator += 1 // TYPE - bit stream mod
        let mod_size : Int = derEncodingGetSizeFrom(publicKeyBits, at:&iterator)
        if(mod_size == -1) {
            return nil
        }
        return publicKeyBits.subdata(in: NSMakeRange(iterator, mod_size).toRange()!)
    }
    
    //Return public key exponent
    private static func getPublicKeyExp(_ publicKeyBits: Data) -> Data? {
        var iterator : Int = 0
        iterator += 1 // TYPE - bit stream - mod + exp
        _ = derEncodingGetSizeFrom(publicKeyBits, at:&iterator) // Total size
        
        iterator += 1// TYPE - bit stream mod
        let mod_size : Int = derEncodingGetSizeFrom(publicKeyBits, at:&iterator)
        iterator += mod_size
        
        iterator += 1 // TYPE - bit stream exp
        let exp_size : Int = derEncodingGetSizeFrom(publicKeyBits, at:&iterator)
        //Ensure we got an exponent size
        if(exp_size == -1) {
            return nil
        }
        return publicKeyBits.subdata(in: NSMakeRange(iterator, exp_size).toRange()!)
    }
    
    private static func derEncodingGetSizeFrom(_ buf : Data, at iterator: inout Int) -> Int{
        
        // Have to cast the pointer to the right size
        //let pointer = UnsafePointer<UInt8>((buf as NSData).bytes)
        //let count = buf.count
        
        // Get our buffer pointer and make an array out of it
        //let buffer = UnsafeBufferPointer<UInt8>(start:pointer, count:count)
        let data = buf//[UInt8](buffer)
        
        var itr : Int = iterator
        var num_bytes :UInt8 = 1
        var ret : Int = 0
        if (data[itr] > 0x80) {
            num_bytes  = data[itr] - 0x80
            itr += 1
        }
        
        for i in 0 ..< Int(num_bytes) {
            ret = (ret * 0x100) + Int(data[itr + i])
        }
        
        iterator = itr + Int(num_bytes)
        
        return ret
    }
    
    
    internal static func signString(_ payloadString:String, keyIds ids:(publicKey: String, privateKey: String), keySize: Int) throws -> String {
        do {
            let privateKeySec = try getKeyRefFromKeyChain(ids.privateKey)
            
            guard let payloadData : Data = payloadString.data(using: String.Encoding.utf8) else {
                throw AppIDError.generalError
            }
            let signedData = try signData(payloadData, privateKey:privateKeySec)
            
            //return signedData.base64EncodedString()
            return Utils.base64StringFromData(signedData, isSafeUrl: true)
        }
        catch {
            throw AppIDError.generalError
        }
    }
    
    
    private static func signData(_ data:Data, privateKey:SecKey) throws -> Data {
        func doSha256(_ dataIn:Data) throws -> Data {
            var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
            dataIn.withUnsafeBytes {
                _ = CC_SHA256($0, CC_LONG(dataIn.count), &hash)
            }
            return Data(bytes: hash)
        }
        
        guard let digest:Data = try? doSha256(data), let signedData: NSMutableData = NSMutableData(length: SecKeyGetBlockSize(privateKey))  else {
            throw AppIDError.generalError
        }
        
        var signedDataLength: Int = signedData.length
        
        let digestBytes: UnsafePointer<UInt8> = ((digest as NSData).bytes).bindMemory(to: UInt8.self, capacity: digest.count)
        let digestlen = digest.count
        let mutableBytes: UnsafeMutablePointer<UInt8> = signedData.mutableBytes.assumingMemoryBound(to: UInt8.self)
        
        let signStatus:OSStatus = SecKeyRawSign(privateKey, SecPadding.PKCS1SHA256, digestBytes, digestlen,
                                                mutableBytes, &signedDataLength)
        
        guard signStatus == errSecSuccess else {
            throw AppIDError.generalError
        }
        
        return signedData as Data
    }
    
    internal static func saveItemToKeyChain(_ data:String, label: String) -> Bool{
        guard let stringData = data.data(using: String.Encoding.utf8) else {
            return false
        }
        let key: [NSString: AnyObject] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: label as AnyObject,
            kSecValueData: stringData as AnyObject
        ]
        var status = SecItemAdd(key as CFDictionary, nil)
        if(status != errSecSuccess){
            if(SecurityUtils.removeItemFromKeyChain(label) == true) {
                status = SecItemAdd(key as CFDictionary, nil)
            }
        }
        return status == errSecSuccess
    }
    
    internal static func removeItemFromKeyChain(_ label: String) -> Bool{
        
        let delQuery : [NSString:AnyObject] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: label as AnyObject
        ]
        
        let delStatus:OSStatus = SecItemDelete(delQuery as CFDictionary)
        return delStatus == errSecSuccess
        
    }
    
    internal static func deleteKeyFromKeyChain(_ tag:String) -> Bool{
        let delQuery : [NSString:AnyObject] = [
            kSecClass  : kSecClassKey,
            kSecAttrApplicationTag : tag as AnyObject
        ]
        let delStatus:OSStatus = SecItemDelete(delQuery as CFDictionary)
        return delStatus == errSecSuccess
    }
}
