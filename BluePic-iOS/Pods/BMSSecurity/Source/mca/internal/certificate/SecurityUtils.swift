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
import RNCryptor

internal class SecurityUtils {
    
    private static func savePublicKeyToKeyChain(key:SecKey,tag:String) throws {
        let publicKeyAttr : [NSString:AnyObject] = [
            kSecValueRef: key,
            kSecAttrIsPermanent : true,
            kSecAttrApplicationTag : tag,
            kSecAttrKeyClass : kSecAttrKeyClassPublic
            
        ]
        let addStatus:OSStatus = SecItemAdd(publicKeyAttr, nil)
        guard addStatus == errSecSuccess else {
            throw BMSSecurityError.generalError
        }
        
        
    }
    private static func getKeyBitsFromKeyChain(tag:String) throws -> NSData {
        let keyAttr : [NSString:AnyObject] = [
            kSecClass : kSecClassKey,
            kSecAttrApplicationTag: tag,
            kSecAttrKeyType : kSecAttrKeyTypeRSA,
            kSecReturnData : true
        ]
        var result: AnyObject?
        
        let status = SecItemCopyMatching(keyAttr, &result)
        
        guard status == errSecSuccess else {
            throw BMSSecurityError.generalError
        }
        return result as! NSData
        
    }
    
    internal static func generateKeyPair(keySize:Int, publicTag:String, privateTag:String)throws -> (publicKey: SecKey, privateKey: SecKey) {
        //make sure keys are deleted
        SecurityUtils.deleteKeyFromKeyChain(publicTag)
        SecurityUtils.deleteKeyFromKeyChain(privateTag)
        
        var status:OSStatus = noErr
        var privateKey:SecKey?
        var publicKey:SecKey?
        
        let privateKeyAttr : [NSString:AnyObject] = [
            kSecAttrIsPermanent : true,
            kSecAttrApplicationTag : privateTag,
            kSecAttrKeyClass : kSecAttrKeyClassPrivate
        ]
        
        let publicKeyAttr : [NSString:AnyObject] = [
            kSecAttrIsPermanent : true,
            kSecAttrApplicationTag : publicTag,
            kSecAttrKeyClass : kSecAttrKeyClassPublic,
        ]
        
        let keyPairAttr : [NSString:AnyObject] = [
            kSecAttrKeyType : kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits : keySize,
            kSecPublicKeyAttrs : publicKeyAttr,
            kSecPrivateKeyAttrs : privateKeyAttr
        ]
        
        status = SecKeyGeneratePair(keyPairAttr, &publicKey, &privateKey)
        if (status != errSecSuccess) {
            throw BMSSecurityError.generalError
        } else {
            return (publicKey!, privateKey!)
        }
    }
    
    private static func getKeyPairBitsFromKeyChain(publicTag:String, privateTag:String) throws -> (publicKey: NSData, privateKey: NSData) {
        return try (getKeyBitsFromKeyChain(publicTag),getKeyBitsFromKeyChain(privateTag))
    }
    
    private static func getKeyPairRefFromKeyChain(publicTag:String, privateTag:String) throws -> (publicKey: SecKey, privateKey: SecKey) {
        return try (getKeyRefFromKeyChain(publicTag),getKeyRefFromKeyChain(privateTag))
    }
    
    private static func getKeyRefFromKeyChain(tag:String) throws -> SecKey {
        let keyAttr : [NSString:AnyObject] = [
            kSecClass : kSecClassKey,
            kSecAttrApplicationTag: tag,
            kSecAttrKeyType : kSecAttrKeyTypeRSA,
            kSecReturnRef : kCFBooleanTrue
        ]
        var result: AnyObject?
        
        let status = SecItemCopyMatching(keyAttr, &result)
        
        guard status == errSecSuccess else {
            throw BMSSecurityError.generalError
        }
        
        return result as! SecKey
        
    }
    
    internal static func getCertificateFromKeyChain(certificateLabel:String) throws -> SecCertificate {
        let getQuery :  [NSString: AnyObject] = [
            kSecClass : kSecClassCertificate,
            kSecReturnRef : true,
            kSecAttrLabel : certificateLabel
        ]
        var result: AnyObject?
        let getStatus = SecItemCopyMatching(getQuery, &result)
        
        guard getStatus == errSecSuccess else {
            throw BMSSecurityError.generalError
        }
        
        return result as! SecCertificate
    }
    
    internal static func getItemFromKeyChain(label:String) ->  String? {
        let query: [NSString: AnyObject] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: label,
            kSecReturnData: kCFBooleanTrue
        ]
        var results: AnyObject?
        let status = SecItemCopyMatching(query, &results)
        if status == errSecSuccess {
            let data = results as! NSData
            let password = String(data: data, encoding: NSUTF8StringEncoding)!
            
            return password
        }
        
