import Foundation

import ExtendedJson
import StitchLogger
import Security

internal struct Consts {
    static let DefaultBaseUrl =          "https://stitch.mongodb.com"
    static let ApiPath =                 "/api/client/v1.0/app/"
    
    //User Defaults
    static let UserDefaultsName =        "com.mongodb.stitch.sdk.UserDefaults"
    static let IsLoggedInUDKey =         "StitchCoreIsLoggedInUserDefaultsKey"
    
    //keychain
    static let AuthJwtKey =              "StitchCoreAuthJwtKey"
    static let AuthRefreshTokenKey =     "StitchCoreAuthRefreshTokenKey"
    static let AuthKeychainServiceName = "com.mongodb.stitch.sdk.authentication"
    
    //keys
    static let ResultKey =               "result"
    static let AccessTokenKey =          "accessToken"
    static let RefreshTokenKey =         "refreshToken"
    static let ErrorKey =                "error"
    static let ErrorCodeKey =            "errorCode"
    
    //api
    static let AuthPath =                "auth"
    static let UserProfilePath =         "auth/me"
    static let NewAccessTokenPath =      "newAccessToken"
    static let PipelinePath =            "pipeline"
    static let PushPath =                "push"
}

public class StitchClient: StitchClientType {
    // MARK: - Properties
    public var appId: String
    
    private var baseUrl: String
    private let networkAdapter: NetworkAdapter
    
    private let userDefaults = UserDefaults(suiteName: Consts.UserDefaultsName)

    private var authProvider: AuthProvider?
    private var authDelegates = [AuthDelegate?]()

