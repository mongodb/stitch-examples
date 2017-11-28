//
//  BsonDBPointer+ExtendedJson.swift
//  ExtendedJson
//
//  Created by Jason Flax on 10/6/17.
//  Copyright © 2017 MongoDB. All rights reserved.
//

import Foundation

extension DBPointer: ExtendedJsonRepresentable {
    enum CodingKeys: String, CodingKey {
        case dbPointer = "$dbPointer", ref = "$ref", oid = "$id"
    }

    public static func fromExtendedJson(xjson: Any) throws -> ExtendedJsonRepresentable {
        guard let json = xjson as? [String: Any],
            let dbPointer = json[ExtendedJsonKeys.dbPointer.rawValue] as? [String: Any],
            let ref = dbPointer[ExtendedJsonKeys.dbRef.rawValue] as? String,
            let oid = dbPointer["$id"],
            let id = try ObjectId.fromExtendedJson(xjson: oid) as? ObjectId,
            dbPointer.count == 2 else {
                throw BsonError.parseValueFailure(value: xjson, attemptedType: DBPointer.self)
        }

        return DBPointer(ref: ref, id: id)
    }

    public var toExtendedJson: Any {
        return [
            ExtendedJsonKeys.dbPointer.rawValue: [
                ExtendedJsonKeys.dbRef: self.ref,
                ExtendedJsonKeys.objectid: self.id.toExtendedJson
            ]
        ]
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nestedContainer = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                            forKey: CodingKeys.dbPointer)
        self.init(ref: try nestedContainer.decode(String.self, forKey: CodingKeys.ref),
                  id: try nestedContainer.decode(ObjectId.self, forKey: CodingKeys.oid))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var nestedContainer = container.nestedContainer(keyedBy: CodingKeys.self,
                                                        forKey: CodingKeys.dbPointer)
        try nestedContainer.encode(self.ref, forKey: CodingKeys.ref)
        try nestedContainer.encode(self.id, forKey: CodingKeys.oid)
    }
    
    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        return other is DBPointer &&
            (other as! DBPointer).id == self.id &&
            (other as! DBPointer).ref == self.ref
    }
}
