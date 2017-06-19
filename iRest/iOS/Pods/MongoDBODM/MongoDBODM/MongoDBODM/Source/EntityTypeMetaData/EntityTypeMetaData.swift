//
//  EntityTypeMetaData.swift
//  MongoDBODM
//

import Foundation
import ExtendedJson
/**
    Implement this protocol and register it in appDelegate in order to usee ODM Entities
    Implementation example:
 
        class RestaurantMetaDataImp: EntityTypeMetaData {
                static let nameKey          = "name"
                static let addressKey       = "address"
 
             func create(document: Document) -> EmbeddedEntity? {
                return nil
             }
             
             func getEntityIdentifier() -> EntityIdentifier {
                return EntityIdentifier(Restaurant.self)
             }
             
             func getSchema() -> [String : EntityIdentifier] {
             return [RestaurantMetaDataImp.nameKey          : EntityIdentifier(String.self),
             RestaurantMetaDataImp.addressKey       : EntityIdentifier(String.self),
             RestaurantMetaDataImp.phoneKey         : EntityIdentifier(String.self),
                ]
             }
             
             var collectionName: String {
                return "Restaurants"
             }
             
             var databaseName: String {
                return "iRestDB"
             }
     
        }
    Registration example: 
 
             func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
                Restaurant.registerClass(entityMetaData: RestaurantMetaDataImp())
                return true
             }

 
 */
public protocol EntityTypeMetaData {
    ///implement this method in order to recieve embedded mongoDBentities from Stitch result
     func create(document: Document) -> EmbeddedEntity? //for embedded entities
     func getSchema() -> [String : EntityIdentifier]
     func getEntityIdentifier() -> EntityIdentifier
    
    var collectionName: String {get}
    var databaseName: String {get}

}
