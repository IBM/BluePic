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
import BMSAnalyticsAPI

internal class AppIDConstants {
    
    
    
    
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
    
    internal static let base64DecodingTableUrlSafe: [Int8] = [
        -2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -1, -2, -1, -1, -2, -2,
        -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
        -1, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 62, -2, -2,
        52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -2, -2, -2, -2, -2, -2,
        -2,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
        15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -2, -2, -2, -2, 63,
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

    
   
    
    internal static let nameAndVer = Utils.getApplicationDetails()
    
    internal static var AppIDRequestManagerLoggerName = Logger.bmsLoggerPrefix + "AppIDRequestManager"
    internal static var RegistrationManagerLoggerName = Logger.bmsLoggerPrefix + "AppIDRegistrationManager"
    internal static var UserAttributeManagerLoggerName = Logger.bmsLoggerPrefix + "AppIDUserManagerManager"
    internal static var TokenManagerLoggerName = Logger.bmsLoggerPrefix + "AppIDTokenManager"
     internal static var AuthorizationManagerLoggerName = Logger.bmsLoggerPrefix + "AppIDAuthorizationManager"
    internal static var AppIDLoggerName = Logger.bmsLoggerPrefix + "AppID"
    internal static var ConfigLoggerName = Logger.bmsLoggerPrefix + "Config"

    internal static var tokenEndPoint = "token"
    internal static var clientsEndPoint = "clients"
    
    internal static var REDIRECT_URI_VALUE = Utils.getApplicationDetails().name + "://mobile/callback"
    internal static var authorizationEndPoint = "authorization"
    internal static var client_id_String = "client_id"
    
    internal static var authorization_code_String = "authorization_code"
    internal static var resource_owner_password_String = "password"
    internal static var JSON_RSA_VALUE = "RSA"
    internal static var JSON_RS256_VALUE = "RS256"
    internal static var JSON_ALG_KEY = "alg"
    internal static var JSON_MOD_KEY = "mod"
    internal static var JSON_EXP_KEY = "exp"
    internal static var JSON_JPK_KEY = "jpk"
    
    
    internal static var JSON_RESPONSE_TYPE_KEY = "response_type"
    internal static var JSON_IMF_USER_KEY = "imf.user"
    internal static var JSON_REDIRECT_URI_KEY = "redirect_uri"
    internal static var JSON_CODE_KEY = "code"
    internal static var JSON_SIGN_UP_KEY = "sign_up"
    internal static var JSON_GRANT_TYPE_KEY = "grant_type"
    internal static var JSON_USERNAME = "username"
    internal static var JSON_PASSWORD = "password"
    internal static var APPID_ACCESS_TOKEN = "appid_access_token"
    
    internal static let MFP_SECURITY_PACKAGE = Logger.bmsLoggerPrefix + "security"
    
    internal static let BEARER = "Bearer"
    internal static let AUTHORIZATION_HEADER = "Authorization"
    internal static let BASIC_AUTHORIZATION_STRING = "Basic"
    internal static let WWW_AUTHENTICATE_HEADER = "WWW-Authenticate"
    internal static let AUTH_REALM = "\"appid_default\""
    /**
     * Parts of the path to authorization endpoint.
     */
    internal static let AUTH_SERVER_NAME = "imf-authserver"
    internal static let V3_AUTH_PATH = "oauth/v3/"
    internal static let OAUTH_AUTHORIZATION_PATH = "/authorization"
    
    
    /**
     * Name of the standard "www-authenticate" header.
     */
    
    internal static var FACEBOOK_COOKIE_NAME =  "c_user"
    

    
    //JSON keys and values
    internal static let JSON_KEYS_KEY = "keys"
    internal static let JSON_JWKS_KEY = "jwks"
    internal static let JSON_DEVICE_ID_KEY = "device_id"
    internal static let JSON_OS_KEY = "device_os"
    internal static let JSON_ENVIRONMENT_KEY = "environment"
    internal static let JSON_MODEL_KEY = "device_model"
    internal static let JSON_SOFTWARE_ID_KEY = "software_id"
    internal static let JSON_SOFTWARE_VERSION_KEY = "software_version"
    internal static let JSON_REDIRECT_URIS_KEY = "redirect_uris"
    internal static let JSON_TOKEN_ENDPOINT_AUTH_METHOD_KEY = "token_endpoint_auth_method"
    internal static let JSON_RESPONSE_TYPES_KEY = "response_types"
    internal static let JSON_GRANT_TYPES_KEY = "grant_types"
    internal static let JSON_CLIENT_NAME_KEY = "client_name"
    internal static let JSON_CLIENT_TYPE_KEY = "client_type"
    internal static let MOBILE_APP_TYPE = "mobileapp"
    internal static let CLIENT_SECRET_BASIC = "client_secret_basic"
    internal static let PASSWORD_STRING = "password"


    
    internal static let tenantPrefName = "com.ibm.bluemix.appid.swift.tenantid"
    internal static let registrationDataPref = "com.ibm.bluemix.appid.swift.REGISTRATION_DATA"
    
    
    internal static let JSON_IOS_ENVIRONMENT_VALUE = "iOSnative"
    internal static let JSON_ACCESS_TOKEN_KEY = "access_token"
    internal static let JSON_ID_TOKEN_KEY = "id_token"
    internal static var JSON_SCOPE_KEY = "scope"
    internal static var JSON_USE_LOGIN_WIDGET = "use_login_widget"
    internal static var JSON_STATE_KEY = "state"
    internal static var OPEN_ID_VALUE = "openid"
    internal static var TRUE_VALUE = "true"
    
    // label names
    internal static let KEY_CHAIN_PREFIX = "com.ibm.mobilefirstplatform.clientsdk.swift.bmssecurity"
    internal static let OAUTH_CERT_LABEL = "\(KEY_CHAIN_PREFIX).certificate"
    internal static let _PUBLIC_KEY_LABEL = "\(KEY_CHAIN_PREFIX).publickey"
    internal static let CLIENT_ID_KEY_LABEL = "\(KEY_CHAIN_PREFIX).clientid"
    internal static let TENANT_ID_KEY_LABEL = "\(KEY_CHAIN_PREFIX).tenantId"
    internal static let _PRIVATE_KEY_LABEL = "\(KEY_CHAIN_PREFIX).privatekey"
    internal static let OAUTH_ACCESS_TOKEN_LABEL = "\(KEY_CHAIN_PREFIX).accesstoken"
    internal static let OAUTH_ID_TOKEN_LABEL = "\(KEY_CHAIN_PREFIX).idtoken"
    internal static let PERSISTENCE_POLICY_LABEL = "persistencePolicy"
    internal static let APP_IDENTITY_LABEL = "appIdentity"
    internal static let DEVICE_IDENTITY_LABEL = "deviceIdentity"
    internal static let USER_IDENTITY_LABEL = "userIdentity"
    // labels
    
    internal static let AnonymousIdpName = "appid_anon"
    internal static let BMSSecurityErrorDomain = "com.ibm.mobilefirstplatform.clientsdk.swift.bmssecurity"
    internal static let privateKeyIdentifier = "\(_PRIVATE_KEY_LABEL):\(nameAndVer.name):\(nameAndVer.version)"
    internal static let publicKeyIdentifier = "\(_PUBLIC_KEY_LABEL):\(nameAndVer.name):\(nameAndVer.version)"
    internal static let idTokenLabel = "\(OAUTH_ID_TOKEN_LABEL):\(nameAndVer.name):\(nameAndVer.version)"
    internal static let accessTokenLabel = "\(OAUTH_ACCESS_TOKEN_LABEL):\(nameAndVer.name):\(nameAndVer.version)"
    internal static let clientIdLabel = "\(CLIENT_ID_KEY_LABEL):\(nameAndVer.name):\(nameAndVer.version)"
    internal static let tenantIdLabel = "\(TENANT_ID_KEY_LABEL):\(nameAndVer.name):\(nameAndVer.version)"
    internal static let certificateIdentifier = "\(OAUTH_CERT_LABEL):\(nameAndVer.name):\(nameAndVer.version)"
    internal static let AuthorizationKeyChainTagsDictionary = [privateKeyIdentifier : kSecClassKey, publicKeyIdentifier : kSecClassKey, idTokenLabel : kSecClassGenericPassword, accessTokenLabel : kSecClassGenericPassword, certificateIdentifier : kSecClassCertificate]
    
}



