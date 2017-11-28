import Foundation

import ExtendedJson
import StitchLogger
import Security

public struct Consts {
    public static let DefaultBaseUrl =   "https://stitch.mongodb.com"
    static let ApiPath =                 "/api/client/v2.0/"

    //User Defaults
    static let UserDefaultsName =        "com.mongodb.stitch.sdk.UserDefaults"
    static let IsLoggedInUDKey =         "StitchCoreIsLoggedInUserDefaultsKey"

    //keychain
    static let AuthJwtKey =              "StitchCoreAuthJwtKey"
    static let AuthRefreshTokenKey =     "StitchCoreAuthRefreshTokenKey"
    static let AuthKeychainServiceName = "com.mongodb.stitch.sdk.authentication"

    //keys
    static let ErrorKey =                "error"
}

/// A StitchClient is responsible for handling the overall interaction with all Stitch services.
public class StitchClient: StitchClientType {
    // MARK: - Properties
    /// Id of the current application
    public var appId: String
    internal lazy var routes = Routes(appId: appId)
    internal var baseUrl: String
    internal let networkAdapter: NetworkAdapter

    internal let userDefaults = UserDefaults(suiteName: Consts.UserDefaultsName)

    internal lazy var httpClient = StitchHTTPClient(baseUrl: baseUrl,
                                                   appId: appId,
                                                   networkAdapter: networkAdapter)
    private var authProvider: AuthProvider?
    private var authDelegates = [AuthDelegate?]()

    private lazy var services = Services(client: self)
    public lazy var push = PushManager(client: self)

    internal struct Routes {
        private var appId: String

        lazy var authRoute = "app/\(appId)/auth"
        lazy var authProvidersExtensionRoute = "app/\(appId)/auth/providers"
        lazy var authProfileRoute = "auth/profile"
        lazy var authSessionRoute = "auth/session"
        mutating func authProvidersLoginRoute(provider: String) -> String {
            return "\(authProvidersExtensionRoute)/\(provider)/login"
        }

        lazy var localUserpassResetRoute = "\(authProvidersExtensionRoute)/local-userpass/reset"
        lazy var localUserpassResetSendRoute = "\(authProvidersExtensionRoute)/local-userpass/reset/send"
        lazy var localUserpassRegisterRoute = "\(authProvidersExtensionRoute)/local-userpass/register/"
        lazy var localUserpassConfirmRoute = "\(authProvidersExtensionRoute)/local-userpass/confirm"
        lazy var localUserpassConfirmSendRoute = "\(authProvidersExtensionRoute)/local-userpass/confirm/send"

        lazy var functionsCallRoute = "app/\(appId)/functions/call"

        lazy var pushProvidersRoute = "app/\(appId)/push/providers"
        mutating func pushProvidersRegistartionRoute(provider: String) -> String {
            return "\(pushProvidersRoute)/\(provider)/registration"
        }

        lazy var apiKeysRoute = "auth/api_keys"
        mutating func apiKeyRoute(id: String) -> String {
            return "\(apiKeysRoute)/\(id)"
        }
        mutating func apiKeyEnableRoute(id: String) -> String {
            return "\(apiKeysRoute)/\(id)/enable"
        }
        mutating func apiKeyDisableRoute(id: String) -> String {
            return "\(apiKeysRoute)/\(id)/disable"
        }

        init(appId: String) {
            self.appId = appId
        }
    }

    /// The currently authenticated user (if authenticated).
    public private(set) var auth: Auth? {
        didSet {
            if let refreshToken = httpClient.authInfo?.refreshToken {
                // save auth persistently
                userDefaults?.set(true, forKey: Consts.IsLoggedInUDKey)

                do {
                    let jsonData = try JSONEncoder().encode(httpClient.authInfo)
                    guard let jsonString = String(data: jsonData,
                                                  encoding: .utf8) else {
                        printLog(.error, text: "Error converting json String to Data")
                        return
                    }

                    self.httpClient.save(token: refreshToken, withKey: Consts.AuthRefreshTokenKey)
                    self.httpClient.save(token: jsonString, withKey: Consts.AuthJwtKey)
                } catch let error as NSError {
                    printLog(.error,
                             text: "failed saving auth to keychain, array to JSON conversion failed: " +
                                error.localizedDescription)
                }
            } else {
                // remove from keychain
                try? self.httpClient.deleteToken(withKey: Consts.AuthJwtKey)
                userDefaults?.set(false, forKey: Consts.IsLoggedInUDKey)
            }
        }
    }

    /// Whether or not the client is currently authenticated
    public var isAuthenticated: Bool {
        return self.httpClient.isAuthenticated
    }

