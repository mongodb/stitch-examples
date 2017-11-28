//
//  String+ExtendedJson.swift
//  ExtendedJson
//
//  Created by Jason Flax on 10/3/17.
//  Copyright © 2017 MongoDB. All rights reserved.
//

import Foundation

extension String: ExtendedJsonRepresentable {
    public static func fromExtendedJson(xjson: Any) throws -> ExtendedJsonRepresentable {
        guard let string = xjson as? String else {
            throw BsonError.parseValueFailure(value: xjson, attemptedType: String.self)
        }

        return string
    }

    public var toExtendedJson: Any {
        return self
    }

    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? String {
            return self == other
        }
        return false
    }
}
