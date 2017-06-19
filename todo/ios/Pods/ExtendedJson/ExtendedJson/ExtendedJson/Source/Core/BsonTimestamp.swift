//
//  BsonTimestamp.swift
//  ExtendedJson
//

import Foundation

public struct BsonTimestamp {

    public private(set) var time: Date
    
    public init(time: Date) {
        self.time = time
    }
    
    public init(time: TimeInterval) {
        self = BsonTimestamp(time: Date(timeIntervalSince1970: time))
    }
}

// MARK: - Equatable

extension BsonTimestamp: Equatable {
    public static func ==(lhs: BsonTimestamp, rhs: BsonTimestamp) -> Bool {        
        return UInt64(lhs.time.timeIntervalSince1970) == UInt64(rhs.time.timeIntervalSince1970)
    }
}
