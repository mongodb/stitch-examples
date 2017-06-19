//
//  Utils.swift
//  MongoDBODM
//

import Foundation

class Utils {
    
    static var entitiesDictionary: [EntityIdentifier : EntityTypeMetaData] = [:]
    
    public static func getIdentifier(any : Any) -> EntityIdentifier{
        return EntityIdentifier(type(of: any))
    }
    
    public static func getIdentifier(type : Any.Type) -> EntityIdentifier{
        return EntityIdentifier(type)
    }
    
    internal struct Consts{
        static let objectIdKey = "_id"
    }
    
}
