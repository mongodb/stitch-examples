//
//  MinKey.swift
//  ExtendedJson
//

import Foundation

public struct MinKey {
    public init() {}
}

// MARK: - Equatable
extension MinKey: Equatable {
    public static func ==(lhs: MinKey, rhs: MinKey) -> Bool {
        return true
    }
}
