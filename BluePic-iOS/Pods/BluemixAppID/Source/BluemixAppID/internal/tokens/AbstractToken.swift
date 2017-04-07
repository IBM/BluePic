import Foundation

public protocol Token {

	var raw: String {get}
	var header: Dictionary<String, Any> {get}
	var payload: Dictionary<String, Any> {get}
	var signature: String {get}
	
	var issuer: String? {get}
	var subject: String? {get}
	var audience: String? {get}
	var expiration: Date? {get}
	var issuedAt: Date? {get}
	var tenant: String? {get}
    var authenticationMethods: [String]? {get}
	var isExpired: Bool {get}
    var isAnonymous: Bool {get}
}

internal class AbstractToken: Token {
	
	private static let ISSUER = "iss"
	private static let SUBJECT = "sub"
	private static let AUDIENCE = "aud"
	private static let EXPIRATION = "exp"
	private static let ISSUED_AT = "iat"
	private static let TENANT = "tenant"
	private static let AUTH_METHODS = "amr"

	var raw: String
	var header: Dictionary<String, Any>
	var payload: Dictionary<String, Any>
	var signature: String
	
	internal init? (with raw: String) {
		self.raw = raw
		let tokenComponents = self.raw.components(separatedBy: ".")
		guard tokenComponents.count==3 else {
			return nil
		}
		
		let headerComponent = tokenComponents[0]
		let payloadComponent = tokenComponents[1]
		self.signature = tokenComponents[2]

		guard
			let headerDecodedData = Utils.decodeBase64WithString(headerComponent, isSafeUrl: true),
			let payloadDecodedData = Utils.decodeBase64WithString(payloadComponent, isSafeUrl: true)
			else {
				return nil
		}
		
		guard
			let headerDecodedString = String(data: headerDecodedData, encoding: String.Encoding.utf8),
			let payloadDecodedString = String(data: payloadDecodedData, encoding: String.Encoding.utf8)
			else {
				return nil
		}
		
		guard
			let headerDictionary = try? Utils.parseJsonStringtoDictionary(headerDecodedString),
			let payloadDictionary = try? Utils.parseJsonStringtoDictionary(payloadDecodedString)
			else {
				return nil
		}
		
		self.header = headerDictionary
		self.payload = payloadDictionary
	}
	
	var issuer: String? {
		return payload[AbstractToken.ISSUER] as? String
	}

	var subject: String? {
		return payload[AbstractToken.SUBJECT] as? String
	}
	
	var audience: String? {
		return payload[AbstractToken.AUDIENCE] as? String
	}
	
    var expiration: Date? {
        guard let exp = payload[AbstractToken.EXPIRATION] as? Double else {
            return nil
        }
        return Date(timeIntervalSince1970: exp)
    }
    
    var issuedAt: Date? {
        guard let iat = payload[AbstractToken.ISSUED_AT] as? Double else {
            return nil
        }
        return Date(timeIntervalSince1970: iat)
    }
	var tenant: String? {
		return payload[AbstractToken.TENANT] as? String
	}
	
    var authenticationMethods: [String]? {
        return payload[AbstractToken.AUTH_METHODS] as? [String]
    }
	
    var isExpired: Bool {
        guard let exp = self.expiration else {
            return true
        }
        return exp < Date()
    }
    
    var isAnonymous: Bool {
        // TODO: complete this
        guard let amr = payload[AbstractToken.AUTH_METHODS] as? Array<String> else {
            return false
        }
        return amr.contains("appid_anon")
    }
	
}
