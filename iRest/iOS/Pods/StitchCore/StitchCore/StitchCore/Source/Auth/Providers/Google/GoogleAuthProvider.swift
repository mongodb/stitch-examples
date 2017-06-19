import Foundation

public struct GoogleAuthProvider: AuthProvider {
    
    public var type: String {
        return "oauth2"
    }
    
    public var name: String {
        return "google"
    }
    
    public var payload: [String : Any] {
        return ["authCode" : authCode]
    }
    
    private(set) var authCode: String
    
    //MARK: - Init
    
    public init(authCode: String) {
        self.authCode = authCode
    }
    
}
