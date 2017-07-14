//
//  RestaurantLocationMetaDataImp.swift
//  PlateSpace
//
//  Created by Ofir Zucker on 08/05/2017.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import Foundation
import ExtendedJson
import MongoDBService
import MongoDBODM

class RestaurantLocationMetaDataImp: EntityTypeMetaData {
    /// default behavior of root entity
    func create(document: Document) -> EmbeddedEntity? {
        let location = RestaurantLocation(document: document)
        return location
    }
    
    func getEntityIdentifier() -> EntityIdentifier {
        return EntityIdentifier(RestaurantLocation.self)
    }
    
    func getSchema() -> [String : EntityIdentifier] {
        return [RestaurantLocation.typeKey         : EntityIdentifier(String.self),
                RestaurantLocation.coordinatesKey  : EntityIdentifier(Double.self)
        ]
    }
    
    var collectionName: String {
        return MongoDBManager.collectionNameRestaurants
    }
    
    var databaseName: String {
        return MongoDBManager.databaseName
    }
    
    
}
