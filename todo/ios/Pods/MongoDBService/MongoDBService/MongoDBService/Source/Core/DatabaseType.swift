//
//  DatabaseType.swift
//  MongoDBService
//

import Foundation

public protocol DatabaseType {

    var client: MongoDBClientType { get }
    var name: String { get }

    @discardableResult
    func collection(named name: String) -> Collection
}
