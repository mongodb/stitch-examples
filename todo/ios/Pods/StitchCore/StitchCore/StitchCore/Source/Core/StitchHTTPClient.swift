//
//  StitchClientRequests.swift
//  StitchCore
//
//  Created by Jason Flax on 10/22/17.
//  Copyright © 2017 MongoDB. All rights reserved.
//

import Foundation
import StitchLogger
import ExtendedJson
import PromiseKit

internal class StitchHTTPClient {
    internal var storage: Storage

    internal var isSimulator: Bool {
        /*
         This is computed in a separate variable due to a compiler warning when the check
         is done directly inside the 'if' statement, indicating that either the 'if'
         block or the 'else' block will never be executed - depending whether the build
         target is a simulator or a device.
         */
        return TARGET_OS_SIMULATOR != 0
    }

    let baseUrl: String
    let networkAdapter: NetworkAdapter
    internal let storageKeys: StorageKeys
    internal var authInfo: AuthInfo?
    private let apiPath: String

    init(baseUrl: String,
         apiPath: String = Consts.ApiPath,
         networkAdapter: NetworkAdapter,
         storage: Storage,
         storageKeys: StorageKeys) {
        self.baseUrl = baseUrl
        self.networkAdapter = networkAdapter
        self.apiPath = apiPath
        self.storage = storage
        self.storageKeys = storageKeys
    }

    /// Whether or not the client is currently authenticated
    public var isAuthenticated: Bool {
        guard authInfo == nil else {
            return true
        }

        do {
            authInfo = try self.getAuthFromSavedJwt()
        } catch {
            printLog(.error, text: error.localizedDescription)
        }

        return authInfo != nil
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
        if let exp = self.authInfo?.accessToken?.expiration {
            return Date() >= (exp - TimeInterval(withinSeconds))
        }
        return nil
    }

    internal func save(token: String, withKey key: String) {
        if isSimulator {
            // Falling back to saving token in UserDefaults because of simulator bug
            storage.set(token, forKey: key)
        } else {
            do {
                let keychainItem = KeychainPasswordItem(service: self.storageKeys.authKeychainServiceName,
                                                        account: key)
                try keychainItem.savePassword(token)
            } catch {
                printLog(.warning, text: "failed saving token to keychain: \(error)")
            }
        }
    }

    internal func deleteToken(withKey key: String) throws {
        if isSimulator {
            // Falling back to saving token in UserDefaults because of simulator bug
            storage.removeObject(forKey: key)
        } else {
            do {
                let keychainItem = KeychainPasswordItem(service: self.storageKeys.authKeychainServiceName,
                                                        account: key)
                try keychainItem.deleteItem()
            } catch {
                printLog(.warning, text: "failed deleting auth token from keychain: \(error)")
                throw error
            }
        }
    }

    // MARK: Private
    internal func clearAuth() throws {
        authInfo = nil

        try deleteToken(withKey: self.storageKeys.authRefreshTokenKey)
        try deleteToken(withKey: self.storageKeys.authJwtKey)

        self.storage.set(false, forKey: self.storageKeys.isLoggedInUDKey)
        self.storage.removeObject(forKey: self.storageKeys.authProviderTypeUDKey)

        self.networkAdapter.cancelAllRequests()
    }

    internal func getAuthFromSavedJwt() throws -> AuthInfo {
        guard let isLoggedIn = storage.value(forKey: self.storageKeys.isLoggedInUDKey) as? Bool,
            isLoggedIn == true else {
            throw StitchError.unauthorized(message: "must be logged in")
        }

        do {
            if let authDicString = readToken(withKey: self.storageKeys.authJwtKey),
                let authDicData = authDicString.data(using: .utf8) {
                return try JSONDecoder().decode(AuthInfo.self, from: authDicData)
            }
        } catch {
            printLog(.error, text: "Failed reading auth token from keychain")
        }

        throw StitchError.unauthorized(message: "authorization failure")
    }

    private func readToken(withKey key: String) -> String? {
        if isSimulator {
            // Falling back to saving token in UserDefaults because of simulator bug
            return storage.value(forKey: key) as? String
        } else {
            do {
                let keychainItem = KeychainPasswordItem(service: self.storageKeys.authKeychainServiceName, account: key)
                let token = try keychainItem.readPassword()
                return token
            } catch {
                printLog(.warning, text: "failed reading auth token from keychain: \(error)")
                return nil
            }
        }
    }

    private var refreshToken: String? {
        guard isAuthenticated else {
            return nil
        }

        return readToken(withKey: self.storageKeys.authRefreshTokenKey)
    }

