import Foundation

protocol AuthResponse: Codable {
    var userId: String { get }
}

internal struct LinkInfo: AuthResponse {
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }

    var userId: String
}

/// Auth represents the current authorization state of the client
internal struct AuthInfo: AuthResponse {
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token",
        userId = "user_id",
        deviceId = "device_id",
        refreshToken = "refresh_token"
    }

    // The current access token for this session in decoded JWT form.
    // Will be nil if the token was malformed and could not be decoded.
    let accessToken: DecodedJWT?

    // The user this session was created for.
    let deviceId: String

    // The user this session was created for.
    let userId: String

    // The refresh token to refresh an expired access token
    internal var refreshToken: String

    internal func auth(with updatedAccessToken: String) -> AuthInfo {
        return AuthInfo(accessToken: try? DecodedJWT(jwt: updatedAccessToken),
                        deviceId: deviceId,
                        userId: userId,
                        refreshToken: refreshToken)
    }

    /**
     Determines if the access token stored in this Auth object is expired or expiring within
     a provided number of seconds.

     - parameter withinSeconds: expiration threshold in seconds. 10 by default to account for latency and clock drift
     between client and Stitch server
     - returns: true if the access token is expired or is going to expire within 'withinSeconds' seconds
     false if the access token exists and is not expired nor expiring within 'withinSeconds' seconds
     nil if the access token doesn't exist, is malformed, or does not have an 'exp' field.
     */
    public func isAccessTokenExpired(withinSeconds: Double = 10.0) -> Bool? {
        if let exp = self.accessToken?.expiration {
            return Date() >= (exp - TimeInterval(withinSeconds))
        }
        return nil
    }
}
