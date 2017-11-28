//
//  Date+ExtenedJson.swift
//  ExtendedJson
//
//  Created by Jason Flax on 10/3/17.
//  Copyright © 2017 MongoDB. All rights reserved.
//

import Foundation

extension Date: ExtendedJsonRepresentable {
    public static func fromExtendedJson(xjson: Any) throws -> ExtendedJsonRepresentable {
        guard let json = xjson as? [String: Any],
            let dateJson = json[ExtendedJsonKeys.date.rawValue] as? [String: String],
            let dateString = dateJson[ExtendedJsonKeys.numberLong.rawValue],
            let dateNum = Double(dateString),
            dateJson.count == 1 else {
                throw BsonError.parseValueFailure(value: xjson, attemptedType: Date.self)
        }

        return Date(timeIntervalSince1970: dateNum)
    }

    public var toExtendedJson: Any {
        return [
            ExtendedJsonKeys.date.rawValue: [
                ExtendedJsonKeys.numberLong.rawValue: String(Double(timeIntervalSince1970 * 1000))
            ]
        ]
    }

    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? Date {
            return self == other
        }
        return false
    }
}
