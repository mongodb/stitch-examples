//
//  RestaurantMetaDataImp.swift
//  SoLoMoSample
//
//  Created by Ofir Zucker on 08/05/2017.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import Foundation
import ExtendedJson
import MongoDBService
import MongoDBODM

class RestaurantMetaDataImp: EntityTypeMetaData {
    
    /// default behavior of root entity
    func create(document: Document) -> EmbeddedEntity? {
        return nil
    }
    
    func getEntityIdentifier() -> EntityIdentifier {
        return EntityIdentifier(Restaurant.self)
    }
    
    func getSchema() -> [String : EntityIdentifier] {
        return [Restaurant.nameKey          : EntityIdentifier(String.self),
                Restaurant.addressKey       : EntityIdentifier(String.self),
                Restaurant.phoneKey         : EntityIdentifier(String.self),
                Restaurant.imageUrlKey      : EntityIdentifier(String.self),
                Restaurant.websiteKey       : EntityIdentifier(String.self),
                Restaurant.averageRatingKey : EntityIdentifier(Double.self),
                Restaurant.numberOfRatesKey : EntityIdentifier(Double.self),
                Restaurant.openingHoursKey  : EntityIdentifier(OpeningHours.self),
                Restaurant.attributesKey    : EntityIdentifier(Attributes.self),
                Restaurant.locationKey      : EntityIdentifier(RestaurantLocation.self)
                ]
        
    }
    
    var collectionName: String {
        return MongoDBManager.collectionNameRestaurants
    }
    
    var databaseName: String {
        return MongoDBManager.databaseName
    }
    

}
