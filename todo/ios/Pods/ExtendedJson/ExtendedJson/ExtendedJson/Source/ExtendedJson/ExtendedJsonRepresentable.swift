//
//  ExtendedJsonRepresentable.swift
//  ExtendedJson
//

import Foundation

public protocol ExtendedJsonRepresentable: Codable {
    static func fromExtendedJson(xjson: Any) throws -> ExtendedJsonRepresentable

    var toExtendedJson: Any { get }

    func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool
}

internal struct ExtendedJsonCodingKeys: CodingKey {
    var stringValue: String

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int?

    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = ""
    }

    static let info = ExtendedJsonCodingKeys(stringValue: "__$info__")!
}

extension ExtendedJsonRepresentable {
    internal static func encodeUnkeyedContainer(sourceMap: inout [Int: String],
                                                forKey key: Int,
                                                withValue value: ExtendedJsonRepresentable) throws -> (inout UnkeyedEncodingContainer) throws -> () {
        func setSourceKey<V>(_ xKey: String,
                             andEncode value: V?) throws -> (inout UnkeyedEncodingContainer) throws -> () where V: ExtendedJsonRepresentable {
            sourceMap[key] = xKey
            if let value = value {
                return { try $0.encode(value as V) }
            } else {
                return { try $0.encodeNil() }
            }
        }

        switch value {
        case let val as ObjectId: return try setSourceKey(ExtendedJsonKeys.objectid.rawValue, andEncode: val)
        case let val as Symbol: return try setSourceKey(ExtendedJsonKeys.symbol.rawValue, andEncode: val)
        case let val as Decimal: return try setSourceKey(ExtendedJsonKeys.numberDecimal.rawValue, andEncode: val)
        case let val as Double: return try setSourceKey(ExtendedJsonKeys.numberDouble.rawValue, andEncode: val)
        case let val as Int32: return try setSourceKey(ExtendedJsonKeys.numberInt.rawValue, andEncode: val)
        case let val as Int64: return try setSourceKey(ExtendedJsonKeys.numberLong.rawValue, andEncode: val)
        case let val as Int: return try setSourceKey(ExtendedJsonKeys.numberLong.rawValue, andEncode: val)
        case let val as RegularExpression: return try setSourceKey(ExtendedJsonKeys.regex.rawValue, andEncode: val)
        case let val as UUID: return try setSourceKey(ExtendedJsonKeys.binary.rawValue, andEncode: val)
        case let val as Date: return try setSourceKey(ExtendedJsonKeys.date.rawValue, andEncode: val)
        case let val as Binary: return try setSourceKey(ExtendedJsonKeys.binary.rawValue, andEncode: val)
        case let val as DBPointer: return try setSourceKey(ExtendedJsonKeys.dbPointer.rawValue, andEncode: val)
        case let val as Timestamp: return try setSourceKey(ExtendedJsonKeys.timestamp.rawValue, andEncode: val)
        case let val as DBRef: return try setSourceKey(ExtendedJsonKeys.dbRef.rawValue, andEncode: val)
        case let val as Undefined: return try setSourceKey(ExtendedJsonKeys.undefined.rawValue, andEncode: val)
        case let val as MaxKey: return try setSourceKey(ExtendedJsonKeys.maxKey.rawValue, andEncode: val)
        case let val as MinKey: return try setSourceKey(ExtendedJsonKeys.minKey.rawValue, andEncode: val)
        case let val as Code: return try setSourceKey(ExtendedJsonKeys.code.rawValue, andEncode: val)
        case let val as BSONArray: return try setSourceKey("__$arr__", andEncode: val)
        case let val as Document: return try setSourceKey("__$doc__", andEncode: val)
        case let val as String: return try setSourceKey("__$str__", andEncode: val)
        case let val as Bool: return try setSourceKey("__$bool__", andEncode: val)
        case let val as Null: return try setSourceKey("__$nil__", andEncode: val)
        default: throw BsonError<Document>.illegalArgument(message: "\(value) not of XJson type")
        }
    }

