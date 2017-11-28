//
//  DBRef+ExtendedJsonRepresentable.swift
//  ExtendedJson
//
//  Created by Jason Flax on 10/5/17.
//  Copyright © 2017 MongoDB. All rights reserved.
//

import Foundation

extension DBRef: Codable, ExtendedJsonRepresentable {
    private struct CodingKeys: CodingKey, Hashable {
        static func ==(lhs: DBRef.CodingKeys,
                       rhs: DBRef.CodingKeys) -> Bool {
            return lhs.stringValue == rhs.stringValue
        }

        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        var intValue: Int?
        init?(intValue: Int) { return nil }

        var hashValue: Int {
            return stringValue.hashValue
        }

        static let ref = CodingKeys(stringValue: "$ref")!
        static let id = CodingKeys(stringValue: "$id")!
        static let db = CodingKeys(stringValue: "$db")!
        static let source = CodingKeys(stringValue: "$__source__")!
    }

    public static func fromExtendedJson(xjson: Any) throws -> ExtendedJsonRepresentable {
        guard let json = xjson as? [String: Any],
            let ref = json[ExtendedJsonKeys.dbRef.rawValue] as? String,
            let idKey = json["$id"],
            let id = try ObjectId.fromExtendedJson(xjson: idKey) as? ObjectId else {
                throw BsonError.parseValueFailure(value: xjson, attemptedType: DBRef.self)
        }

        return DBRef(ref: ref,
                         id: id,
                         db: json["$db"] as? String,
                         otherFields: try json.filter {
                            !$0.key.contains("$")
                        }.mapValues { try DBRef.decodeXJson(value: $0) })
    }

    public var toExtendedJson: Any {
        var dbRef: [String: Any] = [
            ExtendedJsonKeys.dbRef.rawValue: self.ref,
            "$id": self.id.toExtendedJson
        ]

        if let db = self.db {
            dbRef["$db"] = db
        }
        if self.otherFields.capacity > 0 {
            dbRef.merge(self.otherFields) { (_, current) in current }
        }

        return dbRef
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.ref = try container.decode(String.self, forKey: CodingKeys.ref)
        self.id = try container.decode(ObjectId.self, forKey: CodingKeys.id)
        self.db = try container.decode(String?.self, forKey: CodingKeys.db)

        let sourceMap = try container.decode([String: String].self, forKey: CodingKeys.source)

        let otherFieldKeys = Set<CodingKeys>(
            arrayLiteral: CodingKeys.ref, CodingKeys.id, CodingKeys.db, CodingKeys.source
        ).symmetricDifference(container.allKeys)

        self.otherFields = try otherFieldKeys.reduce(into: [String: ExtendedJsonRepresentable]()) { (result: inout [String: ExtendedJsonRepresentable], key: CodingKeys) throws in
            result[key.stringValue] = try DBRef.decode(from: container,
                                                           decodingTypeString: sourceMap[key.stringValue]!,
                                                           forKey: key)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ref, forKey: CodingKeys.ref)
        try container.encode(id, forKey: CodingKeys.id)
        try container.encode(db, forKey: CodingKeys.db)

        var sourceMap = [String: String]()
        try otherFields.forEach {
            let (k, v) = $0
            try DBRef.encodeKeyedContainer(to: &container,
                                               sourceMap: &sourceMap,
                                               forKey: CodingKeys(stringValue: k)!,
                                               withValue: v)
        }

        try container.encode(sourceMap, forKey: CodingKeys.source)
    }

    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? DBRef {
            return other.id == self.id
        }

        return false
    }
}