    private func refreshAccessToken() -> Promise<Void> {
        return doRequest {
            $0.method = .post
            $0.endpoint = "auth/session"
            $0.refreshOnFailure = false
            $0.useRefreshToken = true
        }.done { [weak self] (any: Any) throws in
            guard let strongSelf = self else {
                throw StitchError.clientReleased
            }

            guard let json = any as? [String: String],
                let accessToken = json["auth_info"],
                    let authInfo = strongSelf.authInfo else {
                        throw StitchError.unauthorized(message: "not authenticated")
                }

            strongSelf.authInfo = authInfo.auth(with: accessToken)
        }
    }

    private func refreshAccessTokenAndRetry(requestOptions: RequestOptions) -> Promise<Any> {
        return refreshAccessToken().then { [weak self] _ -> Promise<Any> in
            guard let strongSelf = self else {
                throw StitchError.clientReleased
            }

            return strongSelf.doRequest(with: requestOptions.builder)
        }
    }

    private func url(withEndpoint endpoint: String) -> String {
        return "\(baseUrl)\(apiPath)\(endpoint)"
    }

    internal typealias RequestBuilder = (inout RequestOptions) throws -> Void

    struct RequestOptions {
        var method: NAHTTPMethod = .get
        var endpoint: String = ""
        var isAuthenticatedRequest: Bool = true
        var refreshOnFailure: Bool = false
        var useRefreshToken: Bool = false
        var data: Data?
        var headers: [String: String]?

        let builder: RequestBuilder
        init(builder: @escaping RequestBuilder) throws {
            self.builder = builder
            try builder(&self)
        }

        mutating func encode(withJson json: [String: Any]) throws {
            self.data = try JSONSerialization.data(withJSONObject: json)
        }

        mutating func encode(withDocument doc: Document) throws {
            try encode(withData: doc)
        }

        mutating func encode<T: Encodable>(withData data: T) throws {
            self.data = try JSONEncoder().encode(data)
        }
    }

    @discardableResult
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    internal func doRequest(with requestBuilder: @escaping RequestBuilder) -> Promise<Any> {
        let requestOptions: RequestOptions

        do {
            requestOptions = try RequestOptions(builder: requestBuilder)
        } catch let err {
            return Promise.init(error: err)
        }

        if requestOptions.isAuthenticatedRequest && !isAuthenticated {
            return Promise.init(error: StitchError.unauthorized(message: "Must first authenticate"))
        }

        if requestOptions.isAuthenticatedRequest &&
            !requestOptions.useRefreshToken &&
            (self.isAccessTokenExpired() ?? false) {
            return self.refreshAccessTokenAndRetry(requestOptions: requestOptions)
        }

        var headers: [String: String]?
        if let requestOptionsHeaders = requestOptions.headers {
            headers = requestOptionsHeaders
        } else if requestOptions.isAuthenticatedRequest {
            let bearer = requestOptions.useRefreshToken ? refreshToken ??
                String() : authInfo?.accessToken?.token ?? String()
            headers = ["Authorization": "Bearer \(bearer)"]
        }

        let url: String = self.url(withEndpoint: requestOptions.endpoint)
        return networkAdapter.requestWithJsonEncoding(url: url,
                                                       method: requestOptions.method,
                                                       data: requestOptions.data,
                                                       headers: headers)
            .flatMap(on: DispatchQueue.global(qos: .default)) { [weak self] (args: (Int, Data?)) throws -> Any in
            guard let strongSelf = self else {
                throw StitchError.clientReleased
            }

            let (statusCode, value) = args
            if statusCode != 204 {
                guard let data = value,
                    let json = try? JSONSerialization.jsonObject(with: data,
                                                                 options: .allowFragments) else {
                    throw StitchError.responseParsingFailed(reason: "Received no valid data from server")
                }

                if let json = json as? [String: Any],
                    let error = strongSelf.parseError(from: json) {
                    switch error {
                    case .serverError(let reason):
                        // check if error is invalid session
                        if reason.isInvalidSession {
                            if requestOptions.refreshOnFailure {
                                return strongSelf.refreshAccessTokenAndRetry(requestOptions: requestOptions)
                            } else {
                                try? strongSelf.clearAuth()
                                throw error
                            }
                        } else {
                            throw error
                        }
                    default:
                        throw error
                    }
                }
                return json
            } else {
                return Data()
            }
        }
    }

    internal func parseError(from value: [String: Any]) -> StitchError? {
        guard let errMsg = value[Consts.ErrorKey] as? String else {
            return nil
        }

        printLog(.error, text: "request failed. error: \(errMsg)")

        if let errorCode = value["error_code"] as? String {
            return StitchError.serverError(reason: StitchError.ServerErrorReason(errorCode: errorCode,
                                                                                 errorMessage: errMsg))
        }

        return StitchError.serverError(reason: .other(message: errMsg))
    }
}
