//
//  MongoDBError.swift
//  MongoDBService
//
//  Created by Jason Flax on 10/24/17.
//  Copyright © 2017 Mongo. All rights reserved.
//

import Foundation

public enum MongoDBError: Error {
    case resultError(message: String)
}
