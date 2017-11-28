//
//  Coders.swift
//  ExtendedJson
//
//  Created by Jason Flax on 10/24/17.
//  Copyright © 2017 MongoDB. All rights reserved.
//

import Foundation

fileprivate let positiveInfinity = "∞"
fileprivate let negativeInfinity = "-∞"
fileprivate let nan = "NaN"

fileprivate func unwrap<T>(_ value: T?, codingPath: [CodingKey]) throws -> T {
    guard let value = value else {
        throw DecodingError.valueNotFound(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Value of type \(T.self) was not found"))
    }

    return value
}

public class BSONEncoder {
    struct CodingKeys {
        static let shouldIncludeSourceMap = CodingUserInfoKey(rawValue: "withSourceMap")!
    }

    public func encode(_ value: Encodable) throws -> Document {
        let encoder = _BSONEncoder()
        try value.encode(to: encoder)

        return encoder.target.document
    }

    public func encode<T>(_ value: T,
                          shouldIncludeSourceMap: Bool) throws -> Data where T : Encodable {
        let encoder = JSONEncoder()
        encoder.nonConformingFloatEncodingStrategy =
            JSONEncoder.NonConformingFloatEncodingStrategy.convertToString(positiveInfinity: positiveInfinity,
                                                                           negativeInfinity: negativeInfinity,
                                                                           nan: nan)

        encoder.userInfo[CodingKeys.shouldIncludeSourceMap] = shouldIncludeSourceMap

        switch value {
        case let val as Double:
            return try encoder.encode(val.toExtendedJson as! [String: String])
        case let val as Int:
            return try encoder.encode(val.toExtendedJson as! [String: String])
        case let val as Int32:
            return try encoder.encode(val.toExtendedJson as! [String: String])
        case let val as Int64:
            return try encoder.encode(val.toExtendedJson as! [String: String])
        case let val as Decimal:
            return try encoder.encode(val.toExtendedJson as! [String: String])
        case let val as Date:
            return try encoder.encode(val.toExtendedJson as! [String: String])
        default:
            return try encoder.encode(value)
        }
    }

    public init() {}
}



fileprivate class _BSONEncoder : Encoder, _BSONCodingPathContaining {
    enum Target {
        case document(Document)
        case primitive(get: () -> ExtendedJsonRepresentable?,
                       set: (ExtendedJsonRepresentable?) -> ())

        var document: Document {
            get {
                switch self {
                case .document(let doc): return doc
                case .primitive(let get, _): return get() as? Document ?? Document()
                }
            }
            set {
                switch self {
                case .document: self = .document(newValue)
                case .primitive(_, let set): set(newValue)
                }
            }
        }

        var primitive: ExtendedJsonRepresentable? {
            get {
                switch self {
                case .document(let doc): return doc
                case .primitive(let get, _): return get()
                }
            }
            set {
                switch self {
                case .document: self = .document(newValue as! Document)
                case .primitive(_, let set): set(newValue)
                }
            }
        }
    }
    var target: Target

    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey : Any] = [:]

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        let container = _BSONKeyedEncodingContainer<Key>(encoder: self)
        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return _BSONUnkeyedEncodingContainer(encoder: self)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        return _BSONSingleValueEncodingContainer(encoder: self)
    }

    init(codingPath: [CodingKey] = [], target: Target = .document([:])) {
        self.codingPath = codingPath
        self.target = target
    }

    // MARK: - Value conversion
    func convert(_ value: Bool) throws -> ExtendedJsonRepresentable { return value }
    func convert(_ value: Int) throws -> ExtendedJsonRepresentable { return value }
    func convert(_ value: Int8) throws -> ExtendedJsonRepresentable { return Int32(value) }
    func convert(_ value: Int16) throws -> ExtendedJsonRepresentable { return Int32(value) }
    func convert(_ value: Int32) throws -> ExtendedJsonRepresentable { return value }
    func convert(_ value: Int64) throws -> ExtendedJsonRepresentable { return Int(value) }
    func convert(_ value: UInt8) throws -> ExtendedJsonRepresentable { return Int32(value) }
    func convert(_ value: UInt16) throws -> ExtendedJsonRepresentable { return Int32(value) }
    func convert(_ value: UInt32) throws -> ExtendedJsonRepresentable { return Int(value) }
    func convert(_ value: Float) throws -> ExtendedJsonRepresentable { return Double(value) }
    func convert(_ value: Decimal) throws -> ExtendedJsonRepresentable { return value }
    func convert(_ value: Double) throws -> ExtendedJsonRepresentable { return value }
    func convert(_ value: String) throws -> ExtendedJsonRepresentable { return value }
    func convert(_ value: UInt) throws -> ExtendedJsonRepresentable {
        guard value < Int.max else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: codingPath, debugDescription: "Value exceeds \(Int.max) which is the BSON Int limit"))
        }

        return Int(value)
    }
    
    func convert(_ value: UInt64) throws -> ExtendedJsonRepresentable {
        // BSON only supports 64 bit platforms where UInt64 is the same size as Int64
        return try convert(UInt(value))
    }
    func encode<T : Encodable>(_ value: T) throws -> ExtendedJsonRepresentable? {
        if let primitive = value as? ExtendedJsonRepresentable {
            return primitive
        } else {
            var primitive: ExtendedJsonRepresentable? = nil
            let encoder = _BSONEncoder(target: .primitive(get: { primitive }, set: { primitive = $0 }))
            try value.encode(to: encoder)
            return primitive
        }
    }
}

