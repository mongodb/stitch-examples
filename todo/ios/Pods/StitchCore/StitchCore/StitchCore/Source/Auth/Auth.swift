//
//  Auth.swift
//  StitchCore
//
//  Created by Jason Flax on 10/18/17.
//  Copyright © 2017 MongoDB. All rights reserved.
//

import Foundation
import PromiseKit

public class Auth {
    public let userId: String

    private let stitchClient: StitchClient
    private let stitchHttpClient: StitchHTTPClient

    // Initializes new Auth resource
    // - parameter stitchClient: associated stitch client
    // - parameter authInfo: information about the logged in status
    internal init(stitchClient: StitchClient,
                  stitchHttpClient: StitchHTTPClient,
                  userId: String) {
        self.stitchClient = stitchClient
        self.stitchHttpClient = stitchHttpClient
        self.userId = userId
    }

    public func createApiKey(name: String) -> Promise<ApiKey> {
        return stitchHttpClient.doRequest {
            $0.method =  .post
            $0.endpoint = self.stitchClient.routes.apiKeysRoute
            try $0.encode(withData: ["name": name])
            $0.refreshOnFailure = true
            $0.useRefreshToken = true
        }.flatMap {
            return try JSONDecoder().decode(ApiKey.self, from: JSONSerialization.data(withJSONObject: $0))
        }
    }

    public func fetchApiKey(id: String) -> Promise<ApiKey> {
        return stitchHttpClient.doRequest {
            $0.endpoint = self.stitchClient.routes.apiKeyRoute(id: id)
            $0.refreshOnFailure = true
            $0.useRefreshToken = true
        }.flatMap {
            return try JSONDecoder().decode(ApiKey.self, from: JSONSerialization.data(withJSONObject: $0))
        }
    }

    public func fetchApiKeys() -> Promise<[ApiKey]> {
        return stitchHttpClient.doRequest {
            $0.endpoint = self.stitchClient.routes.apiKeysRoute
            $0.refreshOnFailure = true
            $0.useRefreshToken = true
        }.flatMap {
            return try JSONDecoder().decode([ApiKey].self, from: JSONSerialization.data(withJSONObject: $0))
        }
    }

    public func deleteApiKey(id: String) -> Promise<Void> {
        return stitchHttpClient.doRequest {
            $0.method = .delete
            $0.endpoint = self.stitchClient.routes.apiKeyRoute(id: id)
            $0.refreshOnFailure = true
            $0.useRefreshToken = true
        }.asVoid()
    }

    private func enableDisableApiKey(id: String, shouldEnable: Bool) -> Promise<Void> {
        return stitchHttpClient.doRequest {
            $0.method = .put
            $0.endpoint = shouldEnable ? self.stitchClient.routes.apiKeyEnableRoute(id: id) :
                self.stitchClient.routes.apiKeyDisableRoute(id: id)
            $0.refreshOnFailure = true
            $0.useRefreshToken = true
        }.asVoid()
    }

    public func enableApiKey(id: String) ->  Promise<Void> {
        return self.enableDisableApiKey(id: id, shouldEnable: true)
    }

    public func disableApiKey(id: String) -> Promise<Void> {
        return self.enableDisableApiKey(id: id, shouldEnable: false)
    }

    /**
     Fetch the current user profile, containing all user info. Can fail.
     
     - Returns: A Promise containing profile of the given user
     */
    @discardableResult
    public func fetchUserProfile() -> Promise<UserProfile> {
        return self.stitchHttpClient.doRequest {
            $0.endpoint = self.stitchClient.routes.authProfileRoute
            $0.refreshOnFailure = false
            $0.useRefreshToken = false
        }.flatMap {
            return try JSONDecoder().decode(UserProfile.self,
                                            from: JSONSerialization.data(withJSONObject: $0))
        }
    }
}
