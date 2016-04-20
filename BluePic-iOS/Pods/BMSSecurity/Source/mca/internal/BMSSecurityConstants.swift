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
import BMSAnalyticsAPI

internal class BMSSecurityConstants {
    
    
    
    internal static let SECURE_PATTERN_START = "/*-secure-\n"
    internal static let SECURE_PATTERN_END = "*/"
    
    internal static let  base64EncodingTable:[Character] = [
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P",
        "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f",
        "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v",
        "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "+", "/"
    ]
    
    internal static let base64EncodingTableUrlSafe:[Character] = [
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P",
        "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f",
        "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v",
        "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "-", "_"
    ]
    
    
    internal static let base64DecodingTable: [Int8] = [
        -2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -1, -2, -1, -1, -2, -2,
        -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
        -1, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 62, -2, -2, -2, 63,
        52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -2, -2, -2, -2, -2, -2,
        -2,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
        15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -2, -2, -2, -2, -2,
        -2, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
        41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -2, -2, -2, -2, -2,
        -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
        -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
        -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
        -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
        -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
        -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
        -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
        -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2
    ]
    
    
    internal static var deviceInfo = Utils.getDeviceDictionary()
    internal static let nameAndVer = Utils.getApplicationDetails()
    internal static var authorizationProcessManagerLoggerName = Logger.bmsLoggerPrefix + "AuthorizationProcessManager"
    internal static var authorizationRequestManagerLoggerName = Logger.bmsLoggerPrefix + "AuthorizationRequestManager"
    
    internal static var authorizationEndPoint = "authorization"
    internal static var tokenEndPoint = "token"
    internal static var clientsInstanceEndPoint = "clients/instance"
    
    
    internal static var client_id_String = "client_id"
    
    internal static var authorization_code_String = "authorization_code"
    internal static var JSON_RSA_VALUE = "RSA"
    internal static var JSON_RS256_VALUE = "RS256"
    internal static var JSON_ALG_KEY = "alg"
    internal static var JSON_MOD_KEY = "mod"
    internal static var JSON_EXP_KEY = "exp"
    internal static var JSON_JPK_KEY = "jpk"
    
    internal static var X_WL_SESSION_HEADER_NAME = "X-WL-Session"
    internal static var X_WL_AUTHENTICATE_HEADER_NAME = "X-WL-Authenticate"
    
    internal static var JSON_RESPONSE_TYPE_KEY = "response_type"
    internal static var JSON_CSR_KEY = "CSR"
    internal static var JSON_IMF_USER_KEY = "imf.user"
    internal static var JSON_REDIRECT_URI_KEY = "redirect_uri"
    internal static var JSON_CODE_KEY = "code"
    internal static var JSON_GRANT_TYPE_KEY = "grant_type"
    
    internal static let MFP_SECURITY_PACKAGE = Logger.bmsLoggerPrefix + "security"
    
    internal static let BEARER = "Bearer"
    internal static let AUTHORIZATION_HEADER = "Authorization"
    internal static let WWW_AUTHENTICATE_HEADER = "WWW-Authenticate"
    
    internal static let HTTP_LOCALHOST = "http://localhost"
    /**
     * Parts of the path to authorization endpoint.
     */
    internal static let AUTH_SERVER_NAME = "imf-authserver"
    internal static let AUTH_PATH = "authorization/v1/apps/"
    
    /**
     * The name of "result" parameter returned from authorization endpoint.
     */
    internal static let WL_RESULT = "wl_result";
    
    /**
     * Name of location header.
     */
    internal static let LOCATION_HEADER_NAME = "Location"
    
    /**
     * Name of the standard "www-authenticate" header.
     */
    internal static let AUTHENTICATE_HEADER_NAME = "WWW-Authenticate"
    
    /**
     * Name of "www-authenticate" header value.
     */
    internal static let AUTHENTICATE_HEADER_VALUE = "WL-Composite-Challenge"
    
    /**
     * Names of JSON values returned from the server.
     */
    internal static let AUTH_FAILURE_VALUE_NAME = "WL-Authentication-Failure"
    internal static let AUTH_SUCCESS_VALUE_NAME = "WL-Authentication-Success"
    internal static let CHALLENGES_VALUE_NAME = "challenges"
    
    //JSON keys
    internal static let JSON_CERTIFICATE_KEY = "certificate"
    internal static let JSON_CLIENT_ID_KEY = "clientId"
    internal static let JSON_DEVICE_ID_KEY = "deviceId"
    internal static let JSON_OS_KEY = "deviceOs"
    internal static let JSON_ENVIRONMENT_KEY = "environment"
    internal static let JSON_MODEL_KEY = "deviceModel"
    internal static let JSON_APPLICATION_ID_KEY = "applicationId"
    internal static let JSON_APPLICATION_VERSION_KEY = "applicationVersion"
    internal static let JSON_IOS_ENVIRONMENT_VALUE = "iOSnative"
    internal static let JSON_ACCESS_TOKEN_KEY = "access_token"
    internal static let JSON_ID_TOKEN_KEY = "id_token"
    
    //label names
    internal static let KEY_CHAIN_PREFIX = "com.ibm.mobilefirstplatform.clientsdk.swift.bmssecurity"
    internal static let OAUTH_CERT_LABEL = "\(KEY_CHAIN_PREFIX).certificate"
    internal static let _PUBLIC_KEY_LABEL = "\(KEY_CHAIN_PREFIX).publickey"
    internal static let CLIENT_ID_KEY_LABEL = "\(KEY_CHAIN_PREFIX).clientid"
    internal static let _PRIVATE_KEY_LABEL = "\(KEY_CHAIN_PREFIX).privatekey"
    internal static let OAUTH_ACCESS_TOKEN_LABEL = "\(KEY_CHAIN_PREFIX).accesstoken"
    internal static let OAUTH_ID_TOKEN_LABEL = "\(KEY_CHAIN_PREFIX).idtoken"
    internal static let PERSISTENCE_POLICY_LABEL = "persistencePolicy"
    internal static let APP_IDENTITY_LABEL = "appIdentity"
    internal static let DEVICE_IDENTITY_LABEL = "deviceIdentity"
    internal static let USER_IDENTITY_LABEL = "userIdentity"
    //labels

    internal static let BMSSecurityErrorDomain = "com.ibm.mobilefirstplatform.clientsdk.swift.bmssecurity"
    internal static let privateKeyIdentifier = "\(_PRIVATE_KEY_LABEL):\(nameAndVer.name):\(nameAndVer.version)"
    internal static let publicKeyIdentifier = "\(_PUBLIC_KEY_LABEL):\(nameAndVer.name):\(nameAndVer.version)"
    internal static let idTokenLabel = "\(OAUTH_ID_TOKEN_LABEL):\(nameAndVer.name):\(nameAndVer.version)"
    internal static let accessTokenLabel = "\(OAUTH_ACCESS_TOKEN_LABEL):\(nameAndVer.name):\(nameAndVer.version)"
    internal static let clientIdLabel = "\(CLIENT_ID_KEY_LABEL):\(nameAndVer.name):\(nameAndVer.version)"
    internal static let certificateIdentifier = "\(OAUTH_CERT_LABEL):\(nameAndVer.name):\(nameAndVer.version)"
    internal static let AuthorizationKeyChainTagsDictionary = [privateKeyIdentifier : kSecClassKey, publicKeyIdentifier : kSecClassKey, idTokenLabel : kSecClassGenericPassword, accessTokenLabel : kSecClassGenericPassword, certificateIdentifier : kSecClassCertificate]

}



