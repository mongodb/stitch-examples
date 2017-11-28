//
//  BsonError.swift
//  ExtendedJson
//

import Foundation

public enum ExtendedJsonRepresentableError<T, U> {
    case incompatibleTypeFailure(attemptedType: T.Type, actualType: U.Type, actualValue: ExtendedJsonRepresentable)
}

// MARK: - XJson Error Descriptions
extension ExtendedJsonRepresentableError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .incompatibleTypeFailure(let attemptedType, let actualType, let actualValue):
            return "Attempted conversion from \(actualType) to \(attemptedType) for value \(actualValue) failed"
        }
    }
}

public enum BsonError<T> {
    case illegalArgument(message: String)
    case parseValueFailure(value: Any?, attemptedType: T.Type)
}

// MARK: - Bson Error Descriptions
extension BsonError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .illegalArgument(let message):
            return message
         case .parseValueFailure(let value, let attemptedType):
            return "ExtendedJson \(value ?? "nil") is not valid \(attemptedType)"
        }
    }
}

