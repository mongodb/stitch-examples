import Foundation

public struct Auth {
    
    private static let accessTokenKey =         "accessToken"
    private static let userIdKey =              "userId"
    private static let providerKey =            "provider"
    private static let deviceId =               "deviceId"
    
    let accessToken: String
    let deviceId: String
    
    public let userId: String?
    public let provider: Provider
    
    var json: [String : Any] {
        return [Auth.accessTokenKey : accessToken,
                // TODO: remove once userId is guarenteed to be in the call (backend task)
                Auth.userIdKey : userId ?? "",
                Auth.providerKey : provider.name,
                Auth.deviceId : deviceId]
    }
    
    
    //MARK: - Init
    
    private init(accessToken: String, userId: String?, provider: Provider, deviceId: String) {
        self.accessToken = accessToken
        self.userId = userId
        self.provider = provider
        self.deviceId = deviceId
    }
    
    internal init(dictionary: [String : Any]) throws {
        
        guard let accessToken = dictionary[Auth.accessTokenKey] as? String,
            let userId = dictionary[Auth.userIdKey] as? String?,
            let providerName = dictionary[Auth.providerKey] as? String,
            let provider = Provider(name: providerName),
            let deviceId = dictionary[Auth.deviceId] as? String else {
                throw StitchError.responseParsingFailed(reason: "failed creating Auth out of info: \(dictionary)")
        }
        
        self = Auth(accessToken: accessToken, userId: userId, provider: provider, deviceId: deviceId)
    }
    
    internal func auth(with updatedAccessToken: String) -> Auth {
        return Auth(accessToken: updatedAccessToken, userId: userId, provider: provider, deviceId: deviceId)
    }
}
