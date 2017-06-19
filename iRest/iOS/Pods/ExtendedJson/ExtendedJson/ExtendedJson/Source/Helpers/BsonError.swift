//
//  BsonError.swift
//  ExtendedJson
//

import Foundation

public enum BsonError {
    
    case illegalArgument(message: String)    
    case parseValueFailure(message: String)
}



// MARK: - Error Descriptions

extension BsonError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .illegalArgument(let message), .parseValueFailure(let message):
            return message
        }
    }
}
