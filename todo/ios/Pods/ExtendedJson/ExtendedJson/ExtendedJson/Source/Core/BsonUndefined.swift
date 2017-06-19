//
//  BsonUndefined.swift
//  ExtendedJson
//

import Foundation

public struct BsonUndefined {
    
    public init(){}
}

// MARK: - Equatable

extension BsonUndefined: Equatable {
    public static func ==(lhs: BsonUndefined, rhs: BsonUndefined) -> Bool {
        return true
    }
}
