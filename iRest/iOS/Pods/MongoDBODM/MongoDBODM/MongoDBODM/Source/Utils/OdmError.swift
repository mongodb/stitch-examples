//
//  OdmError.swift
//  MongoDBODM
//

import Foundation

public enum OdmError: Error {
    case objectIdNotFound
    case classMetaDataNotFound
    case corruptedData(message: String)
    case updateParametersMissing
    case collectionOutOfRange
    case partialUpdateSuccess(originalError: Error)
}

// MARK: - Error Descriptions

extension OdmError: LocalizedError {
    public var errorDescription: String {
        switch self {
        case .objectIdNotFound:
            return "no objectId found for the Entity"
        case .classMetaDataNotFound:
            return "Could not find class metadata, the class is not registerd with the right name"
        case .corruptedData(let message):
            return message
        case .updateParametersMissing:
            return "parameters missing for update operation"
        case .collectionOutOfRange:
            return "No more results are available"
        case .partialUpdateSuccess(let originalError):
            return "array item was not removed becaouse of an error : \(originalError), Operation could not be completed "
        }
    }
}
