//
//  RestaurantLocation.swift
//  SoLoMoSample
//
//  Created by Ofir Zucker on 08/05/2017.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import Foundation
import CoreLocation
import MongoExtendedJson
import MongoDB
import MongoBaasODM

class RestaurantLocation: EmbeddedMongoEntity {
    
    static let typeKey        = "type"
    static let coordinatesKey = "coordinates"
    
    var type: String?{
        get {
            return self[RestaurantLocation.typeKey] as? String
        }
        set(newType) {
            self[RestaurantLocation.typeKey] = newType
        }
    }
    
    var coordinates: BsonArray?{
        get {
            return self[RestaurantLocation.coordinatesKey] as? BsonArray
        }
        set(newCoordinates) {
            self[RestaurantLocation.coordinatesKey] = newCoordinates
        }
    }
    
    var coordinate: CLLocationCoordinate2D? {
        var coordinate: CLLocationCoordinate2D?
        
        if let coordinates = coordinates,
            coordinates.count == 2,
            let longitude = coordinates[0] as? Double,
            let latitude = coordinates[1] as? Double {
            coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        return coordinate
    }
}
