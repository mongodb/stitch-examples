//
//  Decimal+ExtendedJson.swift
//  ExtendedJson
//
//  Created by Jason Flax on 10/3/17.
//  Copyright © 2017 MongoDB. All rights reserved.
//

import Foundation

extension Decimal: ExtendedJsonRepresentable {
    public static func fromExtendedJson(xjson: Any) throws -> ExtendedJsonRepresentable {
        guard let json = xjson as? [String: Any],
            let decimalString = json[ExtendedJsonKeys.numberDecimal.rawValue] as? String,
            let decimal = Decimal(string: decimalString),
            json.count == 1 else {
                throw BsonError.parseValueFailure(value: xjson, attemptedType: Decimal.self)
        }

        return decimal
    }

    public var toExtendedJson: Any {
        return [ExtendedJsonKeys.numberDecimal.rawValue: String(describing: self)]
    }

    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? Decimal {
            return self == other
        }
        return false
    }
}
