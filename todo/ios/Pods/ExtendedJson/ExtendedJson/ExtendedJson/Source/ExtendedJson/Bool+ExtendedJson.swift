//
//  Bool+ExtendedJson.swift
//  ExtendedJson
//
//  Created by Jason Flax on 10/4/17.
//  Copyright © 2017 MongoDB. All rights reserved.
//

import Foundation

extension Bool: ExtendedJsonRepresentable {
    public static func fromExtendedJson(xjson: Any) throws -> ExtendedJsonRepresentable {
        guard let bool = xjson as? Bool else {
            throw BsonError.parseValueFailure(value: xjson, attemptedType: Bool.self)
        }

        return bool
    }

    public var toExtendedJson: Any {
        return self
    }

    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? Bool {
            return self == other
        }
        return false
    }
}
