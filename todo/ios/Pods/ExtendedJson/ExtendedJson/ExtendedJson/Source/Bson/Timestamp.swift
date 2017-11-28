//
//  BsonTimestamp.swift
//  ExtendedJson
//

import Foundation

public struct Timestamp {

    public private(set) var time: Date
    public private(set) var increment: Int

    public init(time: Date, increment: Int) {
        self.time = time
        self.increment = increment
    }

    public init(time: TimeInterval, increment: Int) {
        self.time = Date(timeIntervalSince1970: time)
        self.increment = increment
    }
}

// MARK: - Equatable

extension Timestamp: Equatable {
    public static func ==(lhs: Timestamp, rhs: Timestamp) -> Bool {
        return UInt64(lhs.time.timeIntervalSince1970) == UInt64(rhs.time.timeIntervalSince1970)
    }
}
