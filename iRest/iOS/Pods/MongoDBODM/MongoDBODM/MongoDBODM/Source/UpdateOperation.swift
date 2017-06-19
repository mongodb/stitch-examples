//
//  UpdateOperation.swift
//  MongoDBODM
//

import Foundation
import StitchCore
import MongoDBService
import ExtendedJson
import StitchLogger
/**
 Use this struct when you wish to perform update operations - run the operation via execute function.
 execute function takes array of UpdatOperationType enums, which represents the update document.
 In the example we changing the last name to "myers" every user in the collection which his name is "mike"
 
     let criteria: Criteria = .equals(field: "name", value: "mike")
     let updateOperation = UpdateOperation<User>(criteria: criteria, mongoDBClient: mongoDBClient)
     let updateOperationType = UpdateOperationType.set(["lastName" : "myers"])
         updateOperation.execute(operations: [updateOperationType], upsert: false, multi: true).response { [weak self] result in
         switch result {
            case .failure(let error):
            self?.handle(error: error)
        }

 */
public struct UpdateOperation <Entity: RootEntity> {
    
    let criteria: Criteria
    let mongoDBClient: MongoDBClientType
    
    public init(criteria: Criteria, mongoDBClient: MongoDBClientType) {
        self.criteria = criteria
        self.mongoDBClient = mongoDBClient
    }
    
    @discardableResult
    public func execute(operations operationType: [UpdateOperationType], upsert: Bool = false, multi: Bool = false) -> StitchTask<Any>{
        do{
            
            guard let classMetaData = Utils.entitiesDictionary[Utils.getIdentifier(type: Entity.self)] else{
                printLog(.error, text: "not class meta data found on class: \(Entity.self)")
                throw OdmError.classMetaDataNotFound
            }
            let databaseName = classMetaData.databaseName
            let collectionName = classMetaData.collectionName
            
            let collection = mongoDBClient.database(named: databaseName).collection(named: collectionName)

           return execute(operations: operationType, collection: collection, upsert: upsert, multi: multi)
        }
        catch{
            return StitchTask<Any>(error: error)
        }
    }
    
    @discardableResult
    internal func execute(operations operationType: [UpdateOperationType],collection: MongoDBService.CollectionType, upsert: Bool = false, multi: Bool = false) -> StitchTask<Any> {
        let queryDocument = criteria.asDocument
        var updateDocument = Document()
        
        for updateOperation in operationType {
            updateDocument[updateOperation.key] = updateOperation.valueAsDocument
        }
        
        return collection.update(query: queryDocument, update: updateDocument, upsert: upsert, multi: multi)
    }
    
}
