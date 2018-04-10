import Foundation

import ExtendedJson
import StitchLogger
import Security
import PromiseKit

public struct Consts {
    static let ApiPath = "/api/client/v2.0/"

    //User Defaults
    static let UserDefaultsName = "com.mongodb.stitch.sdk.UserDefaults"

    public static let defaultServerUrl = "https://stitch.mongodb.com"

    //keys
    static let ErrorKey = "error"
}

internal protocol StitchClientFactoryProtocol {
    associatedtype TClient = StitchClientType

    static func create(appId: String,
                       baseUrl: String,
                       networkAdapter: NetworkAdapter,
                       storage: Storage?) -> Promise<TClient>
}

public final class StitchClientFactory: StitchClientFactoryProtocol {
    typealias TClient = StitchClient

    public static func create(appId: String,
                              baseUrl: String = Consts.defaultServerUrl,
                              networkAdapter: NetworkAdapter = StitchNetworkAdapter(),
                              storage: Storage? = nil) -> Promise<StitchClient> {
        return Promise.value(StitchClient.init(appId: appId,
                                               baseUrl: baseUrl,
                                               networkAdapter: networkAdapter,
                                               storage: storage))
    }
}

/// A StitchClient is responsible for handling the overall interaction with all Stitch services.
// swiftlint:disable:next type_body_length
public class StitchClient: StitchClientType {
    // MARK: - Properties
    /// Id of the current application
    public var appId: String
    internal lazy var routes = Routes(appId: appId)
    internal var baseUrl: String
    internal let networkAdapter: NetworkAdapter

    internal var storage: Storage
    internal lazy var storageKeys = StorageKeys(suiteName: self.appId)

    internal lazy var httpClient = StitchHTTPClient(baseUrl: baseUrl,
                                                     apiPath: Consts.ApiPath,
                                                     networkAdapter: networkAdapter,
                                                     storage: storage,
                                                     storageKeys: storageKeys)
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
        lazy var localUserpassRegisterRoute = "\(authProvidersExtensionRoute)/local-userpass/register"
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
    private var _auth: Auth? {
        didSet {
            if let refreshToken = httpClient.authInfo?.refreshToken {
                // save auth persistently
                storage.set(true, forKey: self.storageKeys.isLoggedInUDKey)
                storage.set(self.authProvider?.type.rawValue, forKey: self.storageKeys.authProviderTypeUDKey)

                do {
                    let jsonData = try JSONEncoder().encode(httpClient.authInfo)
                    guard let jsonString = String(data: jsonData,
                                                  encoding: .utf8) else {
                        printLog(.error, text: "Error converting json String to Data")
                        return
                    }

                    self.httpClient.save(token: refreshToken, withKey: self.storageKeys.authRefreshTokenKey)
                    self.httpClient.save(token: jsonString, withKey: self.storageKeys.authJwtKey)
                } catch let error as NSError {
                    printLog(.error,
                             text: "failed saving auth to keychain, array to JSON conversion failed: " +
                                error.localizedDescription)
                }
            } else {
                // remove from keychain
                try? self.httpClient.deleteToken(withKey: self.storageKeys.authJwtKey)
                storage.set(false, forKey: self.storageKeys.isLoggedInUDKey)
                storage.removeObject(forKey: self.storageKeys.authProviderTypeUDKey)
            }
        }
    }

    public var auth: Auth? {
        if _auth == nil && isAuthenticated, let userId = self.httpClient.authInfo?.userId {
            _auth = Auth(stitchClient: self,
                         stitchHttpClient: self.httpClient,
                         userId: userId)
        }

        return _auth
    }

    /// Whether or not the client is currently authenticated
    public var isAuthenticated: Bool {
        return self.httpClient.isAuthenticated
    }

    // The type of the provider used to log into the current session, or the most recent
    // provider linked. nil if not authenticated or if provider type is not recognized
    public var loggedInProviderType: AuthProviderTypes? {
        if let rawProviderType =
            storage.value(forKey: self.storageKeys.authProviderTypeUDKey) as? String {
            return AuthProviderTypes(rawValue: rawProviderType)
        }
        return nil
    }

