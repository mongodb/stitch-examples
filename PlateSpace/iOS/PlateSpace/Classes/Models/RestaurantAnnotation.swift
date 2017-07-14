//
//  RestaurantAnnotation.swift
//  PlateSpace
//
//  Created by Ofir Zucker on 08/05/2017.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import MapKit

class RestaurantAnnotation: NSObject, MKAnnotation {
    
    let restaurant: Restaurant
    
    init(withRestaurant restaurant: Restaurant) {
       self.restaurant = restaurant
    }
    
    // MARK: - MKAnnotation
    
    public var coordinate: CLLocationCoordinate2D { return restaurant.location?.coordinate ?? CLLocationCoordinate2D()}
    public var title: String? { return restaurant.name }
}
