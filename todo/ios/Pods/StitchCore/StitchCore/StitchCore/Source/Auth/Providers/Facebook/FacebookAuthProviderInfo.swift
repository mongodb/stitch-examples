import Foundation

public struct FacebookAuthProviderInfo {    
    
    private struct Consts {
        static let clientIdKey =        "clientId"
        static let scopesKey =          "metadataFields"
    }
    
    public private(set) var appId: String
    public private(set) var scopes: [String]?
    
    
    init?(dictionary: [String : Any]) {
        
        guard let appId = dictionary[Consts.clientIdKey] as? String
            else {
                return nil
        }
        
        if let scopes = dictionary[Consts.scopesKey] as? [String] {
            self.scopes = scopes
        }

        self.appId = appId
    }
}
