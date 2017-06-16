//
//  Attributes.swift
//  SoLoMoSample
//
//  Created by Ofir Zucker on 08/05/2017.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import Foundation
import MongoExtendedJson
import MongoDB
import MongoBaasODM

class Attributes: EmbeddedMongoEntity {
    
    static let hasParkingKey     = "hasParking"
    static let veganFriendlyKey  = "veganFriendly"
    static let openOnWeekendsKey = "openOnWeekends"
    static let hasWifiKey        = "hasWifi"
    
    var hasParking: Bool?{
        get {
            return self[Attributes.hasParkingKey] as? Bool
        }
        set(newHasParking) {
            self[Attributes.hasParkingKey] = newHasParking
        }
    }
    
    var veganFriendly: Bool?{
        get {
            return self[Attributes.veganFriendlyKey] as? Bool
        }
        set(newVeganFriendly) {
            self[Attributes.veganFriendlyKey] = newVeganFriendly
        }
    }
    
    var openOnWeekends: Bool?{
        get {
            return self[Attributes.openOnWeekendsKey] as? Bool
        }
        set(newOpenOnWeekends) {
            self[Attributes.openOnWeekendsKey] = newOpenOnWeekends
        }
    }

    var hasWifi: Bool?{
        get {
            return self[Attributes.hasWifiKey] as? Bool
        }
        set(newHasWifi) {
            self[Attributes.hasWifiKey] = newHasWifi
        }
    }

}
