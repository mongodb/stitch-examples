import Foundation

public struct EmailPasswordAuthProvider: AuthProvider {
    
    public var type: String {
        return "local"
    }
    
    public var name: String {
        return "userpass"
    }
    
    public var payload: [String : Any] {
        return ["username" : username,
                "password" : password]
    }
    
    private(set) var username: String
    private(set) var password: String
    
    // MARK: - Init
    
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}
