//
//  UUID+ExtendedJsonRepresentable.swift
//  ExtendedJson
//
//  Created by Jason Flax on 10/6/17.
//  Copyright © 2017 MongoDB. All rights reserved.
//

import Foundation

extension UUID: ExtendedJsonRepresentable {
    public static func fromExtendedJson(xjson: Any) throws -> ExtendedJsonRepresentable {
        guard let json = xjson as? [String: Any],
            let binary = json[ExtendedJsonKeys.binary.rawValue] as? [String: String],
            let base64 = binary["base64"],
            let subType = binary["subType"],
            BsonBinarySubType.uuid.rawValue == UInt8(subType),
            let data = Data(base64Encoded: base64) else {
                throw BsonError.parseValueFailure(value: xjson, attemptedType: UUID.self)
        }

        return UUID(uuid: uuid_t(
            data[0], data[1], data[2], data[3], data[4],
            data[5], data[6], data[7], data[8], data[9],
            data[10], data[11], data[12], data[13], data[14], data[15]
        ))
    }

    public var toBsonBinary: Binary {
        return Binary(type: BsonBinarySubType.uuid, data: [uuid.0, uuid.1, uuid.2, uuid.3, uuid.4,
                                                               uuid.5, uuid.6, uuid.7, uuid.8, uuid.9,
                                                               uuid.10, uuid.11, uuid.12, uuid.13, uuid.14, uuid.15])
    }

    public var toExtendedJson: Any {
        return [
            ExtendedJsonKeys.binary.rawValue: [
                "base64": Data(bytes:
                    [uuid.0, uuid.1, uuid.2, uuid.3, uuid.4,
                     uuid.5, uuid.6, uuid.7, uuid.8, uuid.9,
                     uuid.10, uuid.11, uuid.12, uuid.13, uuid.14, uuid.15]
                    ).base64EncodedString(),
                "subType": String(describing: BsonBinarySubType.uuid)
            ]
        ]
    }

    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        return (other is UUID && (other as! UUID).uuidString == self.uuidString) ||
            (other is Binary && (other as! Binary).isEqual(toOther: self.toBsonBinary))
    }
}
