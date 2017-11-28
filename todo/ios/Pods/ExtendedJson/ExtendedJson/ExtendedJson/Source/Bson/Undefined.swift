//
//  BsonUndefined.swift
//  ExtendedJson
//

import Foundation

public struct Undefined {
    public init() {}
}

// MARK: - Equatable

extension Undefined: Equatable {
    public static func ==(lhs: Undefined, rhs: Undefined) -> Bool {
        return true
    }
}
