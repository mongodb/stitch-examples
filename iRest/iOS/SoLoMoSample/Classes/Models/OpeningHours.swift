//
//  OpeningHours.swift
//  SoLoMoSample
//
//  Created by Ofir Zucker on 08/05/2017.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import Foundation
import ExtendedJson
import MongoDBService
import MongoDBODM

class OpeningHours: EmbeddedEntity {
    
    static let startKey = "start"
    static let endKey   = "end"
    
    var start: String?{
        get {
            return self[OpeningHours.startKey] as? String
        }
        set(newStart) {
            self[OpeningHours.startKey] = newStart
        }
    }
    
    var end: String?{
        get {
            return self[OpeningHours.endKey] as? String
        }
        set(newEnd) {
            self[OpeningHours.endKey] = newEnd
        }
    }
}
