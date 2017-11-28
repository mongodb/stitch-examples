//
//  Double+ExtendedJson.swift
//  ExtendedJson
//
//  Created by Jason Flax on 10/3/17.
//  Copyright © 2017 MongoDB. All rights reserved.
//

import Foundation

extension Double: ExtendedJsonRepresentable {
    enum CodingKeys: String, CodingKey {
        case numberDouble = "$numberDouble"
    }

    public static func fromExtendedJson(xjson: Any) throws -> ExtendedJsonRepresentable {
        guard let json = xjson as? [String: Any],
            let value = json[ExtendedJsonKeys.numberDouble.rawValue] as? String,
            let doubleValue = Double(value),
            json.count == 1 else {
                throw BsonError.parseValueFailure(value: xjson, attemptedType: Double.self)
        }

        return doubleValue
    }

    public var toExtendedJson: Any {
        return [ExtendedJsonKeys.numberDouble.rawValue: String(self)]
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(try container.decode(Double.self, forKey: CodingKeys.numberDouble))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self, forKey: CodingKeys.numberDouble)
    }

    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? Double {
            return self == other || (self.isNaN && other.isNaN)
        }

        return false
    }
}
