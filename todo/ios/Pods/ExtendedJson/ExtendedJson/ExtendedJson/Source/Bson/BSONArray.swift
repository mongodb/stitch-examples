//
//  BsonArray.swift
//  ExtendedJson
//

import Foundation

public protocol BSONCollection {
}
extension BSONCollection {
    public func asArray() -> BSONArray {
        return self as! BSONArray
    }

    public func asDoc() -> Document {
        return self as! Document
    }
}

public struct BSONArray: BSONCollection, Codable {
    private struct CodingKeys: CodingKey {
        var stringValue: String

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        var intValue: Int?

        init?(intValue: Int) {
            self.intValue = intValue
            self.stringValue = String(intValue)
        }

        static let info = CodingKeys(stringValue: "__$info__")!
        static let array = CodingKeys(stringValue: "__$arr__")!
    }

    fileprivate var underlyingArray: [ExtendedJsonRepresentable] = []

    public init() {}

    public init(array: [ExtendedJsonRepresentable]) {
        underlyingArray = array
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let infoContainer = try container.decode([Int: String].self).sorted {
            arg1, arg2 -> Bool in
            return arg1.key < arg2.key
        }

        try infoContainer.forEach { arg in
            let (key, value) = arg
            self[key] = try BSONArray.decode(from: &container, decodingTypeString: value)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        var infoContainer = [Int: String]()

        let encoders = try (0..<self.count).map { index in
            return try BSONArray.encodeUnkeyedContainer(sourceMap: &infoContainer,
                                                        forKey: Int(index),
                                                        withValue: self[index])
        }

        if (encoder.userInfo[BSONEncoder.CodingKeys.shouldIncludeSourceMap] as? Bool ?? false) {
            try container.encode(infoContainer)
        }

        // this strategy is done to ensure the sourceMap (if included)
        // is the first decodable object
        try encoders.forEach { try $0(&container) }
    }

    public init(array: [Any]) throws {
        underlyingArray = try array.map { (any) -> ExtendedJsonRepresentable in
            return try Document.decodeXJson(value: any)
        }
    }

    public mutating func remove(object: ExtendedJsonRepresentable) -> Bool {
        for i in 0..<underlyingArray.count {
            let currentObject = underlyingArray[i]
            if currentObject.isEqual(toOther: object) {
                underlyingArray.remove(at: i)
                return true
            }
        }
        return false
    }
}

// MARK: - Collection

extension BSONArray: Collection {

    public typealias Index = Int

    public var startIndex: Index {
        return underlyingArray.startIndex
    }

    public var endIndex: Index {
        return underlyingArray.endIndex
    }

    public func makeIterator() -> IndexingIterator<[ExtendedJsonRepresentable]> {
        return underlyingArray.makeIterator()
    }

    public subscript(index: Int) -> ExtendedJsonRepresentable {
        get {
            return underlyingArray[index]
        }
        set(newElement) {
            underlyingArray.insert(newElement, at: index)
        }
    }

    public func index(after i: Index) -> Index {
        return underlyingArray.index(after: i)
    }

    // MARK: Mutating

    public mutating func append(_ newElement: ExtendedJsonRepresentable) {
        underlyingArray.append(newElement)
    }

    public mutating func remove(at index: Int) {
        underlyingArray.remove(at: index)
    }

}

extension BSONArray: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: ExtendedJsonRepresentable...) {
        self.init()
        underlyingArray = elements
    }
}
