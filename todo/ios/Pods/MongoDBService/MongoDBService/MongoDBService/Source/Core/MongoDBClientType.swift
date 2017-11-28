//
//  MongoDBClientType.swift
//  MongoDBService
//

import Foundation
import StitchCore

public protocol MongoDBClientType {

    var stitchClient: StitchClient { get }
    var serviceName: String { get }

    @discardableResult
    func database(named name: String) -> DatabaseType
}
