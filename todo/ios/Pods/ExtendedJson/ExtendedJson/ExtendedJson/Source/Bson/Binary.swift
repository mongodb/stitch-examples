//
//  BsonBinary.swift
//  ExtendedJson
//

import Foundation

/// A representation of the BSON Binary type.
public struct Binary {

    public private(set) var type: BsonBinarySubType
	public private(set) var data: [UInt8]

    public init(type: BsonBinarySubType = .binary, data: [UInt8]) {
        self.type = type
        self.data = data
    }
}

// MARK: - Equatable
extension Binary: Equatable {
    public static func ==(lhs: Binary, rhs: Binary) -> Bool {
        return lhs.type == rhs.type && lhs.data == rhs.data
    }
}

public enum BsonBinarySubType: UInt8 {

    /// Binary data.
    case binary = 0x00

    /// A function.
    case function = 0x01

    /// Old binary.
    case oldBinary = 0x02

    /// A UUID in a driver dependent legacy byte order.
    case uuidLegacy = 0x03

    /// A UUID in standard network byte order.
    case uuid = 0x04

    /// MD5 Hash.
    case md5 = 0x05

    /// User defined binary data.
    case userDefined = 0x80
}
