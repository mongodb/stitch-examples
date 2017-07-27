//
//  MongoDBManager.swift
//  MongoDBSample
//
//

import Foundation
import StitchCore


class MongoDBManager {
    
    // MARK: - Properties
    
    /// Shared Mongo Manager instance
    static let shared = MongoDBManager()

    var provider: Provider?
}
