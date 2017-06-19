import Foundation

public struct FacebookAuthProviderInfo {    
    
    private struct Consts {
        static let clientIdKey =        "clientId"
        static let scopesKey =          "metadataFields"
    }
    
    public private(set) var appId: String
    public private(set) var scopes: [String]
    
    
    init?(dictionary: [String : Any]) {
        
        guard let appId = dictionary[Consts.clientIdKey] as? String,
            let scopes = dictionary[Consts.scopesKey] as? [String]
            else {
                return nil
        }
        
        self.appId = appId
        self.scopes = scopes
    }
}
