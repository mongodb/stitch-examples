//
//  Document+ExtendedJsonRepresentable.swift
//  ExtendedJson
//
//  Created by Jason Flax on 10/5/17.
//  Copyright © 2017 MongoDB. All rights reserved.
//

import Foundation

extension Document: ExtendedJsonRepresentable {
    public static func fromExtendedJson(xjson: Any) throws -> ExtendedJsonRepresentable {
        guard let json = xjson as? [String: Any],
            let doc = try? Document(extendedJson: json) else {
                if let empty = xjson as? [Any] {
                    if empty.count == 0 {
                        return Document()
                    }
                }
                throw BsonError.parseValueFailure(value: xjson, attemptedType: Document.self)
        }

        return doc
    }

    //Documen's `makeIterator()` has no concurency handling, therefor modifying the Document while itereting over it might cause unexpected behaviour
    public var toExtendedJson: Any {
        return reduce(into: [:], { ( result: inout [String: Any], kv) in
            let (key, value) = kv
            result[key] = value.toExtendedJson
        })
    }

    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? Document {
            return self == other
        }
        return false
    }
}
