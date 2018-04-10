import Foundation
import ExtendedJson

/**
    An AuthProvider is responsible for providing the necessary information for a specific
    authentication request.
 */
public protocol AuthProvider {
    /// The authentication type of this provider.
    var type: AuthProviderTypes {get}

    /// The JSON payload containing authentication material.
    var payload: Document {get}
}

/// Provider enum representing current state of `AuthProvider`s.
public enum Provider {
    /// Google OAuth2 repr
    case google,
    /// Facebook OAuth2 repr
         facebook,
    /// Email and password authentication
         emailPassword,
    /// Anonymous Authentication
         anonymous

    var type: String {
        switch self {
        case .google:
            return "oauth2/google"
        case .facebook:
            return "oauth2/facebook"
        case .emailPassword:
            return "local/userpass"
        case .anonymous:
            return "anon/user"
        }
    }

    init?(type: String) {
        switch type {
        case Provider.google.type:
            self = .google
        case Provider.facebook.type:
            self = .facebook
        case Provider.emailPassword.type:
            self = .emailPassword
        case Provider.anonymous.type:
            self = .anonymous
        default:
            return nil
        }
    }
}