    public private(set) var auth: Auth? {
        didSet{
            if let newValue = auth {
                // save auth persistently
                userDefaults?.set(true, forKey: Consts.IsLoggedInUDKey)
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: newValue.json, options: JSONSerialization.WritingOptions())
                    guard let jsonString = String(data: jsonData, encoding: String.Encoding.utf8) else {
                        printLog(.error, text: "Error converting json String to Data")
                        return
                    }
                    
                    save(token: jsonString, withKey: Consts.AuthJwtKey)
                } catch let error as NSError {
                    printLog(.error, text: "failed saving auth to keychain, array to JSON conversion failed: \(error.localizedDescription)")
                }
            }
            else {
                // remove from keychain
                try? deleteToken(withKey: Consts.AuthJwtKey)
                userDefaults?.set(false, forKey: Consts.IsLoggedInUDKey)
            }
        }
    }
    
    public var isAuthenticated: Bool {
        
        guard auth == nil else {
            return true
        }
        
        do {
            auth = try getAuthFromSavedJwt()
        }
        catch {
            printLog(.error, text: error.localizedDescription)
        }
        
        onLogin()
        return auth != nil
    }
    
    private var refreshToken: String? {
        
        guard isAuthenticated else {
            return nil
        }
        
        return readToken(withKey: Consts.AuthRefreshTokenKey)
    }
    
    private var isSimulator: Bool {
        /*
         This is computed in a separate variable due to a compiler warning when the check is done directly inside the 'if' statement, indicating that either the 'if' block or the 'else' block will never be executed - depending whether the build target is a simulator or a device.
         */
        return TARGET_OS_SIMULATOR != 0
    }
    
    // MARK: - Init
    
    public init(appId: String, baseUrl: String = Consts.DefaultBaseUrl, networkAdapter: NetworkAdapter = AlamofireNetworkAdapter()) {
        self.appId = appId
        self.baseUrl = baseUrl
        self.networkAdapter = networkAdapter
    }
    
    // MARK: - Auth
    @discardableResult
    public func fetchUserProfile() -> StitchTask<UserProfile> {
        let task = StitchTask<UserProfile>()
        
        if !isAuthenticated {
            task.result = StitchResult.failure(StitchError.unauthorized(
                message: "Tried fetching user while there was no authenticated user found."))
            return task
        }
        
        performRequest(method: .get,
                       endpoint: Consts.UserProfilePath,
                       parameters: nil,
                       refreshOnFailure: false,
                       useRefreshToken: false).response(onQueue: DispatchQueue.global(qos: .utility)) { [weak self] (result) in
                        guard let strongSelf = self else {
                            task.result = StitchResult.failure(StitchError.clientReleased)
                            return
                        }
                        
                        switch result {
                        case .success(let value):
                            if let value = value as [String : Any]? {
                                if let error = strongSelf.parseError(from: value) {
                                    task.result = .failure(error)
                                }
                                else if let user = try? UserProfile(dictionary: value) {
                                    task.result = .success(user)
                                } else {
                                    task.result = StitchResult.failure(StitchError.clientReleased)
                                }
                            }
                        case .failure(let error):
                            task.result = .failure(error)
                        }
        }
        
        return task
    }
    
    @discardableResult
    public func fetchAuthProviders() -> StitchTask<AuthProviderInfo> {
        let task = StitchTask<AuthProviderInfo>()
        let url = self.url(withEndpoint: Consts.AuthPath)
        networkAdapter.requestWithJsonEncoding(url: url, method: .get, parameters: nil, headers: nil).response(onQueue: DispatchQueue.global(qos: .utility)) { [weak self] (response) in
            guard let strongSelf = self else {
                task.result = StitchResult.failure(StitchError.clientReleased)
                return
            }
            
            switch response {
            case .success(let value):
                if let value = value as? [String : Any] {
                    if let error = strongSelf.parseError(from: value) {
                        task.result = .failure(error)
                    }
                    else {
                        task.result = .success(AuthProviderInfo(dictionary: value))
                    }
                }
                
            case .failure(let error):
                task.result = .failure(error)
                
            }
        }
        
        return task
    }
    
    @discardableResult
    public func register(email: String, password: String) -> StitchTask<Void> {
        let task = StitchTask<Void>()
        let provider = EmailPasswordAuthProvider(username: email, password: password)
        let url = "\(self.url(withEndpoint: Consts.AuthPath))/\(provider.type)/\(provider.name)/register"
        
        let payload = ["email" : email, "password" : password]
        networkAdapter.requestWithJsonEncoding(url: url, method: .post, parameters: payload, headers: nil).response { [weak self] (result) in
            
            guard let strongSelf = self else {
                task.result = StitchResult.failure(StitchError.clientReleased)
                return
            }
            
            switch result {
            case .success(let value):
                if let value = value as? [String : Any] {
                    if let error = strongSelf.parseError(from: value) {
                        task.result = .failure(error)
                    }
                    else {
                        task.result = .success()
                    }
                }
            case .failure(let error):
                task.result = .failure(error)
            }
        }
        
        return task
    }
    
    @discardableResult
    public func emailConfirm(token: String, tokenId: String) -> StitchTask<Any> {
        let task = StitchTask<Any>()
        let url = "\(self.url(withEndpoint: Consts.AuthPath))/local/userpass/confirm"
        let params = ["token" : token, "tokenId" : tokenId]
        networkAdapter.requestWithJsonEncoding(url: url, method: .post, parameters: params, headers: nil).response { [weak self] (result) in
            guard let strongSelf = self else {
                task.result = StitchResult.failure(StitchError.clientReleased)
                return
            }
            
            switch result {
            case .success(let value):
                if let value = value as? [String : Any] {
                    if let error = strongSelf.parseError(from: value) {
                        task.result = .failure(error)
                    }
                    else {
                        task.result = .success(value)
                    }
                }
            case .failure(let error):
                task.result = .failure(error)
            }
        }
        
        return task
    }
    
    @discardableResult
    public func sendEmailConfirm(toEmail email: String) -> StitchTask<Void> {
        let task = StitchTask<Void>()
        let url = "\(self.url(withEndpoint: Consts.AuthPath))/local/userpass/confirm/send"
        let params = ["email" : email]
        networkAdapter.requestWithJsonEncoding(url: url, method: .post, parameters: params, headers: nil).response { [weak self] (result) in
            guard let strongSelf = self else {
                task.result = StitchResult.failure(StitchError.clientReleased)
                return
            }
            
            switch result {
            case .success(let value):
                if let value = value as? [String : Any] {
                    if let error = strongSelf.parseError(from: value) {
                        task.result = .failure(error)
                    }
                    else {
                        task.result = .success()
                    }
                }
            case .failure(let error):
                task.result = .failure(error)
            }
        }
        
        return task
    }
    
    @discardableResult
    public func resetPassword(token: String, tokenId: String) -> StitchTask<Any> {
        let task = StitchTask<Any>()
        let url = "\(self.url(withEndpoint: Consts.AuthPath))/local/userpass/reset"
        let params = ["token" : token, "tokenId" : tokenId]
        networkAdapter.requestWithJsonEncoding(url: url, method: .post, parameters: params, headers: nil).response { [weak self] (result) in
            guard let strongSelf = self else {
                task.result = StitchResult.failure(StitchError.clientReleased)
                return
            }
            
            switch result {
            case .success(let value):
                if let value = value as? [String : Any] {
                    if let error = strongSelf.parseError(from: value) {
                        task.result = .failure(error)
                    }
                    else {
                        task.result = .success(value)
                    }
                }
            case .failure(let error):
                task.result = .failure(error)
            }
        }
        
        return task
    }
    
    @discardableResult
    public func sendResetPassword(toEmail email: String) -> StitchTask<Void> {
        let task = StitchTask<Void>()
        let url = "\(self.url(withEndpoint: Consts.AuthPath))/local/userpass/reset/send"
        let params = ["email" : email]
        networkAdapter.requestWithJsonEncoding(url: url, method: .post, parameters: params, headers: nil).response { [weak self] (result) in
            guard let strongSelf = self else {
                task.result = StitchResult.failure(StitchError.clientReleased)
                return
            }
            
            switch result {
            case .success(let value):
                if let value = value as? [String : Any] {
                    if let error = strongSelf.parseError(from: value) {
                        task.result = .failure(error)
                    }
                    else {
                        task.result = .success()
                    }
                }
            case .failure(let error):
                task.result = .failure(error)
            }
        }
        
        return task
    }
    
    @discardableResult
    public func anonymousAuth() -> StitchTask<Bool> {
        return login(withProvider: AnonymousAuthProvider())
    }
    
    @discardableResult
    public func login(withProvider provider: AuthProvider, link: Bool = false) -> StitchTask<Bool> {
        let task = StitchTask<Bool>()
        
        self.authProvider = provider
        
        if isAuthenticated && !link {
            printLog(.info, text: "Already logged in, using cached token.")
            task.result = .success(true)
            return task
        }
        
        var url = "\(self.url(withEndpoint: Consts.AuthPath))/\(provider.type)/\(provider.name)"
        if link {
            guard let auth = auth else {
                task.result = .failure(StitchError.illegalAction(message: "In order to link a new authentication provider you must first be authenticated."))
                return task
            }
            
            url += "?link=\(auth.accessToken)"
        }
        
        var parameters = provider.payload
        self.getAuthRequest(provider: provider).forEach { (key: String, value: Any) in
            parameters[key] = value
        }
        
        networkAdapter.requestWithJsonEncoding(url: url, method: .post, parameters: parameters, headers: nil).response(onQueue: DispatchQueue.global(qos: .utility)) { [weak self] (response) in
            guard let strongSelf = self else {
                task.result = StitchResult.failure(StitchError.clientReleased)
                return
            }
            
            switch response {
            case .success(let value):
                if let value = value as? [String : Any] {
                    if let error = strongSelf.parseError(from: value) {
                        task.result = .failure(error)
                    }
                    else {
                        do {
                            strongSelf.auth = try Auth(dictionary: value)
                        }
                        catch let error {
                            printLog(.error, text: "failed creating Auth: \(error)")
                            task.result = .failure(error)
                        }
                        
                        if strongSelf.auth != nil {
                            
                            if let refreshToken = value[Consts.RefreshTokenKey] as? String {
                                self?.save(token: refreshToken, withKey: Consts.AuthRefreshTokenKey)
                            }
                            task.result = .success(true)
                        }
                    }
                }
                else {
                    printLog(.error, text: "Login failed - failed parsing auth response.")
                    task.result = .failure(StitchError.responseParsingFailed(reason: "Invalid auth response - expected json and received: \(value)"))
                }
            case .failure(let error):
                task.result = .failure(error)
                
            }
        }
        
        return task
    }
    
    @discardableResult
    public func logout() -> StitchTask<Bool> {
        let task = StitchTask<Bool>()
        
        if !isAuthenticated {
            printLog(.info, text: "Tried logging out while there was no authenticated user found.")
            task.result = .success(false)
            return task
        }
        
        performRequest(method: .delete, endpoint: Consts.AuthPath, parameters: nil, refreshOnFailure: false, useRefreshToken: true).response(onQueue: DispatchQueue.global(qos: .utility)) { [weak self] (result) in
            guard let strongSelf = self else {
                task.result = StitchResult.failure(StitchError.clientReleased)
                return
            }
            
            if let error = result.error {
                task.result = .failure(error)
            }
            else {
                do {
                    try strongSelf.clearAuth()
                    task.result = .success(true)
                } catch {
                    task.result = .failure(error)
                }
            }
        }
        return task
    }
    
    // MARK: Private
    private func url(withEndpoint endpoint: String) -> String {
        return "\(baseUrl)\(Consts.ApiPath)\(appId)/\(endpoint)"
    }
    
    private func clearAuth() throws {
        guard auth != nil else {
            return
        }
        
        onLogout()

        auth = nil
        
        try deleteToken(withKey: Consts.AuthRefreshTokenKey)
        
        networkAdapter.cancelAllRequests()
    }
    
    enum AuthFields : String {
        case AccessToken = "accessToken";
        case Options = "options";
        case Device = "device";
    }
    
    /**
     * @return A {@link Document} representing the information for this device
     * from the context of this app.
     */
    private func getDeviceInfo() -> [String : Any] {
        var info = [String : Any]()
        
        if let deviceId = auth?.deviceId {
            info[DeviceFields.DeviceId.rawValue] = deviceId
        }
        
        info[DeviceFields.AppVersion.rawValue] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        info[DeviceFields.AppId.rawValue] = Bundle.main.bundleIdentifier
        info[DeviceFields.Platform.rawValue] = "ios"
        info[DeviceFields.PlatformVersion.rawValue] = UIDevice.current.systemVersion
        
        return info;
    }
    
    /**
     * -parameter provider: The provider that will handle authentication.
     * -returns: A dict representing all information required for
     *              an auth request against a specific provider.
     */
    private func getAuthRequest(provider: AuthProvider) -> [String : Any] {
        var request = provider.payload
        var options = [String : Any]()
        options[AuthFields.Device.rawValue] = getDeviceInfo()
    	request[AuthFields.Options.rawValue] = options
        return request;
    }
    
    // MARK: - Requests
    
    @discardableResult
    public func executePipeline(pipeline: Pipeline) -> StitchTask<Any> {
        return executePipeline(pipelines: [pipeline])
    }
    
    @discardableResult
    public func executePipeline(pipelines: [Pipeline]) -> StitchTask<Any> {
        let params: [[String: Any]] = pipelines.map { $0.toJson }
        
        return performRequest(method: .post, endpoint: Consts.PipelinePath, parameters: params).continuationTask(parser: { (json) -> Any in
            let document = try Document(extendedJson: json)
            if let docResult = document[Consts.ResultKey] {
                return docResult
            }
            else {
                throw StitchError.responseParsingFailed(reason: "Unexpected result received - expected a json reponse with a 'result' key, found: \(json).")
            }
        })
    }
    
    // MARK: Private
    
    @discardableResult
    private func performRequest(method: NAHTTPMethod, endpoint: String, parameters: [[String : Any]]?, refreshOnFailure: Bool = true, useRefreshToken: Bool = false) -> StitchTask<[String : Any]> {
        let task = StitchTask<[String : Any]>()
        guard isAuthenticated else {
            task.result = .failure(StitchError.unauthorized(message: "Must first authenticate"))
            return task
        }
        
        let url = self.url(withEndpoint: endpoint)
        let token = useRefreshToken ? refreshToken ?? String() : auth?.accessToken ?? String()
        
        networkAdapter.requestWithArray(url: url, method: method, parameters: parameters, headers: ["Authorization" : "Bearer \(token)"]).response(onQueue: DispatchQueue.global(qos: .utility), completionHandler: { [weak self] (response) in
            guard let strongSelf = self else {
                task.result = StitchResult.failure(StitchError.clientReleased)
                return
            }
            
            switch response {
            case .success(let value):
                strongSelf.handleSuccessfulResponse(withValue: value, method: method, endpoint: endpoint, parameters: parameters, refreshOnFailure: refreshOnFailure, task: task)
                
            case .failure(let error):
                task.result = .failure(error)
                
            }
        })
        
        return task
    }
    
    func handleSuccessfulResponse(withValue value: Any, method: NAHTTPMethod, endpoint: String, parameters: [[String : Any]]?, refreshOnFailure: Bool, task: StitchTask<[String : Any]>) {
        if let value = value as? [String : Any] {
            if let error = parseError(from: value) {
                switch error {
                case .serverError(let reason):
                    
                    // check if error is invalid session
                    if reason.isInvalidSession {
                        if refreshOnFailure {
                            handleInvalidSession(method: method, endpoint: endpoint, parameters: parameters, task: task)
                        }
                        else {
                            try? clearAuth()
                            task.result = .failure(error)
                        }
                    }
                    else {
                        task.result = .failure(error)
                    }
                default:
                    task.result = .failure(error)
                }
            }
            else {
                task.result = .success(value)
            }
        }
        else {
            task.result = .failure(StitchError.responseParsingFailed(reason: "Unexpected result received - expected json and received: \(value)"))
        }
    }
    
    private func getAuthFromSavedJwt() throws -> Auth? {
        guard userDefaults?.bool(forKey: Consts.IsLoggedInUDKey) == true else {
            return nil
        }
        
        do {
            if let authDicString = readToken(withKey: Consts.AuthJwtKey),
                let authDicData = authDicString.data(using: .utf8),
                let authDic = try JSONSerialization.jsonObject(with: authDicData, options: []) as? [String: Any] {
                return try Auth(dictionary: authDic)
            }
        } catch {
            printLog(.error, text: "Failed reading auth token from keychain")
        }
        
        return nil
    }
    
    // MARK: - Refresh Access Token
    
    private func handleInvalidSession(method: NAHTTPMethod, endpoint: String, parameters: [[String : Any]]?, task: StitchTask<[String : Any]>) {
        refreshAccessToken().response(onQueue: DispatchQueue.global(qos: .utility)) { [weak self] (result) in
            guard let strongSelf = self else {
                task.result = StitchResult.failure(StitchError.clientReleased)
                return
            }
            
            switch result {
            case .failure(let error):
                task.result = .failure(error)
                
            case .success:
                // retry once
                strongSelf.performRequest(method: method, endpoint: endpoint, parameters: parameters, refreshOnFailure: false)
                    .response(onQueue: DispatchQueue.global(qos: .utility)) { (result) in
                        switch result {
                        case .failure(let error):
                            task.result = .failure(error)
                            
                        case .success(let value):
                            task.result = .success(value)
                            
                        }
                }
                
            }
        }
    }
    
    private func refreshAccessToken() -> StitchTask<Void> {
        return performRequest(method: .post, endpoint: "\(Consts.AuthPath)/\(Consts.NewAccessTokenPath)", parameters: nil, refreshOnFailure: false, useRefreshToken: true).continuationTask(parser: { [weak self] (json) -> Void in
            guard let strongSelf = self else {
                throw StitchError.clientReleased
            }
            
            if let accessToken = json[Consts.AccessTokenKey] as? String {
                strongSelf.auth = strongSelf.auth?.auth(with: accessToken)
            }
            else {
                throw StitchError.responseParsingFailed(reason: "failed parsing access token from result: \(json).")
            }
        })
    }
    
    // MARK: - Token operations
    
    private func save(token: String, withKey key: String) {
        if isSimulator {
            printLog(.debug, text: "Falling back to saving token in UserDefaults because of simulator bug")
            userDefaults?.set(token, forKey: key)
        } else {
            do {
                let keychainItem = KeychainPasswordItem(service: Consts.AuthKeychainServiceName, account: key)
                try keychainItem.savePassword(token)
            } catch {
                printLog(.warning, text: "failed saving token to keychain: \(error)")
            }
        }
    }
    
    private func deleteToken(withKey key: String) throws {
        if isSimulator {
            printLog(.debug, text: "Falling back to deleting token from UserDefaults because of simulator bug")
            userDefaults?.removeObject(forKey: key)
        } else {
            do {
                let keychainItem = KeychainPasswordItem(service: Consts.AuthKeychainServiceName, account: key)
                try keychainItem.deleteItem()
            } catch {
                printLog(.warning, text: "failed deleting auth token from keychain: \(error)")
                throw error
            }
        }
    }
    
    private func readToken(withKey key: String) -> String? {
        if isSimulator {
            printLog(.debug, text: "Falling back to reading token from UserDefaults because of simulator bug")
            return userDefaults?.object(forKey: key) as? String
        } else {
            do {
                let keychainItem = KeychainPasswordItem(service: Consts.AuthKeychainServiceName, account: key)
                let token = try keychainItem.readPassword()
                return token
            } catch {
                printLog(.warning, text: "failed reading auth token from keychain: \(error)")
                return nil
            }
        }
    }

    // MARK: - Error handling
    
    private func parseError(from value: [String : Any]) -> StitchError? {
        
        guard let errMsg = value[Consts.ErrorKey] as? String else {
            return nil
        }
        
        printLog(.error, text: "request failed. error: \(errMsg)")
        
        if let errorCode = value[Consts.ErrorCodeKey] as? String {
            return StitchError.serverError(reason: StitchError.ServerErrorReason(errorCode: errorCode, errorMessage: errMsg))
        }
        
        return StitchError.serverError(reason: .other(message: errMsg))
    }
    
    
    /**
     * Gets all available push providers for the current app.
     *
     * - returns: A task containing {@link AvailablePushProviders} that can be resolved on completion
     * of the request.
     */
    public func getPushProviders() -> StitchTask<AvailablePushProviders> {
        return performRequest(method: .get, endpoint: Consts.PushPath, parameters: nil).continuationTask { json in
            return AvailablePushProviders.fromQuery(doc: try! Document(extendedJson: json))
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
    
    public func addAuthDelegate(delegate: AuthDelegate) {
        self.authDelegates.append(delegate)
    }
}
