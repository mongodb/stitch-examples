//
//  AttributesMetaDataImp.swift
//  PlateSpace
//
//  Created by Ofir Zucker on 08/05/2017.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import Foundation
import ExtendedJson
import MongoDBService
import MongoDBODM

class AttributesMetaDataImp: EntityTypeMetaData {
    /// default behavior of root entity
    func create(document: Document) -> EmbeddedEntity? {
        let attributes = Attributes(document: document)
        return attributes
    }
    
    func getEntityIdentifier() -> EntityIdentifier {
        return EntityIdentifier(Attributes.self)
    }
    
    func getSchema() -> [String : EntityIdentifier] {
        return [Attributes.hasParkingKey       : EntityIdentifier(Bool.self),
                Attributes.veganFriendlyKey    : EntityIdentifier(Bool.self),
                Attributes.openOnWeekendsKey   : EntityIdentifier(Bool.self),
                Attributes.hasWifiKey          : EntityIdentifier(Bool.self)
        ]
        
    }
    
    var collectionName: String {
        return MongoDBManager.collectionNameRestaurants
    }
    
    var databaseName: String {
        return MongoDBManager.databaseName
    }

    
}
