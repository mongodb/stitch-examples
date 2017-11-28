//
//  ObjectId+ExtendedJson.swift
//  ExtendedJson
//
//  Created by Jason Flax on 10/3/17.
//  Copyright © 2017 MongoDB. All rights reserved.
//

import Foundation

extension ObjectId: ExtendedJsonRepresentable {
    enum CodingKeys: String, CodingKey {
        case oid = "$oid"
    }

    public static func fromExtendedJson(xjson: Any) throws -> ExtendedJsonRepresentable {
        guard let json = xjson as? [String: Any],
            let value = json[ExtendedJsonKeys.objectid.rawValue] as? String,
            json.count == 1 else {
                throw BsonError.parseValueFailure(value: xjson, attemptedType: ObjectId.self)
        }

        return try ObjectId(hexString: value)
    }

    public var toExtendedJson: Any {
        return [ExtendedJsonKeys.objectid.rawValue: hexString]
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(hexString: try container.decode(String.self, forKey: CodingKeys.oid))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hexString, forKey: CodingKeys.oid)
    }

    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? ObjectId {
            return self == other
        }
        return false
    }
}
