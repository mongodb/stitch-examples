// The following code was copied in part from github.com/auth0/JWTDecode.swift and
// modified significantly for use in this SDK under the terms of the following license:
//
//    The MIT License (MIT)
//
//    Copyright (c) 2014 Auth0, Inc. <support@auth0.com> (http://auth0.com)
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

import Foundation

public struct DecodedJWT: Codable {
    let payload: [String: Any]
    let token: String

    init(jwt: String) throws {
        do {
            self.token = jwt
            self.payload = try DecodedJWT.jwtDecodePayload(jwt: jwt)
        } catch let error as DecodeError {
            throw error
        }
    }

    public init(from decoder: Decoder) throws {
        try self.init(jwt: decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.token)
    }

    public var expiration: Date? {
        guard let exp = self.payload["exp"] else {
            return nil
        }

        guard let timestamp: TimeInterval = exp as? TimeInterval else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }

    public enum DecodeError: LocalizedError {
        case invalidBase64Url(String)
        case invalidJSON(String)
        case invalidPartCount(String, Int)

        public var localizedDescription: String {
            switch self {
            case .invalidJSON(let value):
                return NSLocalizedString("Malformed jwt token, failed to parse JSON value from base64Url \(value)",
                                        comment: "Invalid JSON value inside base64Url")
            case .invalidPartCount(let jwt, let parts):
                return NSLocalizedString("Malformed jwt token \(jwt) has \(parts) parts when it should have 3 parts",
                                        comment: "Invalid amount of jwt parts")
            case .invalidBase64Url(let value):
                return NSLocalizedString("Malformed jwt token, failed to decode base64Url value \(value)",
                                        comment: "Invalid JWT token base64Url value")
            }
        }
    }

    private static func jwtDecodePayload(jwt: String) throws -> [String: Any] {
        let parts = jwt.components(separatedBy: ".")
        guard parts.count == 3 else {
            throw DecodeError.invalidPartCount(jwt, parts.count)
        }

        return try decodeJWTPart(parts[1])
    }

    private static func decodeJWTPart(_ value: String) throws -> [String: Any] {
        guard let bodyData = base64UrlDecode(value) else {
            throw DecodeError.invalidBase64Url(value)
        }

        guard let json = try? JSONSerialization.jsonObject(with: bodyData, options: []),
            let payload = json as? [String: Any] else {
            throw DecodeError.invalidJSON(value)
        }

        return payload
    }

    private static func base64UrlDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            base64 += padding
        }
        return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
    }
}
