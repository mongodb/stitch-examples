//
//  Int+ExtendedJson.swift
//  ExtendedJson
//
//  Created by Jason Flax on 10/3/17.
//  Copyright © 2017 MongoDB. All rights reserved.
//

import Foundation

extension Int: ExtendedJsonRepresentable {
    public static func fromExtendedJson(xjson: Any) throws -> ExtendedJsonRepresentable {
        guard let json = xjson as? [String: Any] else {
            throw BsonError.parseValueFailure(value: xjson, attemptedType: Int.self)
        }

        if let value = json[ExtendedJsonKeys.numberInt.rawValue] as? String,
            let intValue = Int(value) {
            return intValue
        } else if let value = json[ExtendedJsonKeys.numberLong.rawValue] as? String,
                let intValue = Int(value) {
            return intValue
        }

        throw BsonError.parseValueFailure(value: xjson, attemptedType: Int.self)
    }

    public var toExtendedJson: Any {
        // check if we're on a 32-bit or 64-bit platform and act accordingly
        if MemoryLayout<Int>.size == MemoryLayout<Int32>.size {
            let int32: Int32 = Int32(self)
            return int32.toExtendedJson
        }

        let int64: Int64 = Int64(self)
        return int64.toExtendedJson
    }

    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? Int {
            return self == other
        } else if let other = other as? Int32 {
            return self == other
        } else if let other = other as? Int64 {
            return self == other
        }
        return false
    }
}

extension Int32: ExtendedJsonRepresentable {
    public static func fromExtendedJson(xjson: Any) throws -> ExtendedJsonRepresentable {
        guard let json = xjson as? [String: Any],
            let value = json[ExtendedJsonKeys.numberInt.rawValue] as? String,
            let int32Value = Int32(value) else {
                throw BsonError.parseValueFailure(value: xjson, attemptedType: Int32.self)
        }

        return int32Value
    }

    public var toExtendedJson: Any {
        return [ExtendedJsonKeys.numberInt.rawValue: String(self)]
    }

    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? Int32 {
            return self == other
        } else if let other = other as? Int {
            return self == other
        }
        return false
    }
}

extension Int64: ExtendedJsonRepresentable {
    enum CodingKeys: String,CodingKey {
        case numberLong = "$numberLong"
    }
    public static func fromExtendedJson(xjson: Any) throws -> ExtendedJsonRepresentable {
        guard let json = xjson as? [String: Any],
            let value = json[ExtendedJsonKeys.numberLong.rawValue] as? String,
            let int64Value = Int64(value) else {
                throw BsonError.parseValueFailure(value: xjson, attemptedType: Int64.self)
        }

        return int64Value
    }

    public var toExtendedJson: Any {
        return [ExtendedJsonKeys.numberLong.rawValue: String(self)]
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(try container.decode(Double.self, forKey: CodingKeys.numberLong))
    }

    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? Int64 {
            return self == other
        } else if let other = other as? Int {
            return self == other
        }
        return false
    }
}