fileprivate class _BSONKeyedEncodingContainer<K : CodingKey> : KeyedEncodingContainerProtocol, _BSONCodingPathContaining {
    let encoder: _BSONEncoder
    var codingPath: [CodingKey]

    init(encoder: _BSONEncoder) {
        self.encoder = encoder
        self.codingPath = encoder.codingPath
    }

    func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
        try with(pushedKey: key) {
            encoder.target.document[key.stringValue] = try encoder.encode(value)
        }
    }

    func encodeNil(forKey key: K) throws {
        with(pushedKey: key) {
            encoder.target.document[key.stringValue] = nil
        }
    }

    private func nestedEncoder(forKey key: CodingKey) -> _BSONEncoder {
        return self.encoder.with(pushedKey: key) {
            return _BSONEncoder(codingPath: self.encoder.codingPath, target: .primitive(get: { self.encoder.target.document[key.stringValue] }, set: { self.encoder.target.document[key.stringValue] = $0 }))
        }
    }

    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> {
        let encoder = nestedEncoder(forKey: key)
        return encoder.container(keyedBy: keyType)
    }

    func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        let encoder = nestedEncoder(forKey: key)
        return encoder.unkeyedContainer()
    }

    func superEncoder() -> Encoder {
        return nestedEncoder(forKey: _BSONSuperKey.super)
    }

    func superEncoder(forKey key: K) -> Encoder {
        return nestedEncoder(forKey: key)
    }

    typealias Key = K
}

fileprivate struct _BSONUnkeyedEncodingContainer : UnkeyedEncodingContainer {
    var count: Int {
        return encoder.target.document.count
    }

    var encoder: _BSONEncoder
    var codingPath: [CodingKey] {
        get {
            return encoder.codingPath
        }
        set {
            encoder.codingPath = newValue
        }
    }

    init(encoder: _BSONEncoder) {
        self.encoder = encoder

        if (self.encoder.target.document.count == 0) {
            self.encoder.target.document = [:] // array
        }
    }

    private func nestedEncoder() -> _BSONEncoder {
        let index = self.encoder.target.document.count
        self.encoder.target.document[String(index)] = Document()
        return _BSONEncoder(codingPath: codingPath, target: .primitive(get: { self.encoder.target.document[String(index)] }, set: { self.encoder.target.document[String(index)] = $0 }))
    }

    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        let encoder = nestedEncoder()
        let container = _BSONKeyedEncodingContainer<NestedKey>(encoder: encoder)
        return KeyedEncodingContainer(container)
    }

    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let encoder = nestedEncoder()
        return _BSONUnkeyedEncodingContainer(encoder: encoder)
    }

    func superEncoder() -> Encoder {
        // TODO: Check: is this OK?
        return nestedEncoder()
    }

    func encode(_ value: Bool) throws { try encoder.target.document[String(describing: index)] = (encoder.convert(value)) }
    func encode(_ value: Int) throws { try encoder.target.document[String(describing: index)] = (encoder.convert(value)) }
    func encode(_ value: Int8) throws { try encoder.target.document[String(describing: index)] = (encoder.convert(value)) }
    func encode(_ value: Int16) throws { try encoder.target.document[String(describing: index)] = encoder.convert(value) }
    func encode(_ value: Int32) throws { try encoder.target.document[String(describing: index)] = encoder.convert(value) }
    func encode(_ value: Int64) throws { try encoder.target.document[String(describing: index)] = encoder.convert(value) }
    func encode(_ value: UInt) throws { try encoder.target.document[String(describing: index)] = encoder.convert(value) }
    func encode(_ value: UInt8) throws { try encoder.target.document[String(describing: index)] = encoder.convert(value) }
    func encode(_ value: UInt16) throws { try encoder.target.document[String(describing: index)] = encoder.convert(value) }
    func encode(_ value: UInt32) throws { try encoder.target.document[String(describing: index)] = encoder.convert(value) }
    func encode(_ value: UInt64) throws { try encoder.target.document[String(describing: index)] = encoder.convert(value) }
    func encode(_ value: String) throws { try encoder.target.document[String(describing: index)] = encoder.convert(value) }
    func encode(_ value: Float) throws { try encoder.target.document[String(describing: index)] = encoder.convert(value) }
    func encode(_ value: Decimal) throws { try encoder.target.document[String(describing: index)] = encoder.convert(value) }
    func encode(_ value: Double) throws { try encoder.target.document[String(describing: index)] = encoder.convert(value) }
    func encode<T : Encodable>(_ value: T) throws { try encoder.target.document[String(describing: index)] = (unwrap(encoder.encode(value), codingPath: codingPath)) }
    mutating func encodeNil() throws { encoder.target.document[String(describing: index)] = Null() }
}