    internal static func encodeKeyedContainer<T>(to container: inout KeyedEncodingContainer<T>,
                                                 sourceMap: inout [String: String],
                                                 forKey key: T,
                                                 withValue value: ExtendedJsonRepresentable?) throws {
        func setSourceKey<V>(_ xKey: String,
                             andEncode value: V?) throws where V: ExtendedJsonRepresentable {
            sourceMap[key.stringValue] = xKey
            if let value = value {
                try container.encode(value as V, forKey: key)
            } else {
                try container.encodeNil(forKey: key)
            }
        }

        switch value {
        case let val as ObjectId: try setSourceKey(ExtendedJsonKeys.objectid.rawValue, andEncode: val)
        case let val as Symbol: try setSourceKey(ExtendedJsonKeys.symbol.rawValue, andEncode: val)
        case let val as Decimal: try setSourceKey(ExtendedJsonKeys.numberDecimal.rawValue, andEncode: val)
        case let val as Double: try setSourceKey(ExtendedJsonKeys.numberDouble.rawValue, andEncode: val)
        case let val as Int32: try setSourceKey(ExtendedJsonKeys.numberInt.rawValue, andEncode: val)
        case let val as Int64: try setSourceKey(ExtendedJsonKeys.numberLong.rawValue, andEncode: val)
        case let val as Int: try setSourceKey(ExtendedJsonKeys.numberLong.rawValue, andEncode: val)
        case let val as RegularExpression: try setSourceKey(ExtendedJsonKeys.regex.rawValue, andEncode: val)
        case let val as UUID: try setSourceKey(ExtendedJsonKeys.binary.rawValue, andEncode: val)
        case let val as Date: try setSourceKey(ExtendedJsonKeys.date.rawValue, andEncode: val)
        case let val as Binary: try setSourceKey(ExtendedJsonKeys.binary.rawValue, andEncode: val)
        case let val as DBPointer: try setSourceKey(ExtendedJsonKeys.dbPointer.rawValue, andEncode: val)
        case let val as Timestamp: try setSourceKey(ExtendedJsonKeys.timestamp.rawValue, andEncode: val)
        case let val as DBRef: try setSourceKey(ExtendedJsonKeys.dbRef.rawValue, andEncode: val)
        case let val as Undefined: try setSourceKey(ExtendedJsonKeys.undefined.rawValue, andEncode: val)
        case let val as MaxKey: try setSourceKey(ExtendedJsonKeys.maxKey.rawValue, andEncode: val)
        case let val as MinKey: try setSourceKey(ExtendedJsonKeys.minKey.rawValue, andEncode: val)
        case let val as Code: try setSourceKey(ExtendedJsonKeys.code.rawValue, andEncode: val)
        case let val as BSONArray: try setSourceKey("__$arr__", andEncode: val)
        case let val as Document: try setSourceKey("__$doc__", andEncode: val)
        case let val as String: try setSourceKey("__$str__", andEncode: val)
        case let val as Bool: try setSourceKey("__$bool__", andEncode: val)
        case let val as Null: try setSourceKey("__$nil__", andEncode: val)
        default: break
        }
    }

    internal static func decode(from container: inout UnkeyedDecodingContainer,
                                decodingTypeString: String) throws -> ExtendedJsonRepresentable {
        func decode<V>(_ type: V.Type) throws -> V where V: ExtendedJsonRepresentable {
            return try container.decode(type)
        }
        switch decodingTypeString {
        case ExtendedJsonKeys.objectid.rawValue: return try decode(ObjectId.self)
        case ExtendedJsonKeys.symbol.rawValue: return try decode(Symbol.self)
        case ExtendedJsonKeys.numberDecimal.rawValue: return try decode(Decimal.self)
        case ExtendedJsonKeys.numberInt.rawValue: return try decode(Int.self)
        case ExtendedJsonKeys.numberLong.rawValue: return try decode(Int64.self)
        case ExtendedJsonKeys.numberDouble.rawValue: return try decode(Double.self)
        case ExtendedJsonKeys.timestamp.rawValue: return try decode(Timestamp.self)
        case ExtendedJsonKeys.dbPointer.rawValue: return try decode(DBPointer.self)
        case ExtendedJsonKeys.regex.rawValue: return try decode(RegularExpression.self)
        case ExtendedJsonKeys.date.rawValue: return try decode(Date.self)
        case ExtendedJsonKeys.binary.rawValue: return try decode(Binary.self)
        case ExtendedJsonKeys.undefined.rawValue: return try decode(Undefined.self)
        case ExtendedJsonKeys.minKey.rawValue: return try decode(MinKey.self)
        case ExtendedJsonKeys.maxKey.rawValue: return try decode(MaxKey.self)
        case ExtendedJsonKeys.dbRef.rawValue: return try decode(DBRef.self)
        case ExtendedJsonKeys.code.rawValue: return try decode(Code.self)
        case "__$arr__": return try decode(BSONArray.self)
        case "__$doc__": return try decode(Document.self)
        case "__$str__": return try decode(String.self)
        case "__$bool__": return try decode(Bool.self)
        case "__$nil__": return try decode(Null.self)
        default: throw BsonError<Document>.illegalArgument(message: "unknown key found while decoding bson: \(decodingTypeString)")
        }
    }

