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

internal class StitchHTTPClient {
    internal let userDefaults = UserDefaults(suiteName: Consts.UserDefaultsName)

    internal var isSimulator: Bool {
        /*
         This is computed in a separate variable due to a compiler warning when the check
         is done directly inside the 'if' statement, indicating that either the 'if'
         block or the 'else' block will never be executed - depending whether the build
         target is a simulator or a device.
         */
        return TARGET_OS_SIMULATOR != 0
    }

    let baseUrl, appId: String
    let networkAdapter: NetworkAdapter
    internal var authInfo: AuthInfo?

    init(baseUrl: String, appId: String, networkAdapter: NetworkAdapter) {
        self.baseUrl = baseUrl
        self.appId = appId
        self.networkAdapter = networkAdapter
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
            printLog(.debug, text: "Falling back to saving token in UserDefaults because of simulator bug")
            userDefaults?.set(token, forKey: key)
        } else {
            do {
                let keychainItem = KeychainPasswordItem(service: Consts.AuthKeychainServiceName, account: key)
                try keychainItem.savePassword(token)
            } catch {
                printLog(.warning, text: "failed saving token to keychain: \(error)")
            }
        }
    }

    internal func deleteToken(withKey key: String) throws {
        if isSimulator {
            printLog(.debug, text: "Falling back to deleting token from UserDefaults because of simulator bug")
            userDefaults?.removeObject(forKey: key)
        } else {
            do {
                let keychainItem = KeychainPasswordItem(service: Consts.AuthKeychainServiceName, account: key)
                try keychainItem.deleteItem()
            } catch {
                printLog(.warning, text: "failed deleting auth token from keychain: \(error)")
                throw error
            }
        }
    }

    // MARK: Private
    internal func clearAuth() throws {
        guard authInfo != nil else {
            return
        }

        authInfo = nil

        try deleteToken(withKey: Consts.AuthRefreshTokenKey)

        self.networkAdapter.cancelAllRequests()
    }

    internal func getAuthFromSavedJwt() throws -> AuthInfo {
        guard userDefaults?.bool(forKey: Consts.IsLoggedInUDKey) == true else {
            throw StitchError.unauthorized(message: "must be logged in")
        }

        do {
            if let authDicString = readToken(withKey: Consts.AuthJwtKey),
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
            printLog(.debug, text: "Falling back to reading token from UserDefaults because of simulator bug")
            return userDefaults?.object(forKey: key) as? String
        } else {
            do {
                let keychainItem = KeychainPasswordItem(service: Consts.AuthKeychainServiceName, account: key)
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

        return readToken(withKey: Consts.AuthRefreshTokenKey)
    }

    private func refreshAccessToken() -> StitchTask<Void> {
        return doRequest {
            $0.method = .post
            $0.endpoint = "auth/session"
            $0.refreshOnFailure = false
            $0.useRefreshToken = true
        }.then(parser: { [weak self] (any) -> Void in
            guard let strongSelf = self else {
                throw StitchError.clientReleased
            }

            guard let json = any as? [String: String],
                let accessToken = json["auth_info"],
                    let authInfo = strongSelf.authInfo else {
                        throw StitchError.unauthorized(message: "not authenticated")
                }

            strongSelf.authInfo = authInfo.auth(with: accessToken)
        })
    }

    private func refreshAccessTokenAndRetry(requestOptions: RequestOptions,
                                            task: StitchTask<Any>) {
        refreshAccessToken().response(onQueue: DispatchQueue.global(qos: .utility)) { [weak self] (innerTask) in
            guard let strongSelf = self else {
                task.result = StitchResult.failure(StitchError.clientReleased)
                return
            }

            switch innerTask.result {
            case .failure(let error):
                task.result = .failure(error)
            case .success:
                // retry once
                strongSelf.doRequest(with: requestOptions.builder)
                    .response(onQueue: DispatchQueue.global(qos: .utility)) { innerTask in
                        switch innerTask.result {
                        case .failure(let error):
                            task.result = .failure(error)
                        case .success(let value):
                            task.result = .success(value)
                        }
                }
            }
        }
    }

    private func url(withEndpoint endpoint: String) -> String {
        return "\(baseUrl)\(Consts.ApiPath)\(endpoint)"
    }

    internal typealias RequestBuilder = (inout RequestOptions) throws -> Void

    struct RequestOptions {
        var method: NAHTTPMethod = .get
        var endpoint: String = ""
        var isAuthenticatedRequest: Bool = true
        var refreshOnFailure: Bool = false
        var useRefreshToken: Bool = false
        var parameters: Document = [:]

        let builder: RequestBuilder
        init(builder: @escaping RequestBuilder) throws {
            self.builder = builder
            try builder(&self)
        }
    }

    @discardableResult
    internal func doRequest(with requestBuilder: @escaping RequestBuilder) -> StitchTask<Any> {
        let task = StitchTask<Any>()
        let requestOptions: RequestOptions
        do {
            requestOptions = try RequestOptions(builder: requestBuilder)
        } catch let err {
            task.result = .failure(err)
            return task
        }

        if requestOptions.isAuthenticatedRequest && !isAuthenticated {
            task.result = .failure(StitchError.unauthorized(message: "Must first authenticate"))
            return task
        }

        if requestOptions.isAuthenticatedRequest && !requestOptions.useRefreshToken && (self.isAccessTokenExpired() ?? false) {
            self.refreshAccessTokenAndRetry(requestOptions: requestOptions,
                                            task: task)
            return task
        }

        let bearer = requestOptions.useRefreshToken ? refreshToken ?? String() : authInfo?.accessToken?.token ?? String()
        let url: String = self.url(withEndpoint: requestOptions.endpoint)
        networkAdapter.requestWithJsonEncoding(url: url,
                                               method: requestOptions.method,
                                               parameters: requestOptions.parameters,
                                               headers: requestOptions.isAuthenticatedRequest ?
                                                ["Authorization": "Bearer \(bearer)"] : nil)
            .response(onQueue: DispatchQueue.global(qos: .default),
                      completionHandler: { [weak self] internalTask in
                    guard let strongSelf = self else {
                        task.result = StitchResult.failure(StitchError.clientReleased)
                        return
                    }

                    switch internalTask.result {
                    case .success(let args):
                        let (statusCode, value) = args
                        if statusCode != 204 {
                            guard let data = value,
                                let json = try? JSONSerialization.jsonObject(with: data,
                                                                             options: .allowFragments) else {
                                    return task.result = .failure(
                                        StitchError.responseParsingFailed(reason: "Received no valid data from server"))
                            }

                            if let json = json as? [String: Any], let error = strongSelf.parseError(from: json) {
                                switch error {
                                case .serverError(let reason):
                                    // check if error is invalid session
                                    if reason.isInvalidSession {
                                        if requestOptions.refreshOnFailure {
                                            strongSelf.refreshAccessTokenAndRetry(requestOptions: requestOptions,
                                                                                  task: task)
                                        } else {
                                            try? strongSelf.clearAuth()
                                            task.result = .failure(error)
                                        }
                                    } else {
                                        task.result = .failure(error)
                                    }
                                default:
                                    task.result = .failure(error)
                                }
                                return
                            }
                            task.result = .success(json)
                        } else {
                            task.result = .success(Data())
                        }
                    case .failure(let error):
                        task.result = .failure(error)
                    }
            })

        return task
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
