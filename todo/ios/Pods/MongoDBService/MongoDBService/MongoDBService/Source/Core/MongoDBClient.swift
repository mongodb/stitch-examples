//
//  MongoDBClient.swift
//  MongoDBService
//

import Foundation
import StitchCore

public class MongoDBClient: MongoDBClientType {

    public let stitchClient: StitchClient
    public let serviceName: String

    // MARK: - Init

    public required init(stitchClient: StitchClient, serviceName: String) {
        self.stitchClient = stitchClient
        self.serviceName = serviceName
    }

    // MARK: - Public

    @discardableResult
    public func database(named name: String) -> DatabaseType {
        return Database(client: self, name: name)
    }
}
