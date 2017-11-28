//
//  Database.swift
//  MongoDBService
//

import Foundation

public struct Database: DatabaseType {

    public let client: MongoDBClientType
    public let name: String

    internal init(client: MongoDBClientType, name: String) {
        self.client = client
        self.name = name
    }

    // MARK: - Collection

    @discardableResult
    public func collection(named name: String) -> Collection {
        return Collection(database: self, name: name)
    }
}
