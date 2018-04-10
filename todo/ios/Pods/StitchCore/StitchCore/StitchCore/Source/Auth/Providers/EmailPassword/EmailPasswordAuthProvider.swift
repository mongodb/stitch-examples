import Foundation
import ExtendedJson

/// EmailPasswordAuthProvider provides a way to authenticate using an email and password.
public struct EmailPasswordAuthProvider: AuthProvider {
    /// The authentication type for email/pass login.
    public var type: AuthProviderTypes = AuthProviderTypes.emailPass

    /// The JSON payload containing the username and password.
    public var payload: Document {
        return ["username": username,
                "password": password]
    }

    private(set) var username: String
    private(set) var password: String

    // MARK: - Init
    /**
         Create a new provider object using an email and password.
         Can be used for login or registration.
     
         - Parameters:
             - username: Username or email to login with
             - password: password to login with
     */
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}