    // MARK: - Init
    /**
        Create a new object to interact with Stitch
        - Parameters: 
            - appId:  The App ID for the Stitch app.
            - baseUrl: The base URL of the Stitch Client API server.
            - networkAdapter: Optional interface if AlamoFire is not desired.
     */
    fileprivate init(appId: String,
                     baseUrl: String = "https://stitch.mongodb.com",
                     networkAdapter: NetworkAdapter = StitchNetworkAdapter(),
                     storage: Storage? = nil) {
        self.appId = appId
        self.baseUrl = baseUrl
        self.networkAdapter = networkAdapter

        let suiteName = "\(Consts.UserDefaultsName).\(appId)"
        if let storage = storage {
            self.storage = storage
        } else {
            #if !os(Linux)
            guard let userDefaults = UserDefaults.init(suiteName: suiteName) else {
                self.storage = MemoryStorage.init()
                printLog(.warning, text: "Invalid suiteName: \(suiteName)")
                printLog(.warning,
                         text: "Defaulting to memory storage. NOTE: App will not persist authentication status")
                return
            }
            self.storage = userDefaults
            #else
            printLog(.warning, text: "Defaulting to memory storage. NOTE: App will not persist authentication status")
            self.storage = MemoryStorage.init(suiteName: suiteName)!
            #endif
        }

        runMigration(storage: &self.storage)
    }

    // MARK: - Auth

