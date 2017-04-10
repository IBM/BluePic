import Foundation

internal class AccessTokenImpl: AbstractToken, AccessToken {
	private static let SCOPE = "scope"

	var scope: String? {
		return payload[AccessTokenImpl.SCOPE] as? String
	}
}
