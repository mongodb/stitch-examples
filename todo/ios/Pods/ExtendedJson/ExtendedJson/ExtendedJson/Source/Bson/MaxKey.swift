//
//  MaxKey.swift
//  ExtendedJson
//

import Foundation

public struct MaxKey {
    public init() {}
}

// MARK: - Equatable
extension MaxKey: Equatable {
    public static func ==(lhs: MaxKey, rhs: MaxKey) -> Bool {
        return true
    }
}
