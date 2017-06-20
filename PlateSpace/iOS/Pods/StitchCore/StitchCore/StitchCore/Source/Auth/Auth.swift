import Foundation

public struct Auth {
    
    private static let accessTokenKey =         "accessToken"
    private static let userIdKey =              "userId"
    private static let deviceId =               "deviceId"
    
    let accessToken: String
    let deviceId: String
    
    public let userId: String?
    
    var json: [String : Any] {
        return [Auth.accessTokenKey : accessToken,
                // TODO: remove once userId is guarenteed to be in the call (backend task)
                Auth.userIdKey : userId ?? "",
                Auth.deviceId : deviceId]
    }
    
    
    //MARK: - Init
    
    private init(accessToken: String, userId: String?, deviceId: String) {
        self.accessToken = accessToken
        self.userId = userId
        self.deviceId = deviceId
    }
    
    internal init(dictionary: [String : Any]) throws {
        
        guard let accessToken = dictionary[Auth.accessTokenKey] as? String,
            let userId = dictionary[Auth.userIdKey] as? String?,
            let deviceId = dictionary[Auth.deviceId] as? String else {
                throw StitchError.responseParsingFailed(reason: "failed creating Auth out of info: \(dictionary)")
        }
        
        self = Auth(accessToken: accessToken, userId: userId, deviceId: deviceId)
    }
    
    internal func auth(with updatedAccessToken: String) -> Auth {
        return Auth(accessToken: updatedAccessToken, userId: userId, deviceId: deviceId)
    }
}
