import Foundation

public struct GoogleAuthProviderInfo {
    
    private struct Consts {
        static let clientIdKey =        "clientId"
        static let scopesKey =          "metadataFields"
    }
    
    public private(set) var clientId: String
    public private(set) var scopes: [String]
    
    
    init?(dictionary: [String : Any]) {
        
        guard let clientId = dictionary[Consts.clientIdKey] as? String,
            let scopes = dictionary[Consts.scopesKey] as? [String]
        else {
            return nil
        }
        
        self.clientId = clientId
        self.scopes = scopes
    }
}