fileprivate struct _BSONSingleValueEncodingContainer : SingleValueEncodingContainer {
    let encoder: _BSONEncoder
    let codingPath: [CodingKey]

    init(encoder: _BSONEncoder) {
        self.encoder = encoder
        self.codingPath = encoder.codingPath
    }

    func encodeNil() throws { encoder.target.primitive = nil }
    func encode(_ value: Bool) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: Int) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: Int8) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: Int16) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: Int32) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: Int64) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: UInt8) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: UInt16) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: UInt32) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: Float) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: Decimal) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: Double) throws {
        try encoder.with(replacedPath: codingPath) {
            try encoder.target.primitive = encoder.convert(value)
        }
    }
    func encode(_ value: String) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: UInt) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: UInt64) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode<T>(_ value: T) throws where T : Encodable { try encoder.target.primitive = encoder.encode(value) }
}

public class BSONDecoder {
    public func decode<T : Decodable>(_ type: T.Type,
                                      from document: Document) throws -> T {
        let decoder = _BSONDecoder(target: .document(document))
        return try T(from: decoder)
    }

    public func decode<T>(_ type: T.Type,
                          from data: Data,
                          hasSourceMap: Bool) throws -> T where T: Decodable {
        switch type {
        case let superType as ExtendedJsonRepresentable.Type:
            if hasSourceMap { fallthrough }
            guard let t = try superType.fromExtendedJson(
                xjson: try JSONSerialization.jsonObject(with: data,
                                                        options: .allowFragments)) as? T else {
                throw BsonError.parseValueFailure(value: data, attemptedType: type)
            }

            return t
        default:
            let decoder = JSONDecoder()
            decoder.nonConformingFloatDecodingStrategy =
                JSONDecoder.NonConformingFloatDecodingStrategy.convertFromString(positiveInfinity: positiveInfinity,
                                                                                 negativeInfinity: negativeInfinity,
                                                                                 nan: nan)
            return try decoder.decode(type, from: data)
        }
    }

    public init() {}
}

