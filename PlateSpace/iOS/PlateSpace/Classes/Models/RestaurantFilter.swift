//
//  RestaurantFilter.swift
//  PlateSpace
//

import Foundation

struct RestaurantFilter: OptionSet, CustomStringConvertible {
    let rawValue: Int
    
    static let freeParking   = RestaurantFilter(rawValue: 1 << 0)
    static let openWeekends  = RestaurantFilter(rawValue: 1 << 1)
    static let vegan         = RestaurantFilter(rawValue: 1 << 2)
    static let hasWifi       = RestaurantFilter(rawValue: 1 << 3)
    
    static let all: RestaurantFilter = [.freeParking, .openWeekends, .vegan, .hasWifi]
    static let none: RestaurantFilter = []
    
    var description: String {
        switch self.rawValue {
        case RestaurantFilter.freeParking.rawValue:
            return "Free Parking"
        case RestaurantFilter.openWeekends.rawValue:
            return "Open on weekends"
        case RestaurantFilter.vegan.rawValue:
            return "Vegan Friendly"
        case RestaurantFilter.hasWifi.rawValue:
            return "Has Wifi"
        case RestaurantFilter.all.rawValue:
            return "All Categories"
        default:
            return ""
        }
    }
}
