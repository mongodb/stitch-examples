//
//  MaxKey+ExtendedJson.swift
//  ExtendedJson
//
//  Created by Jason Flax on 10/4/17.
//  Copyright © 2017 MongoDB. All rights reserved.
//

import Foundation

extension MaxKey: ExtendedJsonRepresentable {
    enum CodingKeys: String, CodingKey {
        case maxKey = "$maxKey"
    }

    public static func fromExtendedJson(xjson: Any) throws -> ExtendedJsonRepresentable {
        guard let json = xjson as? [String: Any],
            let maxKey = json[ExtendedJsonKeys.maxKey.rawValue] as? Int,
            maxKey == 1,
            json.count == 1 else {
                throw BsonError.parseValueFailure(value: xjson, attemptedType: MaxKey.self)
        }

        return MaxKey()
    }

    public var toExtendedJson: Any {
        return [ExtendedJsonKeys.maxKey.rawValue: 1]
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // assert that this was encoding properly
        guard let max = try? container.decode(Int.self, forKey: CodingKeys.maxKey),
            max == 1 else {
            throw DecodingError.dataCorruptedError(forKey: CodingKeys.maxKey,
                                                   in: container,
                                                   debugDescription: "Max key was not encoded correctly")
        }
        self.init()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(1, forKey: CodingKeys.maxKey)
    }

    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? MaxKey {
            return self == other
        }
        return false
    }
}
