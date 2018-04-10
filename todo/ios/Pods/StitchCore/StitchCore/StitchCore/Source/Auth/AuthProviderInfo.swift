import Foundation
import ExtendedJson

public protocol AuthProviderType: Codable {
    var name: String { get }
    var type: String { get }
}

public struct AnonymousAuthProviderInfo: AuthProviderType {
    public let name: String
    public let type: String
}
public struct EmailPasswordAuthProviderInfo: AuthProviderType {
    public struct Config: Codable {
        public let emailConfirmationUrl: String
        public let resetPasswordUrl: String
    }

    public let config: Config
    public let name: String
    public let type: String
}
public struct ApiKeyAuthProviderInfo: AuthProviderType {
    public let name: String
    public let type: String
}
public struct GoogleAuthProviderInfo: AuthProviderType {
    public struct Config: Codable {
        public let clientId: String
    }
    public struct MetadataField: Codable {
        public let name: String
        public let required: Bool
    }

    public let config: Config
    public let metadataFields: [MetadataField]?

    public let name: String
    public let type: String

    enum CodingKeys: String, CodingKey {
        case metadataFields = "metadata_fields", name, type, config
    }
}
public struct FacebookAuthProviderInfo: AuthProviderType {
    public struct Config: Codable {
        public let clientId: String
    }
    public struct MetadataField: Codable {
        public let name: String
        public let required: Bool
    }

    public let config: Config
    public let metadataFields: [MetadataField]?
    public let name: String
    public let type: String

    enum CodingKeys: String, CodingKey {
        case name, type, config, metadataFields = "metadata_fields"
    }
}
public struct CustomAuthProviderInfo: AuthProviderType {
    public struct Config: Codable {
        public let clientId: String
    }
    public struct MetadataField: Codable {
        public let name: String
        public let required: Bool
    }

    public let config: Config?
    public let metadataFields: [MetadataField]?
    public let name: String
    public let type: String

    enum CodingKeys: String, CodingKey {
        case name, type, config, metadataFields = "metadata_fields"
    }
}

public enum AuthProviderTypes: String, Codable {
    case google = "oauth2-google"
    case facebook = "oauth2-facebook"
    case apiKey = "api-key"
    case emailPass = "local-userpass"
    case anonymous = "anon-user"
    case custom = "custom-token"
}

/// Struct containing information about available providers
public struct AuthProviderInfo {
    /// Info about the `AnonymousAuthProvider`
    public private(set) var anonymousAuthProviderInfo: AnonymousAuthProviderInfo?
    /// Info about the `GoogleAuthProvider`
    public private(set) var googleProviderInfo: GoogleAuthProviderInfo?
    /// Info about the `FacebookAuthProvider`
    public private(set) var facebookProviderInfo: FacebookAuthProviderInfo?
    /// Info about the `EmailPasswordAuthProvider`
    public private(set) var emailPasswordAuthProviderInfo: EmailPasswordAuthProviderInfo?
    /// Info about the `ApiKeyAuthProvider`
    public private(set) var apiKeyAuthProviderInfo: ApiKeyAuthProviderInfo?
    /// Info for any custom auth providers
    public private(set) var customAuthProviderInfos = [CustomAuthProviderInfo]()

    public init(from infos: [[String: Any]]) throws {
        try infos.forEach { info in
            guard let type = info["type"] as? String,
                let providerType = AuthProviderTypes.init(rawValue: type) else {
                return
            }

            let data = try JSONSerialization.data(withJSONObject: info)
            switch providerType {
            case .google: googleProviderInfo =
                try JSONDecoder().decode(GoogleAuthProviderInfo.self, from: data)
            case .facebook: facebookProviderInfo =
                try JSONDecoder().decode(FacebookAuthProviderInfo.self, from: data)
            case .apiKey: apiKeyAuthProviderInfo =
                try JSONDecoder().decode(ApiKeyAuthProviderInfo.self, from: data)
            case .emailPass: emailPasswordAuthProviderInfo =
                try JSONDecoder().decode(EmailPasswordAuthProviderInfo.self, from: data)
            case .anonymous: anonymousAuthProviderInfo =
                try JSONDecoder().decode(AnonymousAuthProviderInfo.self, from: data)
            case .custom:
                customAuthProviderInfos.append(
                    try JSONDecoder().decode(CustomAuthProviderInfo.self, from: data))
            }
        }
    }
}
