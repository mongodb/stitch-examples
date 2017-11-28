//
//  BsonDBPointer.swift
//  ExtendedJson
//
//  Created by Jason Flax on 10/6/17.
//  Copyright © 2017 MongoDB. All rights reserved.
//

import Foundation

public struct DBPointer {
    let ref: String
    let id: ObjectId

    public init (ref: String, id: ObjectId) {
        self.ref = ref
        self.id = id
    }
}