    // MARK: - Init
    /**
        Create a new object to interact with Stitch
        - Parameters: 
            - appId:  The App ID for the Stitch app.
            - baseUrl: The base URL of the Stitch Client API server.
            - networkAdapter: Optional interface if AlamoFire is not desired.
     */
    public init(appId: String,
                baseUrl: String = Consts.DefaultBaseUrl,
                networkAdapter: NetworkAdapter = StitchNetworkAdapter()) {
        self.appId = appId
        self.baseUrl = baseUrl
        self.networkAdapter = networkAdapter
    }

    // MARK: - Auth

    /**
     Fetches all available auth providers for the current app.
     
     - Returns: A task containing AuthProviderInfo that can be resolved
     on completion of the request.
     */
    @discardableResult
    public func fetchAuthProviders() -> StitchTask<AuthProviderInfo> {
        return httpClient.doRequest {
            $0.endpoint = self.routes.authProvidersExtensionRoute
            $0.isAuthenticatedRequest = false
        }.then { any in
            guard let json = any as? [[String: Any]] else {
                throw StitchError.responseParsingFailed(reason: "\(any) was not valid")
            }

            return try AuthProviderInfo(from: json)
        }
    }

    /**
     Registers the current user using email and password.
     
     - parameter email: email for the given user
     - parameter password: password for the given user
     - returns: A task containing whether or not registration was successful.
     */
    @discardableResult
    public func register(email: String, password: String) -> StitchTask<Void> {
        return httpClient.doRequest {
            $0.method = .post
            $0.endpoint = self.routes.localUserpassRegisterRoute
            $0.isAuthenticatedRequest = false
            $0.parameters = ["email": email, "password": password]
        }.then { _ in }
    }

    /**
     * Confirm a newly registered email in this context
     * - parameter token: confirmation token emailed to new user
     * - parameter tokenId: confirmation tokenId emailed to new user
     * - returns: A task containing whether or not the email was confirmed successfully
     */
    @discardableResult
    public func emailConfirm(token: String, tokenId: String) -> StitchTask<Void> {
        return httpClient.doRequest {
            $0.method = .post
            $0.endpoint = self.routes.localUserpassConfirmRoute
            $0.isAuthenticatedRequest = false
            $0.parameters = ["token": token, "tokenId": tokenId]
        }.then { _ in }
    }

    /**
     * Send a confirmation email for a newly registered user
     * - parameter email: email address of user
     * - returns: A task containing whether or not the email was sent successfully.
     */
    @discardableResult
    public func sendEmailConfirm(toEmail email: String) -> StitchTask<Void> {
        return httpClient.doRequest {
            $0.method = .post
            $0.endpoint = self.routes.localUserpassConfirmSendRoute
            $0.isAuthenticatedRequest = false
            $0.parameters = ["email": email]
        }.then { _ in }
    }

    /**
     * Reset a given user's password
     * - parameter token: token associated with this user
     * - parameter tokenId: id of the token associated with this user
     * - returns: A task containing whether or not the reset was successful
     */
    @discardableResult
    public func resetPassword(token: String, tokenId: String) -> StitchTask<Void> {
        return httpClient.doRequest {
            $0.method = .post
            $0.endpoint = self.routes.localUserpassResetRoute
            $0.isAuthenticatedRequest = false
            $0.parameters = ["token": token, "tokenId": tokenId]
        }.then { _ in }
    }

    /**
     * Send a reset password email to a given email address
     * - parameter email: email address to reset password for
     * - returns: A task containing whether or not the reset email was sent successfully
     */
    @discardableResult
    public func sendResetPassword(toEmail email: String) -> StitchTask<Void> {
        return httpClient.doRequest {
            $0.method = .post
            $0.endpoint = self.routes.localUserpassResetSendRoute
            $0.isAuthenticatedRequest = false
            $0.parameters = ["email": email]
        }.then { _ in }
    }

    /**
     Logs the current user in anonymously.
     
     - Returns: A task containing whether or not the login as successful
     */
    @discardableResult
    public func anonymousAuth() -> StitchTask<UserId> {
        return login(withProvider: AnonymousAuthProvider())
    }

