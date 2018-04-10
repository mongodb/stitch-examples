import Foundation
import ExtendedJson

/// GoogleAuthProvider provides a way to authenticate via Google's OAuth 2.0 provider.
public struct GoogleAuthProvider: AuthProvider {
    /// The authentication type for google login.
    public var type: AuthProviderTypes = AuthProviderTypes.google

    /// The JSON payload containing the authCode.
    public var payload: Document {
        return ["authCode": authCode]
    }

    private(set) var authCode: String

    // MARK: - Init
    /**
         - parameter authCode: Authorization code needed for login
     */
    public init(authCode: String) {
        self.authCode = authCode
    }
}
