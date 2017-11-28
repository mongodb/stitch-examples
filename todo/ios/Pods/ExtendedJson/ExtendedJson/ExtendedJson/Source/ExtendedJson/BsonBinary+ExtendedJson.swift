//
//  BsonBinary+ExtendedJson.swift
//  ExtendedJson
//
//  Created by Jason Flax on 10/3/17.
//  Copyright © 2017 MongoDB. All rights reserved.
//

import Foundation

extension Binary: ExtendedJsonRepresentable {
    enum CodingKeys: String, CodingKey {
        case binary = "$binary", base64, subType
    }

    fileprivate init(typeString: String, base64String: String) throws {
        let fixedTypeString = typeString.hasHexadecimalPrefix() ?
            String(typeString.characters.dropFirst(2)) : typeString
        guard let data = Data(base64Encoded: base64String),
            let typeInt = UInt8(fixedTypeString, radix: 16),
            let type = BsonBinarySubType(rawValue: typeInt) else {
                throw BsonError.parseValueFailure(value: base64String,
                                                  attemptedType: Binary.self)
        }

        self.init(type: type, data: [UInt8](data))
    }

    public static func fromExtendedJson(xjson: Any) throws -> ExtendedJsonRepresentable {
        guard let json = xjson as? [String: Any],
            let binaryJson = json[ExtendedJsonKeys.binary.rawValue] as? [String: String],
            let base64String = binaryJson["base64"],
            let typeString = binaryJson["subType"],
            binaryJson.count == 2 else {
                throw BsonError.parseValueFailure(value: xjson, attemptedType: Binary.self)
        }

        return try Binary(typeString: typeString, base64String: base64String)
    }

    public var toExtendedJson: Any {
        let base64String = Data(bytes: data).base64EncodedString()
        let type = String(self.type.rawValue, radix: 16)
        return [
            ExtendedJsonKeys.binary.rawValue: [
                "base64": base64String,
                "subType": "0x\(type)"
            ]
        ]
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nestedContainer = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                            forKey: CodingKeys.binary)
        try self.init(typeString: nestedContainer.decode(String.self,
                                                         forKey: CodingKeys.subType),
                      base64String: nestedContainer.decode(String.self,
                                                           forKey: CodingKeys.base64))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var nestedContainer = container.nestedContainer(keyedBy: CodingKeys.self,
                                                        forKey: CodingKeys.binary)
        let base64String = Data(bytes: data).base64EncodedString()
        let type = String(self.type.rawValue, radix: 16)
        try nestedContainer.encode(base64String, forKey: CodingKeys.base64)
        try nestedContainer.encode("0x\(type)", forKey: CodingKeys.subType)
    }

    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        func _compare(b1: [UInt8], b2: [UInt8]) -> Bool {
            for i in 0..<b2.count {
                if b1[i] != b2[i] {
                    return false
                }
            }
            return true
        }

        if let other = other as? Binary {
            return _compare(b1: self.data, b2: other.data)
        } else if let other = other as? UUID {
            return _compare(b1: self.data, b2: other.toBsonBinary.data)
        }
        return false
    }
}
