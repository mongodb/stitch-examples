//
//  BsonTimestamp+ExtendedJson.swift
//  ExtendedJson
//
//  Created by Jason Flax on 10/3/17.
//  Copyright © 2017 MongoDB. All rights reserved.
//

import Foundation

extension Timestamp: ExtendedJsonRepresentable {
    enum CodingKeys: String, CodingKey {
        case timestamp = "$timestamp", t, i
    }
    public static func fromExtendedJson(xjson: Any) throws -> ExtendedJsonRepresentable {
        guard let json = xjson as? [String: Any],
            let timestampJson = json[ExtendedJsonKeys.timestamp.rawValue] as? [String: Int64],
            let timestamp = timestampJson["t"],
            let increment = timestampJson["i"],
            timestampJson.count == 2 else {
                throw BsonError.parseValueFailure(value: xjson, attemptedType: Timestamp.self)
        }

        return Timestamp(time: TimeInterval(timestamp), increment: Int(increment))
    }

    public var toExtendedJson: Any {
        return [
            ExtendedJsonKeys.timestamp.rawValue: [
                "t": Int64(self.time.timeIntervalSince1970),
                "i": increment
            ]
        ]
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nestedContainer = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                            forKey: CodingKeys.timestamp)

        self.init(time: TimeInterval(try nestedContainer.decode(Int64.self, forKey: CodingKeys.t)),
                  increment: try nestedContainer.decode(Int.self, forKey: CodingKeys.i))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var nestedContainer = container.nestedContainer(keyedBy: CodingKeys.self,
                                                        forKey: CodingKeys.timestamp)

        try nestedContainer.encode(Int64(self.time.timeIntervalSince1970), forKey: CodingKeys.t)
        try nestedContainer.encode(increment, forKey: CodingKeys.i)
    }

    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? Timestamp {
            return self == other
        }
        return false
    }
}