    /**
     Logs the current user in using a specific auth provider.
     
     - Parameters:
     - withProvider: The provider that will handle the login.
     - link: Whether or not to link a new auth provider.
     - Returns: A task containing whether or not the login as successful
     */
    @discardableResult
    public func login(withProvider provider: AuthProvider) -> StitchTask<UserId> {
        self.authProvider = provider

        if isAuthenticated, let auth = auth {
            printLog(.info, text: "Already logged in, using cached token.")
            return StitchTask<UserId>.withSuccess(auth.userId)
        }

        return httpClient.doRequest {
            $0.method = .post
            $0.endpoint = self.routes.authProvidersLoginRoute(provider: provider.type)
            $0.isAuthenticatedRequest = false
            $0.parameters = self.getAuthRequest(provider: provider)
        }.then { [weak self] any in
            guard let strongSelf = self else { throw StitchError.clientReleased }
            let authInfo = try JSONDecoder().decode(AuthInfo.self,
                                                    from: JSONSerialization.data(withJSONObject: any))
            strongSelf.httpClient.authInfo = authInfo
            strongSelf.auth = Auth(stitchClient: strongSelf,
                                   stitchHttpClient: strongSelf.httpClient,
                                   userId: authInfo.userId)
            strongSelf.onLogin()
            return authInfo.userId
        }
    }

    /**
     * Logs out the current user.
     *
     * - returns: A task that can be resolved upon completion of logout.
     */
    @discardableResult
    public func logout() -> StitchTask<Void> {
        if !isAuthenticated {
            printLog(.info, text: "Tried logging out while there was no authenticated user found.")
            return StitchTask<Void>(value: Void())
        }

        return httpClient.doRequest {
            $0.method = .delete
            $0.endpoint = self.routes.authSessionRoute
            $0.refreshOnFailure = false
            $0.useRefreshToken = true
        }.then { _ in }
    }

    // MARK: Private
    internal func clearAuth() throws {
        onLogout()

        try self.httpClient.clearAuth()
    }

    enum AuthFields: String {
        case accessToken, options, device
    }

    /**
     * @return A {@link Document} representing the information for this device
     * from the context of this app.
     */
    private func getDeviceInfo() -> Document {
        var info = Document()

        if let deviceId = self.httpClient.authInfo?.deviceId {
            info[DeviceFields.deviceId.rawValue] = deviceId
        }

        info[DeviceFields.appVersion.rawValue] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        info[DeviceFields.appId.rawValue] = Bundle.main.bundleIdentifier
        info[DeviceFields.platform.rawValue] = "ios"
        info[DeviceFields.platformVersion.rawValue] = UIDevice.current.systemVersion

        return info
    }

    /**
     * -parameter provider: The provider that will handle authentication.
     * -returns: A dict representing all information required for
     *              an auth request against a specific provider.
     */
    private func getAuthRequest(provider: AuthProvider) -> Document {
        var request = provider.payload
        let options: Document = [
            AuthFields.device.rawValue: getDeviceInfo()
        ]
    	request[AuthFields.options.rawValue] = options
        return request
    }

    // MARK: - Requests
    /**
     * Execute a named function
     * -parameter name: name of the function
     * -parameter args: extended JSON arguments associated with the function
     * -returns: return value of the associated function
    */
    public func executeFunction(name: String,
                                args: ExtendedJsonRepresentable...) -> StitchTask<Any> {
        return httpClient.doRequest {
            $0.method = .post
            $0.endpoint = self.routes.functionsCallRoute
            $0.parameters = ["name": name,
                             "arguments": BSONArray(array: args)]
        }
    }

    /**
     * Execute a named function associated with a service
     * -parameter name: name of the function
     * -parameter serviceName: name of your service
     * -parameter args: extended JSON arguments associated with the function
     * -returns: return value of the associated function
     */
    public func executeServiceFunction(name: String,
                                       service: String,
                                       args: ExtendedJsonRepresentable...) -> StitchTask<Any> {
        return httpClient.doRequest {
            $0.method = .post
            $0.endpoint = self.routes.functionsCallRoute
            $0.parameters = ["name": name,
                             "arguments": BSONArray(array: args),
                             "service": service]
        }
    }

    // MARK: - Error handling
    /**
     * Gets all available push providers for the current app.
     *
     * - returns: A task containing {@link AvailablePushProviders} that can be resolved on completion
     * of the request.
     */
    public func getPushProviders() -> StitchTask<AvailablePushProviders> {
        return httpClient.doRequest {
            $0.endpoint = self.routes.pushProvidersRoute
            $0.isAuthenticatedRequest = false
        }.then {
            guard let array = $0 as? [Any] else {
                throw StitchError.responseParsingFailed(reason: "\($0) was not of expected type array")
            }
            return try AvailablePushProviders.fromQuery(doc: BSONArray(array: array))
        }
    }

    /**
     * Called when a user logs in with this client.
     */
    private func onLogin() {
        authDelegates.forEach { $0?.onLogin() }
    }

    /**
     * Called when a user is logged out from this client.
     */
    private func onLogout() {
        authDelegates.forEach { $0?.onLogout() }
    }

    /**
     Adds a delegate for auth events.
     
     - parameter delegate: The delegate that will receive auth events.
     */
    public func addAuthDelegate(delegate: AuthDelegate) {
        self.authDelegates.append(delegate)
    }
}