        return nil
    }
    
    internal static func signCsr(payloadJSON:[String : AnyObject], keyIds ids:(publicKey: String, privateKey: String), keySize: Int) throws -> String {
        do {
            let strPayloadJSON = try Utils.JSONStringify(payloadJSON)
            let keys = try getKeyPairBitsFromKeyChain(ids.publicKey, privateTag: ids.privateKey)
            let publicKey = keys.publicKey
            
            let privateKeySec = try getKeyPairRefFromKeyChain(ids.publicKey, privateTag: ids.privateKey).privateKey
            let strJwsHeaderJSON = try Utils.JSONStringify(getJWSHeaderForPublicKey(publicKey))
            guard let jwsHeaderData : NSData = strJwsHeaderJSON.dataUsingEncoding(NSUTF8StringEncoding), payloadJSONData : NSData = strPayloadJSON.dataUsingEncoding(NSUTF8StringEncoding) else {
                throw BMSSecurityError.generalError
            }
            
            let jwsHeaderBase64 = Utils.base64StringFromData(jwsHeaderData, isSafeUrl: true)
            let payloadJSONBase64 = Utils.base64StringFromData(payloadJSONData, isSafeUrl: true)
            
            let jwsHeaderAndPayload = jwsHeaderBase64.stringByAppendingString(".".stringByAppendingString(payloadJSONBase64))
            let signedData = try signData(jwsHeaderAndPayload, privateKey:privateKeySec)
            
            let signedDataBase64 = Utils.base64StringFromData(signedData, isSafeUrl: true)
            
            return jwsHeaderAndPayload.stringByAppendingString(".".stringByAppendingString(signedDataBase64))
        }
        catch {
            throw BMSSecurityError.generalError
        }
    }
    
    private static func getJWSHeaderForPublicKey(publicKey: NSData) throws ->[String:AnyObject]
    {
        let base64Options = NSDataBase64EncodingOptions(rawValue:0)
        
        guard let pkModulus : NSData = getPublicKeyMod(publicKey), let pkExponent : NSData = getPublicKeyExp(publicKey) else {
            throw BMSSecurityError.generalError
        }
        
        let mod:String = pkModulus.base64EncodedStringWithOptions(base64Options)
        
        let exp:String = pkExponent.base64EncodedStringWithOptions(base64Options)
        
        let publicKeyJSON : [String:AnyObject] = [
            BMSSecurityConstants.JSON_ALG_KEY : BMSSecurityConstants.JSON_RSA_VALUE,
            BMSSecurityConstants.JSON_MOD_KEY : mod,
            BMSSecurityConstants.JSON_EXP_KEY : exp
        ]
        let jwsHeaderJSON :[String:AnyObject] = [
            BMSSecurityConstants.JSON_ALG_KEY : BMSSecurityConstants.JSON_RS256_VALUE,
            BMSSecurityConstants.JSON_JPK_KEY : publicKeyJSON
        ]
        return jwsHeaderJSON
        
    }
    
    private static func getPublicKeyMod(publicKeyBits: NSData) -> NSData? {
        var iterator : Int = 0
        iterator++ // TYPE - bit stream - mod + exp
        derEncodingGetSizeFrom(publicKeyBits, at:&iterator) // Total size
        
        iterator++ // TYPE - bit stream mod
        let mod_size : Int = derEncodingGetSizeFrom(publicKeyBits, at:&iterator)
        if(mod_size == -1) {
            return nil
        }
        return publicKeyBits.subdataWithRange(NSMakeRange(iterator, mod_size))
    }
    
    //Return public key exponent
    private static func getPublicKeyExp(publicKeyBits: NSData) -> NSData? {
        var iterator : Int = 0
        iterator++ // TYPE - bit stream - mod + exp
        derEncodingGetSizeFrom(publicKeyBits, at:&iterator) // Total size
        
        iterator++// TYPE - bit stream mod
        let mod_size : Int = derEncodingGetSizeFrom(publicKeyBits, at:&iterator)
        iterator += mod_size
        
        iterator++ // TYPE - bit stream exp
        let exp_size : Int = derEncodingGetSizeFrom(publicKeyBits, at:&iterator)
        //Ensure we got an exponent size
        if(exp_size == -1) {
            return nil
        }
        return publicKeyBits.subdataWithRange(NSMakeRange(iterator, exp_size))
    }
    
    private static func derEncodingGetSizeFrom(buf : NSData, inout at iterator: Int) -> Int{
        
        // Have to cast the pointer to the right size
        let pointer = UnsafePointer<UInt8>(buf.bytes)
        let count = buf.length
        
        // Get our buffer pointer and make an array out of it
        let buffer = UnsafeBufferPointer<UInt8>(start:pointer, count:count)
        let data = [UInt8](buffer)
        
        var itr : Int = iterator
        var num_bytes :UInt8 = 1
        var ret : Int = 0
        if (data[itr] > 0x80) {
            num_bytes  = data[itr] - 0x80
            itr++
        }
        
        for var i = 0; i < Int(num_bytes); i++ {
            ret = (ret * 0x100) + Int(data[itr + i])
        }
        
        iterator = itr + Int(num_bytes)
        
        return ret
    }
    
    private static func signData(payload:String, privateKey:SecKey) throws -> NSData {
        guard let data:NSData = payload.dataUsingEncoding(NSUTF8StringEncoding) else {
            throw BMSSecurityError.generalError
        }
        
        func doSha256(dataIn:NSData) throws -> NSData {
            
            guard let shaOut: NSMutableData = NSMutableData(length: Int(CC_SHA256_DIGEST_LENGTH)) else {
                throw BMSSecurityError.generalError
            }
            
            CC_SHA256(dataIn.bytes, CC_LONG(dataIn.length), UnsafeMutablePointer<UInt8>(shaOut.mutableBytes))
            
            return shaOut
        }
        
        guard let digest:NSData = try? doSha256(data), signedData: NSMutableData = NSMutableData(length: SecKeyGetBlockSize(privateKey))  else {
            throw BMSSecurityError.generalError
        }
        
        var signedDataLength: Int = signedData.length
        
        let digestBytes = UnsafePointer<UInt8>(digest.bytes)
        let digestlen = digest.length
        
        let signStatus:OSStatus = SecKeyRawSign(privateKey, SecPadding.PKCS1SHA256, digestBytes, digestlen, UnsafeMutablePointer<UInt8>(signedData.mutableBytes),
            &signedDataLength)
        
        guard signStatus == errSecSuccess else {
            throw BMSSecurityError.generalError
        }
        
        return signedData
    }
    
    internal static func saveItemToKeyChain(data:String, label: String) -> Bool{
        guard let stringData = data.dataUsingEncoding(NSUTF8StringEncoding) else {
            return false
        }
        let key: [NSString: AnyObject] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: label,
            kSecValueData: stringData
        ]
        let status = SecItemAdd(key, nil)
        
        return status == errSecSuccess
        
    }
    internal static func removeItemFromKeyChain(label: String) -> Bool{
        
        let delQuery : [NSString:AnyObject] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: label
        ]
        
        let delStatus:OSStatus = SecItemDelete(delQuery)
        return delStatus == errSecSuccess
        
    }
    
    
    internal static func getCertificateFromString(stringData:String) throws -> SecCertificate{
        
        if let data:NSData = NSData(base64EncodedString: stringData, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)  {
            if let certificate = SecCertificateCreateWithData(kCFAllocatorDefault, data) {
                return certificate
            }
        }
        throw BMSSecurityError.generalError
    }
    
    internal static func deleteCertificateFromKeyChain(certificateLabel:String) -> Bool{
        let delQuery : [NSString:AnyObject] = [
            kSecClass: kSecClassCertificate,
            kSecAttrLabel: certificateLabel
        ]
        let delStatus:OSStatus = SecItemDelete(delQuery)
        
        return delStatus == errSecSuccess
        
    }
    
    private static func deleteKeyFromKeyChain(tag:String) -> Bool{
        let delQuery : [NSString:AnyObject] = [
            kSecClass  : kSecClassKey,
            kSecAttrApplicationTag : tag
        ]
        let delStatus:OSStatus = SecItemDelete(delQuery)
        return delStatus == errSecSuccess
    }
    
    
    internal static func saveCertificateToKeyChain(certificate:SecCertificate, certificateLabel:String) throws {
        //make sure certificate is deleted
        deleteCertificateFromKeyChain(certificateLabel)
        //set certificate in key chain
        let setQuery: [NSString: AnyObject] = [
            kSecClass: kSecClassCertificate,
            kSecValueRef: certificate,
            kSecAttrLabel: certificateLabel,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        let addStatus:OSStatus = SecItemAdd(setQuery, nil)
        
        guard addStatus == errSecSuccess else {
            throw BMSSecurityError.generalError
        }
    }
    internal static func checkCertificatePublicKeyValidity(certificate:SecCertificate, publicKeyTag:String) throws -> Bool{
        
        let certificatePublicKeyTag = "checkCertificatePublicKeyValidity : publicKeyFromCertificate"
        var publicKeyBits = try getKeyBitsFromKeyChain(publicKeyTag)
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        var status = SecTrustCreateWithCertificates(certificate, policy, &trust)
        if let unWrappedTrust = trust where status == errSecSuccess {
            if let certificatePublicKey = SecTrustCopyPublicKey(unWrappedTrust)  {
                defer {
                    SecurityUtils.deleteKeyFromKeyChain(certificatePublicKeyTag)
                }
                try savePublicKeyToKeyChain(certificatePublicKey, tag: certificatePublicKeyTag)
                let ceritificatePublicKeyBits = try getKeyBitsFromKeyChain(certificatePublicKeyTag)
                
                if(ceritificatePublicKeyBits == publicKeyBits){
                    return true
                }
            }
        }
        throw BMSSecurityError.generalError
    }
    
    internal static func clearDictValuesFromKeyChain(dict : [String : NSString])  {
        for (tag, kSecClassName) in dict {
            if kSecClassName == kSecClassCertificate {
                deleteCertificateFromKeyChain(tag)
            } else if kSecClassName == kSecClassKey {
                deleteKeyFromKeyChain(tag)
            } else if kSecClassName == kSecClassGenericPassword {
                removeItemFromKeyChain(tag)
            }
        }
    }
}