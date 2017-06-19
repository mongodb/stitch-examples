//
//  Restaurant.swift
//  SoLoMoSample
//
//  Created by Miko Halevi on 3/8/17.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import Foundation
import ExtendedJson
import MongoDBService
import MongoDBODM

class Restaurant : RootEntity, Equatable {
    
    static let nameKey          = "name"
    static let addressKey       = "address"
    static let phoneKey         = "phone"
    static let imageUrlKey      = "image_url"
    static let websiteKey       = "website"
    static let averageRatingKey = "averageRating"
    static let numberOfRatesKey = "numberOfRates"
    static let openingHoursKey  = "openingHours"
    static let attributesKey    = "attributes"
    static let locationKey      = "location"
    
    var name: String?{
        get {
            return self[Restaurant.nameKey] as? String
        }
        set(newName) {
            self[Restaurant.nameKey] = newName
        }
    }
    
    var address: String?{
        get {
            return self[Restaurant.addressKey] as? String
        }
        set(newAddress) {
            self[Restaurant.addressKey] = newAddress
        }
    }
    
    var phone: String?{
        get {
            return self[Restaurant.phoneKey] as? String
        }
        set(newPhone) {
            self[Restaurant.phoneKey] = newPhone
        }
    }
    
    var image_url: String?{
        get {
            return self[Restaurant.imageUrlKey] as? String
        }
        set(newImageUrl) {
            self[Restaurant.imageUrlKey] = newImageUrl
        }
    }
    
    var website: String?{
        get {
            return self[Restaurant.websiteKey] as? String
        }
        set(newWebsite) {
            self[Restaurant.websiteKey] = newWebsite
        }
    }
    
    var averageRating: Double?{
        get {
            return self[Restaurant.averageRatingKey] as? Double
        }
        set(newAverageRating) {
            self[Restaurant.averageRatingKey] = newAverageRating
        }
    }
    
    var numberOfRates: Double?{
        get {
            return self[Restaurant.numberOfRatesKey] as? Double
        }
        set(newNumberOfRates) {
            self[Restaurant.numberOfRatesKey] = newNumberOfRates
        }
    }

    var openingHours: OpeningHours? {
        get {
            return self[Restaurant.openingHoursKey] as? OpeningHours
        }
        set(newOpeningHours) {
            self[Restaurant.openingHoursKey] = newOpeningHours
        }
    }
    
    var attributes: Attributes? {
        get {
            return self[Restaurant.attributesKey] as? Attributes
        }
        set(newAttributes) {
            self[Restaurant.attributesKey] = newAttributes
        }
    }

    var location: RestaurantLocation? {
        get {
            return self[Restaurant.locationKey] as? RestaurantLocation
        }
        set(newLocation) {
            self[Restaurant.locationKey] = newLocation
        }
    }
}

//MARK: - Equatable

func ==(lhs: Restaurant, rhs: Restaurant) -> Bool {
    return lhs.objectId == rhs.objectId
}
