//
//  MongoDBManager.swift
//  MongoDBSample
//
//  Created by Jay Flax on 6/20/17.
//  Copyright © 2017 Zemingo. All rights reserved.
//

import Foundation
import StitchCore


class MongoDBManager {
    
    // MARK: - Properties
    
    /// Shared Mongo Manager instance
    static let shared = MongoDBManager()

    var provider: Provider?
}
