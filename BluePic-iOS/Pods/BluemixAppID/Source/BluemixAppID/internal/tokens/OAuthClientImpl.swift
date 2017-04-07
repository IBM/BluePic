import Foundation

internal class OAuthClientImpl: OAuthClient {

	private static let OAUTH_CLIENT = "oauth_client"
	private static let TYPE = "type"
	private static let NAME = "name"
	private static let SOFTWARE_ID = "software_id"
	private static let SOFTWARE_VERSION = "software_version"
	private static let DEVICE_ID = "device_id"
	private static let DEVICE_MODEL = "device_model"
	private static let DEVICE_OS = "device_os"
	
	internal var oauthClient: Dictionary<String, Any>?
	
	internal init?(with identityToken: IdentityToken) {
		self.oauthClient = identityToken.payload[OAuthClientImpl.OAUTH_CLIENT] as? Dictionary<String, Any>
	}
	
	var type: String? {
		return oauthClient?[OAuthClientImpl.TYPE] as? String
	}
	
	var name: String? {
		return oauthClient?[OAuthClientImpl.NAME] as? String
	}
	
	var softwareId: String? {
		return oauthClient?[OAuthClientImpl.SOFTWARE_ID] as? String
	}

	var softwareVersion: String? {
		return oauthClient?[OAuthClientImpl.SOFTWARE_VERSION] as? String
	}

	var deviceId: String? {
		return oauthClient?[OAuthClientImpl.DEVICE_ID] as? String
	}

	var deviceModel: String? {
		return oauthClient?[OAuthClientImpl.DEVICE_MODEL] as? String
	}

	var deviceOS: String? {
		return oauthClient?[OAuthClientImpl.DEVICE_OS] as? String
	}
}
