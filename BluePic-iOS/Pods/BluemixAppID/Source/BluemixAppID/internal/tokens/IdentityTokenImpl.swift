import Foundation

internal class IdentityTokenImpl: AbstractToken, IdentityToken {

	private static let NAME = "name"
	private static let EMAIL = "email"
	private static let GENDER = "gender"
	private static let LOCALE = "locale"
	private static let PICTURE = "picture"
	private static let IDENTITIES = "identities"

	var name: String? {
		return payload[IdentityTokenImpl.NAME] as? String
	}
	
	var email: String? {
		return payload[IdentityTokenImpl.EMAIL] as? String
	}
	
	var gender: String? {
		return payload[IdentityTokenImpl.GENDER] as? String
	}
	
	var locale: String? {
		return payload[IdentityTokenImpl.LOCALE] as? String
	}
	
	var picture: String? {
		return payload[IdentityTokenImpl.PICTURE] as? String
	}
	
	var identities: Array<Dictionary<String, Any>>? {
        return payload[IdentityTokenImpl.IDENTITIES] as? Array<Dictionary<String, Any>>
	}
	
	var oauthClient: OAuthClient? {
		return OAuthClientImpl(with: self)
	}
}
