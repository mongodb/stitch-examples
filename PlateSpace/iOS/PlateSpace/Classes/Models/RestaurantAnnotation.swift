//
//  RestaurantAnnotation.swift
//  PlateSpace
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
