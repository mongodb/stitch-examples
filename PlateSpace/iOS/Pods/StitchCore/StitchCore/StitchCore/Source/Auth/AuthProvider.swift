import Foundation

public protocol AuthProvider {
    var type: String {get}
    var name: String {get}
    var payload: [String : Any] {get}
}

public enum Provider {
    case google, facebook, emailPassword, anonymous
    
    var name: String {
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
    
    init?(name: String) {
        switch name {
        case Provider.google.name:
            self = .google
        case Provider.facebook.name:
            self = .facebook
        case Provider.emailPassword.name:
            self = .emailPassword
        case Provider.anonymous.name:
            self = .anonymous
        default:
            return nil
        }
    }
}