    /**
     Fetches all available auth providers for the current app.
     
     - Returns: A task containing AuthProviderInfo that can be resolved
     on completion of the request.
     */
    @discardableResult
    public func fetchAuthProviders() -> Promise<AuthProviderInfo> {
        return httpClient.doRequest {
            $0.endpoint = self.routes.authProvidersExtensionRoute
            $0.isAuthenticatedRequest = false
        }.flatMap { any in
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
    public func register(email: String, password: String) -> Promise<Void> {
        return httpClient.doRequest {
            $0.method = .post
            $0.endpoint = self.routes.localUserpassRegisterRoute
            $0.isAuthenticatedRequest = false
            try $0.encode(withData: ["email": email, "password": password])
        }.asVoid()
    }

    /**
     * Confirm a newly registered email in this context
     * - parameter token: confirmation token emailed to new user
     * - parameter tokenId: confirmation tokenId emailed to new user
     * - returns: A task containing whether or not the email was confirmed successfully
     */
    @discardableResult
    public func emailConfirm(token: String, tokenId: String) -> Promise<Void> {
        return httpClient.doRequest {
            $0.method = .post
            $0.endpoint = self.routes.localUserpassConfirmRoute
            $0.isAuthenticatedRequest = false
            try $0.encode(withData: ["token": token, "tokenId": tokenId])
        }.asVoid()
    }

    /**
     * Send a confirmation email for a newly registered user
     * - parameter email: email address of user
     * - returns: A task containing whether or not the email was sent successfully.
     */
    @discardableResult
    public func sendEmailConfirm(toEmail email: String) -> Promise<Void> {
        return httpClient.doRequest {
            $0.method = .post
            $0.endpoint = self.routes.localUserpassConfirmSendRoute
            $0.isAuthenticatedRequest = false
            try $0.encode(withData: ["email": email])
        }.asVoid()
    }

    /**
     * Reset a given user's password
     * - parameter token: token associated with this user
     * - parameter tokenId: id of the token associated with this user
     * - returns: A task containing whether or not the reset was successful
     */
    @discardableResult
    public func resetPassword(token: String, tokenId: String, password: String) -> Promise<Void> {
        return httpClient.doRequest {
            $0.method = .post
            $0.endpoint = self.routes.localUserpassResetRoute
            $0.isAuthenticatedRequest = false
            try $0.encode(withData: ["token": token,
                                    "tokenId": tokenId,
                                    "password": password])
        }.asVoid()
    }

    /**
     * Send a reset password email to a given email address
     * - parameter email: email address to reset password for
     * - returns: A task containing whether or not the reset email was sent successfully
     */
    @discardableResult
    public func sendResetPassword(toEmail email: String) -> Promise<Void> {
        return httpClient.doRequest {
            $0.method = .post
            $0.endpoint = self.routes.localUserpassResetSendRoute
            $0.isAuthenticatedRequest = false
            try $0.encode(withData: ["email": email])
        }.asVoid()
    }

    /**
     Logs the current user in anonymously.
     
     - Returns: A task containing whether or not the login as successful
     */
    @discardableResult
    public func anonymousAuth() -> Promise<UserId> {
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
    public func login(withProvider provider: AuthProvider) -> Promise<UserId> {
        guard let userId = self.auth?.userId else {
            // Not currently authenticated, perform login.
            return self.doAuthRequest(withProvider: provider)
        }

        // Check if logging in as anonymous user while already logged in as anonymous user
        if provider.type == AuthProviderTypes.anonymous &&
            self.loggedInProviderType == AuthProviderTypes.anonymous {
            printLog(.info, text: "Already logged in as anonymous user, using cached token.")
            return Promise.value(userId)
        }

        // Using a different provider, log out and then perform login.
        printLog(.info, text: "Already logged in, logging out of existing session.")
        return self.logout().then {
            return self.doAuthRequest(withProvider: provider)
        }
    }

    /**
     * Logs out the current user.
     *
     * - returns: A task that can be resolved upon completion of logout.
     */
    @discardableResult
    public func logout() -> Promise<Void> {
        if !isAuthenticated {
            printLog(.info, text: "Tried logging out while there was no authenticated user found.")
            return Promise.value(())
        }

        return httpClient.doRequest {
            $0.method = .delete
            $0.endpoint = self.routes.authSessionRoute
            $0.refreshOnFailure = false
            $0.useRefreshToken = true
        }.recover { _ in
            // We don't really care about errors in doing the request.
            // Try clearing auth, but throw again if it fails.
            printLog(.info, text: "Logout request to Stitch resulted in error. Clearing locally stored tokens anyway.")
            return Guarantee.value(())
        }.done { _ in
            // This block will always be reached regardless of whether doRequest fails or succeeds
            try self.clearAuth()
            return
        }
    }

    /**
     * Links the current user to another identity.
     *
     * - Parameters:
     * - withProvider: The authentication provider which will provide the new identity
     *
     * - Returns:
     * - The user ID of the current, original user
     */
    @discardableResult
    public func link(withProvider provider: AuthProvider) -> Promise<UserId> {
        if !isAuthenticated {
            return Promise.init(
                error: StitchError.illegalAction(message: "Must be authenticated to link a user to new identity.")
            )
        }

        return self.doAuthRequest(withProvider: provider, withLinking: true)
    }

    // MARK: Private
    private func doAuthRequest(withProvider provider: AuthProvider,
                               withLinking linking: Bool = false) -> Promise<UserId> {
        return httpClient.doRequest { request in
            request.method = .post

            let authRoute = self.routes.authProvidersLoginRoute(provider: provider.type.rawValue)
            request.endpoint = "\(authRoute)\(linking ? "?link=true" : "")"
            request.isAuthenticatedRequest = linking

            try request.encode(withData: self.getAuthRequest(provider: provider))
            }.flatMap { [weak self] json in
                guard let strongSelf = self else { throw StitchError.clientReleased }
                strongSelf.authProvider = provider
                if !linking {
                    let authInfo = try JSONDecoder().decode(AuthInfo.self,
                                                            from: JSONSerialization.data(withJSONObject: json))
                    strongSelf.httpClient.authInfo = authInfo
                    strongSelf._auth = Auth(stitchClient: strongSelf,
                                            stitchHttpClient: strongSelf.httpClient,
                                            userId: authInfo.userId)
                    strongSelf.onLogin()
                    return authInfo.userId
                } else {
                    let linkInfo = try JSONDecoder().decode(LinkInfo.self,
                                                            from: JSONSerialization.data(withJSONObject: json))
                    strongSelf.storage.set(strongSelf.authProvider?.type.rawValue,
                                           forKey: strongSelf.storageKeys.authProviderTypeUDKey)
                    return linkInfo.userId
                }
        }
    }

    internal func clearAuth() throws {
        onLogout()

        self.authProvider = nil
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
            StitchClient.AuthFields.device.rawValue: self.getDeviceInfo()
        ]
    	request[StitchClient.AuthFields.options.rawValue] = options
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
                                args: ExtendedJsonRepresentable...) -> Promise<Any> {
        return httpClient.doRequest {
            $0.method = .post
            $0.endpoint = self.routes.functionsCallRoute
            try $0.encode(withDocument: ["name": name,
                                         "arguments": BSONArray(array: args)])
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
                                       args: ExtendedJsonRepresentable...) -> Promise<Any> {
        return httpClient.doRequest {
            $0.method = .post
            $0.endpoint = self.routes.functionsCallRoute
            try $0.encode(withDocument: ["name": name,
                                         "arguments": BSONArray(array: args),
                                         "service": service])
        }
    }

    // MARK: - Error handling
    /**
     * Gets all available push providers for the current app.
     *
     * - returns: A task containing {@link AvailablePushProviders} that can be resolved on completion
     * of the request.
     */
    public func getPushProviders() -> Promise<AvailablePushProviders> {
        return httpClient.doRequest {
            $0.endpoint = self.routes.pushProvidersRoute
            $0.isAuthenticatedRequest = false
        }.flatMap {
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
// swiftlint:disable:this file_length
