import Foundation

public protocol StitchClientType {
    
    // MARK: - Properties
    var appId: String { get }
    var auth: Auth? { get }
    var isAuthenticated: Bool { get }
    
    // MARK: - Auth
    
    @discardableResult
    func fetchAuthProviders() -> StitchTask<AuthProviderInfo>
    
    @discardableResult
    func fetchUserProfile() -> StitchTask<UserProfile>
    
    @discardableResult
    func register(email: String, password: String) -> StitchTask<Void>
    
    @discardableResult
    func emailConfirm(token: String, tokenId: String) -> StitchTask<Any>
    
    @discardableResult
    func sendEmailConfirm(toEmail email: String) -> StitchTask<Void>
    
    @discardableResult
    func resetPassword(token: String, tokenId: String) -> StitchTask<Any>
    
    @discardableResult
    func sendResetPassword(toEmail email: String) -> StitchTask<Void>
    
    @discardableResult
    func anonymousAuth() -> StitchTask<Bool>
    
    @discardableResult
    func login(withProvider provider: AuthProvider, link: Bool) -> StitchTask<Bool>
    
    @discardableResult
    func logout() -> StitchTask<Bool>
    
    // MARK: - Requests
    
    @discardableResult
    func executePipeline(pipeline: Pipeline) -> StitchTask<Any>
    
    @discardableResult
    func executePipeline(pipelines: [Pipeline]) -> StitchTask<Any>
    
    func addAuthDelegate(delegate: AuthDelegate)    
}

// MARK: - Defaul Values

public extension StitchClientType {
    
    @discardableResult
    func login(withProvider provider: AuthProvider, link: Bool = false) -> StitchTask<Bool> {
        return login(withProvider: provider, link: link)
    }
}