fileprivate class _BSONDecoder: Decoder, _BSONCodingPathContaining {
    enum Target {
        case document(Document)
        case primitive(get: () -> ExtendedJsonRepresentable?)
        case storedExtendedJsonRepresentable(ExtendedJsonRepresentable?)

        var document: Document {
            get {
                switch self {
                case .document(let doc): return doc
                case .primitive(let get): return get() as? Document ?? Document()
                case .storedExtendedJsonRepresentable(let val): return val as? Document ?? Document()
                }
            }
        }

        var primitive: ExtendedJsonRepresentable? {
            get {
                switch self {
                case .document(let doc): return doc
                case .primitive(let get): return get()
                case .storedExtendedJsonRepresentable(let val): return val
                }
            }
        }
    }

    let target: Target

    var codingPath: [CodingKey]

    var userInfo: [CodingUserInfoKey : Any] = [:]

    init(codingPath: [CodingKey] = [], target: Target) {
        self.target = target
        self.codingPath = codingPath
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        let container = _BSONKeyedDecodingContainer<Key>(decoder: self, codingPath: self.codingPath)
        return KeyedDecodingContainer(container)
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return _BSONUnkeyedDecodingContainer(decoder: self)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return _BSONSingleValueDecodingContainer(codingPath: self.codingPath, decoder: self)
    }

    /// Performs the given closure with the given key pushed onto the end of the current coding path.
    ///
    /// - parameter key: The key to push. May be nil for unkeyed containers.
    /// - parameter work: The work to perform with the key in the path.
    func with<T>(pushedKey key: CodingKey, _ work: () throws -> T) rethrows -> T {
        self.codingPath.append(key)
        let ret: T = try work()
        self.codingPath.removeLast()
        return ret
    }

    // MARK: - Value conversion
    func unwrap<T : ExtendedJsonRepresentable>(_ value: ExtendedJsonRepresentable?) throws -> T {
        guard let primitiveValue = value, !(primitiveValue is NSNull) else {
            throw DecodingError.valueNotFound(T.self,
                                              DecodingError.Context(codingPath: codingPath,
                                                                    debugDescription: "Value not found - expected value of type \(T.self), found null / nil"))
        }

        guard let tValue = primitiveValue as? T else {
            throw DecodingError.typeMismatch(T.self,
                                             DecodingError.Context(codingPath: codingPath,
                                                                   debugDescription: "Type mismatch - expected value of type \(T.self), found \(type(of: primitiveValue))"))
        }

        return tValue
    }

    func unwrap(_ value: ExtendedJsonRepresentable?) throws -> Int32 {
        guard let primitiveValue = value, !(primitiveValue is NSNull) else {
            throw DecodingError.valueNotFound(Int32.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Value not found - expected value of type \(Int32.self), found null / nil"))
        }

        switch primitiveValue {
        case let number as Int32:
            return number
        case let number as Int:
            guard number >= Int32.min && number <= Int32.max else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(Int32.self)"))
            }
            return Int32(number) as Int32
        case let number as Double:
            guard number >= Double(Int32.min) && number <= Double(Int32.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(Int32.self)"))
            }
            return Int32(number) as Int32
        default:
            throw DecodingError.typeMismatch(Int32.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Type mismatch - expected value of type \(Int32.self), found \(type(of: primitiveValue))"))
        }
    }

    func unwrap(_ value: ExtendedJsonRepresentable?) throws -> Int {
        guard let primitiveValue = value, !(primitiveValue is NSNull) else {
            throw DecodingError.valueNotFound(Int.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Value not found - expected value of type \(Int.self), found null / nil"))
        }

        switch primitiveValue {
        case let number as Int32:
            return Int(number) as Int
        case let number as Int:
            return number
        case let number as Double:
            guard number >= Double(Int.min) && number <= Double(Int.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(Int.self)"))
            }
            return Int(number) as Int
        default:
            throw DecodingError.typeMismatch(Int.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Type mismatch - expected value of type \(Int.self), found \(type(of: primitiveValue))"))
        }
    }

    func unwrap(_ value: ExtendedJsonRepresentable?) throws -> Double {
        guard let primitiveValue = value, !(primitiveValue is NSNull) else {
            throw DecodingError.valueNotFound(Double.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Value not found - expected value of type \(Double.self), found null / nil"))
        }

        switch primitiveValue {
        case let number as Int32:
            return Double(number)
        case let number as Int:
            return Double(number)
        case let number as Double:
            return number
        default:
            throw DecodingError.typeMismatch(Double.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Type mismatch - expected value of type \(Double.self), found \(type(of: primitiveValue))"))
        }
    }

    func unwrap(_ value: ExtendedJsonRepresentable?) throws -> Bool {
        guard let primitiveValue = value, !(primitiveValue is NSNull) else {
            throw DecodingError.valueNotFound(Bool.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Value not found - expected value of type \(Bool.self), found null / nil"))
        }

        guard let bool = primitiveValue as? Bool else {
            throw DecodingError.typeMismatch(Bool.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Type mismatch - expected value of type \(Bool.self), found \(type(of: primitiveValue))"))
        }

        return bool
    }

    func unwrap(_ value: ExtendedJsonRepresentable?) throws -> Int8 {
        let number: Int32 = try unwrap(value)

        guard number >= Int8.min && number <= Int8.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(Int8.self)"))
        }
        return Int8(number)
    }

    func unwrap(_ value: ExtendedJsonRepresentable?) throws -> Int16 {
        let number: Int32 = try unwrap(value)

        guard number >= Int16.min && number <= Int16.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(Int16.self)"))
        }
        return Int16(number)
    }

    func unwrap(_ value: ExtendedJsonRepresentable?) throws -> Int64 {
        guard let primitiveValue = value, !(primitiveValue is NSNull) else {
            throw DecodingError.valueNotFound(Int.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Value not found - expected value of type \(Int.self), found null / nil"))
        }

        switch primitiveValue {
        case let number as Int64:
            return number
        default:
            throw DecodingError.typeMismatch(Double.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Type mismatch - expected value of type \(Double.self), found \(type(of: primitiveValue))"))
        }
    }

    func unwrap(_ value: ExtendedJsonRepresentable?) throws -> UInt8 {
        let number: Int32 = try unwrap(value)

        guard number >= UInt8.min && number <= UInt8.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(UInt8.self)"))
        }
        return UInt8(number)
    }

    func unwrap(_ value: ExtendedJsonRepresentable?) throws -> UInt16 {
        let number: Int32 = try unwrap(value)

        guard number >= UInt16.min && number <= UInt16.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(UInt16.self)"))
        }
        return UInt16(number)
    }

    func unwrap(_ value: ExtendedJsonRepresentable?) throws -> UInt32 {
        let number: Int = try unwrap(value)

        guard number >= UInt32.min && number <= UInt32.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(UInt32.self)"))
        }
        return UInt32(number)
    }
    
    func unwrap(_ value: ExtendedJsonRepresentable?) throws -> Float {
        // TODO: Check losing precision like JSONEncoder
        let number: Double = try unwrap(value)

        return Float(number)
    }

    func unwrap(_ value: ExtendedJsonRepresentable?) throws -> Decimal {
        guard let primitiveValue = value, !(primitiveValue is NSNull) else {
            throw DecodingError.valueNotFound(Int.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Value not found - expected value of type \(Int.self), found null / nil"))
        }

        switch primitiveValue {
        case let number as Decimal:
            return number
        default:
            throw DecodingError.typeMismatch(Double.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Type mismatch - expected value of type \(Double.self), found \(type(of: primitiveValue))"))
        }
    }

    func unwrap(_ value: ExtendedJsonRepresentable?) throws -> UInt {
        let number: Int = try unwrap(value)

        guard number <= UInt.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(UInt.self)"))
        }
        return UInt(number)
    }

    func unwrap(_ value: ExtendedJsonRepresentable?) throws -> UInt64 {
        let number: UInt = try unwrap(value)

        // BSON only supports 64 bit platforms where UInt64 is the same size as UInt
        return UInt64(number)
    }

    func decode<T>(_ value: ExtendedJsonRepresentable?) throws -> T where T : Decodable {
        guard let value = value else {
            throw DecodingError.valueNotFound(T.self,
                                              DecodingError.Context(codingPath: codingPath,
                                                                    debugDescription: "Value not found - expected value of type \(T.self), found null / nil"))
        }

        switch T.self {
        case is Document.Type:
            return try ExtendedJson.unwrap(unwrap(value), codingPath: codingPath) as Document as! T
        case is BSONArray.Type:
            return try ExtendedJson.unwrap(unwrap(value), codingPath: codingPath) as BSONArray as! T
        case is ObjectId.Type:
            return try ExtendedJson.unwrap(unwrap(value), codingPath: codingPath) as ObjectId as! T
        case is Symbol.Type:
            return try ExtendedJson.unwrap(unwrap(value), codingPath: codingPath) as Symbol as! T
        case is Binary.Type:
            return try ExtendedJson.unwrap(unwrap(value), codingPath: codingPath) as Binary as! T
        case is Code.Type:
            return try ExtendedJson.unwrap(unwrap(value), codingPath: codingPath) as Code as! T
        case is DBPointer.Type:
            return try ExtendedJson.unwrap(unwrap(value), codingPath: codingPath) as DBPointer as! T
        case is DBRef.Type:
            return try ExtendedJson.unwrap(unwrap(value), codingPath: codingPath) as DBRef as! T
        case is Timestamp.Type:
            return try ExtendedJson.unwrap(unwrap(value), codingPath: codingPath) as Timestamp as! T
        case is Undefined.Type:
            return try ExtendedJson.unwrap(unwrap(value), codingPath: codingPath) as Undefined as! T
        case is MaxKey.Type:
            return try ExtendedJson.unwrap(unwrap(value), codingPath: codingPath) as MaxKey as! T
        case is MinKey.Type:
            return try ExtendedJson.unwrap(unwrap(value), codingPath: codingPath) as MinKey as! T
        case is Date.Type:
            return try ExtendedJson.unwrap(unwrap(value), codingPath: codingPath) as Date as! T
        case is Decimal.Type:
            return try unwrap(value) as Decimal as! T
        case is NSNull.Type:
            return Null() as! T
        case is RegularExpression.Type:
            return try ExtendedJson.unwrap(unwrap(value), codingPath: codingPath) as RegularExpression as! T
        default: break
        }

        let decoder = _BSONDecoder(target: .storedExtendedJsonRepresentable(value))
        return try T(from: decoder)
    }
}

fileprivate struct _BSONKeyedDecodingContainer<Key : CodingKey> : KeyedDecodingContainerProtocol {
    let decoder: _BSONDecoder

    var codingPath: [CodingKey]

    var allKeys: [Key] {
        return decoder.target.document.orderedKeys.flatMap { Key(stringValue: $0 as! String) }
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        return decoder.target.document[key.stringValue] == nil
    }

    func contains(_ key: Key) -> Bool {
        return decoder.target.document[key.stringValue] != nil
    }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }

    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }

    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }

    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }

    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }

    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }

    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }

    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }

    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }

    func decode(_ type: Decimal.Type, forKey key: Key) throws -> Decimal {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        return try decoder.with(pushedKey: key) {
            return try decoder.decode(decoder.target.document[key.stringValue])
        }
    }

    private func nestedDecoder(forKey key: CodingKey) -> _BSONDecoder {
        return decoder.with(pushedKey: key) {
            return _BSONDecoder(codingPath: self.decoder.codingPath, target: .primitive(get: { self.decoder.target.document[key.stringValue] }))
        }
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        return try nestedDecoder(forKey: key).container(keyedBy: type)
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        return try nestedDecoder(forKey: key).unkeyedContainer()
    }

    func superDecoder() throws -> Decoder {
        return nestedDecoder(forKey: _BSONSuperKey.super)
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        return nestedDecoder(forKey: key)
    }
}

