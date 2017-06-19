import Foundation

public struct AnonymousAuthProvider: AuthProvider {
    
    public var type: String {
        return "anon"
    }
    
    public var name: String {
        return "user"
    }
    
    public var payload: [String : Any] {
        return [:]
    }
}