    internal static func decode<T>(from container: KeyedDecodingContainer<T>,
                                   decodingTypeString: String,
                                   forKey key: T) throws -> ExtendedJsonRepresentable {
        func decode<V>(_ type: V.Type) throws -> V where V: ExtendedJsonRepresentable {
            return try container.decode(type, forKey: key)
        }

        switch decodingTypeString {
        case ExtendedJsonKeys.objectid.rawValue: return try decode(ObjectId.self)
        case ExtendedJsonKeys.symbol.rawValue: return try decode(Symbol.self)
        case ExtendedJsonKeys.numberDecimal.rawValue: return try decode(Decimal.self)
        case ExtendedJsonKeys.numberInt.rawValue: return try decode(Int.self)
        case ExtendedJsonKeys.numberLong.rawValue: return try decode(Int64.self)
        case ExtendedJsonKeys.numberDouble.rawValue: return try decode(Double.self)
        case ExtendedJsonKeys.timestamp.rawValue: return try decode(Timestamp.self)
        case ExtendedJsonKeys.dbPointer.rawValue: return try decode(DBPointer.self)
        case ExtendedJsonKeys.regex.rawValue: return try decode(RegularExpression.self)
        case ExtendedJsonKeys.date.rawValue: return try decode(Date.self)
        case ExtendedJsonKeys.binary.rawValue: return try decode(Binary.self)
        case ExtendedJsonKeys.undefined.rawValue: return try decode(Undefined.self)
        case ExtendedJsonKeys.minKey.rawValue: return try decode(MinKey.self)
        case ExtendedJsonKeys.maxKey.rawValue: return try decode(MaxKey.self)
        case ExtendedJsonKeys.dbRef.rawValue: return try decode(DBRef.self)
        case ExtendedJsonKeys.code.rawValue: return try decode(Code.self)
        case "__$arr__": return try decode(BSONArray.self)
        case "__$doc__": return try decode(Document.self)
        case "__$str__": return try decode(String.self)
        case "__$bool__": return try decode(Bool.self)
        case "__$nil__": return try decode(Null.self)
        default: throw BsonError<Document>.illegalArgument(message: "unknown key found while decoding bson: \(decodingTypeString)")
        }
    }

    public static func decodeXJson(value: Any?) throws -> ExtendedJsonRepresentable {
        switch (value) {
        case let json as [String: Any]:
            if json.count == 0 {
                return Document()
            }

            var iterator = json.makeIterator()
            while let next = iterator.next() {
                if let key = ExtendedJsonKeys(rawValue: next.key) {
                    switch (key) {
                    case .objectid: return try ObjectId.fromExtendedJson(xjson: json)
                    case .numberInt: return try Int32.fromExtendedJson(xjson: json)
                    case .numberLong: return try Int64.fromExtendedJson(xjson: json)
                    case .numberDouble: return try Double.fromExtendedJson(xjson: json)
                    case .numberDecimal: return try Decimal.fromExtendedJson(xjson: json)
                    case .date: return try Date.fromExtendedJson(xjson: json)
                    case .binary: return try Binary.fromExtendedJson(xjson: json)
                    case .timestamp: return try Timestamp.fromExtendedJson(xjson: json)
                    case .regex: return try RegularExpression.fromExtendedJson(xjson: json)
                    case .dbRef: return try DBRef.fromExtendedJson(xjson: json)
                    case .minKey: return try MinKey.fromExtendedJson(xjson: json)
                    case .maxKey: return try MaxKey.fromExtendedJson(xjson: json)
                    case .undefined: return try Undefined.fromExtendedJson(xjson: json)
                    case .code: return try Code.fromExtendedJson(xjson: json)
                    case .symbol: return try Symbol.fromExtendedJson(xjson: json)
                    case .dbPointer: return try DBPointer.fromExtendedJson(xjson: json)
                    }
                }
            }

            return try Document(extendedJson: json)
        case is NSNull, nil:
            return try Null.fromExtendedJson(xjson: NSNull())
        case is [Any]:
            return try BSONArray.fromExtendedJson(xjson: value!)
        case is String:
            return try String.fromExtendedJson(xjson: value!)
        case is Bool:
            return try Bool.fromExtendedJson(xjson: value!)
        case let value as ExtendedJsonRepresentable:
            return value
        default:
            throw BsonError.parseValueFailure(value: value, attemptedType: Document.self)
        }
    }
}

// MARK: - Helpers
internal enum ExtendedJsonKeys: String {
    case objectid = "$oid",
    symbol = "$symbol",
    numberInt = "$numberInt",
    numberLong = "$numberLong",
    numberDouble = "$numberDouble",
    numberDecimal = "$numberDecimal",
    date = "$date",
    binary = "$binary",
    code = "$code",
    timestamp = "$timestamp",
    regex = "$regularExpression",
    dbPointer = "$dbPointer",
    dbRef = "$ref",
    minKey = "$minKey",
    maxKey = "$maxKey",
    undefined = "$undefined"
}

// MARK: ISO8601

internal extension DateFormatter {

    static let iso8601DateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
}