fileprivate class _BSONUnkeyedDecodingContainer : UnkeyedDecodingContainer, _BSONCodingPathContaining {
    let decoder: _BSONDecoder
    var codingPath: [CodingKey]

    init(decoder: _BSONDecoder) {
        self.decoder = decoder
        self.codingPath = decoder.codingPath
    }

    var count: Int? { return decoder.target.document.count }
    var currentIndex: Int = 0

    var isAtEnd: Bool {
        return currentIndex >= self.count!
    }

    func next() -> ExtendedJsonRepresentable? {
        let value = decoder.target.document[decoder.target.document.orderedKeys[currentIndex] as! String]
        currentIndex += 1
        return value
    }

    func assertNotAtEnd(_ type: Any.Type) throws {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Unkeyed decoding container is at end"))
        }
    }

    /// Decodes a null value.
    ///
    /// If the value is not null, does not increment currentIndex.
    ///
    /// - returns: Whether the encountered value was null.
    /// - throws: `DecodingError.valueNotFound` if there are no more values to decode.
    func decodeNil() throws -> Bool {
        try assertNotAtEnd(NSNull.self)
        if decoder.target.document[decoder.target.document.orderedKeys[currentIndex] as! String] == nil {
            currentIndex += 1
            return true
        } else {
            return false
        }
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        return try decoder.unwrap(next())
    }

    func decode(_ type: Int.Type) throws -> Int {
        return try decoder.unwrap(next())
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        return try decoder.unwrap(next())
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        return try decoder.unwrap(next())
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        return try decoder.unwrap(next())
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        return try decoder.unwrap(next())
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        return try decoder.unwrap(next())
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try decoder.unwrap(next())
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try decoder.unwrap(next())
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try decoder.unwrap(next())
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try decoder.unwrap(next())
    }

    func decode(_ type: Float.Type) throws -> Float {
        return try decoder.unwrap(next())
    }

    func decode(_ type: Decimal.Type) throws -> Decimal {
        return try decoder.unwrap(next())
    }

    func decode(_ type: Double.Type) throws -> Double {
        return try decoder.unwrap(next())
    }

    func decode(_ type: String.Type) throws -> String {
        return try decoder.unwrap(next())
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        return try decoder.decode(next())
    }

    func nestedDecoder() throws -> _BSONDecoder {
        return try decoder.with(pushedKey: _BSONUnkeyedIndexKey(index: self.currentIndex)) {
            guard !isAtEnd else {
                throw DecodingError.valueNotFound(Decoder.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot get nested decoder -- unkeyed container is at end."))
            }

            let value = next()
            return _BSONDecoder(target: .storedExtendedJsonRepresentable(value))
        }
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        return try nestedDecoder().container(keyedBy: type)
    }

    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        return try nestedDecoder().unkeyedContainer()
    }

    func superDecoder() throws -> Decoder {
        return try nestedDecoder()
    }

}

