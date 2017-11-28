//
//  NSNull+ExtendedJson.swift
//  ExtendedJson
//
//  Created by Jason Flax on 10/3/17.
//  Copyright © 2017 MongoDB. All rights reserved.
//

import Foundation

public final class Null: NSNull, ExtendedJsonRepresentable {
    public static func fromExtendedJson(xjson: Any) throws -> ExtendedJsonRepresentable {
        guard let _ = xjson as? NSNull else {
            throw BsonError.parseValueFailure(value: xjson, attemptedType: NSNull.self)
        }

        return Null()
    }

    public var toExtendedJson: Any {
        return self
    }

    public override init() { super.init() }

    public init(from decoder: Decoder) throws {
        super.init()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }

    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? NSNull {
            return self == other
        }
        return false
    }
}
