//
//  OpeningHoursMetaDataImp.swift
//  PlateSpace
//
//  Created by Ofir Zucker on 08/05/2017.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import Foundation
import ExtendedJson
import MongoDBService
import MongoDBODM

class OpeningHoursMetaDataImp: EntityTypeMetaData {
    /// default behavior of root entity
    func create(document: Document) -> EmbeddedEntity? {
        let openingHours = OpeningHours(document: document)
        return openingHours
    }
    
    func getEntityIdentifier() -> EntityIdentifier {
        return EntityIdentifier(OpeningHours.self)
    }
    
    func getSchema() -> [String : EntityIdentifier] {
        return [OpeningHours.startKey  : EntityIdentifier(String.self),
                OpeningHours.endKey    : EntityIdentifier(String.self)
        ]
    }
    
    var collectionName: String {
        return MongoDBManager.collectionNameRestaurants
    }
    
    var databaseName: String {
        return MongoDBManager.databaseName
    }

    
}