fileprivate struct _BSONSingleValueDecodingContainer : SingleValueDecodingContainer {
    var codingPath: [CodingKey]
    let decoder: _BSONDecoder

    private func unwrap<T>(_ value: T?) throws -> T {
        return try ExtendedJson.unwrap(value, codingPath: decoder.codingPath)
    }

    func decodeNil() -> Bool { return decoder.target.primitive == nil }
    func decode(_ type: Bool.Type) throws -> Bool { return try decoder.unwrap(decoder.target.primitive) }
    func decode(_ type: Int.Type) throws -> Int { return try decoder.unwrap(decoder.target.primitive) }
    func decode(_ type: Int8.Type) throws -> Int8 { return try decoder.unwrap(decoder.target.primitive) }
    func decode(_ type: Int16.Type) throws -> Int16 { return try decoder.unwrap(decoder.target.primitive) }
    func decode(_ type: Int32.Type) throws -> Int32 { return try decoder.unwrap(decoder.target.primitive) }
    func decode(_ type: Int64.Type) throws -> Int64 { return try decoder.unwrap(decoder.target.primitive) }
    func decode(_ type: UInt.Type) throws -> UInt { return try decoder.unwrap(decoder.target.primitive) }
    func decode(_ type: UInt8.Type) throws -> UInt8 { return try decoder.unwrap(decoder.target.primitive) }
    func decode(_ type: UInt16.Type) throws -> UInt16 { return try decoder.unwrap(decoder.target.primitive) }
    func decode(_ type: UInt32.Type) throws -> UInt32 { return try decoder.unwrap(decoder.target.primitive) }
    func decode(_ type: UInt64.Type) throws -> UInt64 { return try decoder.unwrap(decoder.target.primitive) }
    func decode(_ type: Float.Type) throws -> Float { return try decoder.unwrap(decoder.target.primitive) }
    func decode(_ type: Decimal.Type) throws -> Decimal { return try decoder.unwrap(decoder.target.primitive) }
    func decode(_ type: Double.Type) throws -> Double { return try decoder.unwrap(decoder.target.primitive) }
    func decode(_ type: String.Type) throws -> String { return try decoder.unwrap(decoder.target.primitive) }
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable { return try decoder.decode(decoder.target.primitive) }
}

// - MARK: Supporting Protocols
fileprivate protocol _BSONCodingPathContaining : class {
    var codingPath: [CodingKey] { get set }
}

extension _BSONCodingPathContaining {
    // MARK: - Coding Path Operations
    /// Performs the given closure with the given key pushed onto the end of the current coding path.
    ///
    /// - parameter key: The key to push. May be nil for unkeyed containers.
    /// - parameter work: The work to perform with the key in the path.
    func with<T>(pushedKey key: CodingKey, _ work: () throws -> T) rethrows -> T {
        self.codingPath.append(key)
        let ret: T = try work()
        self.codingPath.removeLast()
        return ret
    }

    func with<T>(replacedPath path: [CodingKey], _ work: () throws -> T) rethrows -> T {
        let originalPath = self.codingPath
        self.codingPath = path
        let ret: T = try work()
        self.codingPath = originalPath
        return ret
    }
}

// - MARK: Shared Super Key
fileprivate enum _BSONSuperKey : String, CodingKey {
    case `super`
}

fileprivate struct _BSONUnkeyedIndexKey : CodingKey {
    var index: Int
    init(index: Int) {
        self.index = index
    }

    var intValue: Int? {
        return index
    }

    var stringValue: String {
        return String(describing: index)
    }

    init?(intValue: Int) {
        self.index = intValue
    }

    init?(stringValue: String) {
        return nil
    }
}
