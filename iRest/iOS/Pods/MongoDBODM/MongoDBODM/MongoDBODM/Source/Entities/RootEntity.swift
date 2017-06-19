//
//  RootEntity.swift
//  MongoDBODM
//

import Foundation
import ExtendedJson
import MongoDBService
import StitchCore
import StitchLogger

/**
 Represents Root Entity in the ODM layer, It corresponds to a root document in a MongoDB collection (The collection that is declared in the EntityMetaData that corresponds to this RootEntity). sublass this Entity with computed variables and register it if you wish to model you root MongoDB document into swift class
 Subclass example:
 
        class Restaurant : RootEntity {
         
         static let nameKey          = "name"
         static let addressKey       = "address"
         static let attributesKey    = "attributes"

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
 
         var attributes: Attributes? {
            get {
                return self[Restaurant.attributesKey] as? Attributes
            }
                set(newAttributes) {
            self[Restaurant.attributesKey] = newAttributes
            }
         }
        }
 */

open class RootEntity: BaseEntity {
    
    //MARK: Properties
    
    var mongoDBClient: MongoDBClientType
    
    private var collection: MongoDBService.CollectionType? {
        if let classMetaData = self.getEntityMetaData(){
            let databaseName = classMetaData.databaseName
            let collectionName = classMetaData.collectionName
            return mongoDBClient.database(named:databaseName).collection(named:collectionName)
        }
        return nil;
    }
    
    //MARK: Init
    
    required public init(document: Document = Document(), mongoDBClient: MongoDBClientType) {
        self.mongoDBClient = mongoDBClient
        super.init(document: document)
    }
    
    //MARK: Static getters
    
    internal static var schema: [String : EntityIdentifier]? {
        
        let classIdentifier = EntityIdentifier(self)
        
        if let entityTypeMetaData = Utils.entitiesDictionary[classIdentifier]{
            return entityTypeMetaData.getSchema()
        }
        return nil
    }
    
    //MARK: Public
    
    /**
     Use this method when you want to save a new created RootEntity to Stitch
     
            var restaurant = Restaurant()
            restaurant.name = "Pita place"
            restaurant.address = "74 Washington st, NY"
            restaurant.save()
     - note: saving the root entity will generate a new document in the collection with its embedded documents (recursively)
     - returns: result on success, error otherwise
     */
    @discardableResult
    public func save() -> StitchCore.StitchTask<Any> {
        if let collection = collection {
            return collection.insert(document: asDocument).response(completionHandler: { stitchResult in
                if let bsonArray = stitchResult.value as? BsonArray , let document = bsonArray.first as? Document, let objectId = document[Utils.Consts.objectIdKey] as? ObjectId  {
                    self.objectId = objectId
                    self.handleOperationResult(stitchResult: stitchResult)
                }
            })
        }
        let error = OdmError.classMetaDataNotFound
        return StitchCore.StitchTask(error: error)
    }
    
    /**
     Use this method when you want to update an existing entity - this method would save all the new values that been changed since the entity was fetched
     
         let query = Query<Restaurant>(criteria: criteria, mongoDBClient: mongoDBClient)
         query.find().response { [weak self] result in
         switch result {
         case .success(let result):
            var restaurant = result.first
            restaurant.name = "Burger place"
            restaurant.update()
         case .failure(let error):
            self?.handle(error: error)
         }

     - note: The update does not cascade to its existing embedded documents, in order to commit changes of an embedded document, you will need to invoke its update directly (see `EmbeddedEntity.update`). For newly created embedded documents, the update of its parent is cascading.
     - note: If there are changes in an array propery (additionals and removals together) this method will execute two seperate calls to Stitch
     
     - returns: result on success, error otherwise. partialSuccess error is called in a case that are two seperate Stitch calls and the second one fails after first successful call
     */
    @discardableResult
    public func update() -> StitchCore.StitchTask<Any> {
        return update(operationTypes: nil, operationTypePrefix: nil, embeddedEntityInArrayObjectId: nil).response(completionHandler: { (result) in
            self.handleOperationResult(stitchResult: result)
        })
    }
    
    /**
     Use this method when you want to delete an existing entity
     
     - returns: result on success, error otherwise.
     */
    @discardableResult
    public func delete() -> StitchCore.StitchTask<Any> {
        let error: OdmError
        if let entityId = self.objectId{
            let queryDocument = Document(key: Utils.Consts.objectIdKey, value: entityId)
            if let collection = collection{
                return collection.delete(query: queryDocument, singleDoc: true)
            }
            else{
                error = OdmError.classMetaDataNotFound
            }
        }
        else{
            printLog(.error, text: "trying to delete an entity without object id")
            error = OdmError.objectIdNotFound
            return StitchCore.StitchTask(error: error)
        }
        
        return StitchCore.StitchTask(error: error)
    }
    
    //MARK: Internal
    
    override internal func update(operationTypes: [UpdateOperationType]?, operationTypePrefix: String?, embeddedEntityInArrayObjectId: ObjectId?) -> StitchTask<Any> {
        let error: OdmError
        var updateTypesToReturn = operationTypes ?? getUpdateOperationTypes()
        
        if let entityId = self.objectId{
            
            var criteriaToReturn = Criteria.equals(field: Utils.Consts.objectIdKey, value: entityId)
            // for embedded entity that is part of an array
            if let embeddedEntityInArrayObjectId = embeddedEntityInArrayObjectId, let operationTypePrefix = operationTypePrefix {
                
                let embeddedEntityFieldName = operationTypePrefix.replacingOccurrences(of: ".$", with: "") + Utils.Consts.objectIdKey
                let embeddedEntityCriteria = Criteria.equals(field: embeddedEntityFieldName, value: embeddedEntityInArrayObjectId)
                criteriaToReturn = criteriaToReturn && embeddedEntityCriteria
            }
            
            // for embedded entity that is held in a simple property
            if let operationTypePrefix = operationTypePrefix {
                updateTypesToReturn = embedPrefixIn(operationTypes: updateTypesToReturn, prefix: operationTypePrefix)
            }
            return executeUpdate(operationTypes: updateTypesToReturn, criteria: criteriaToReturn)
        }
            
        else{
            printLog(.error, text: "trying to update an entity without object id")
            error = OdmError.objectIdNotFound
        }
        
        return StitchCore.StitchTask(error: error)
    }
    
    //MARK: Private
    
    private func getEntityMetaData() -> EntityTypeMetaData?{
        let myType = type(of: self)
        return Utils.entitiesDictionary[Utils.getIdentifier(type:myType)]
    }
    
    private func createEntityCriteria() -> Criteria? {
        if let entityId = self.objectId {
            return Criteria.equals(field: Utils.Consts.objectIdKey, value: entityId)
        }
        return nil
    }
    
    private func embedPrefixIn(operationTypes: [UpdateOperationType], prefix: String) -> [UpdateOperationType] {
        var mutatedOperationTypes: [UpdateOperationType] = []
        
        for operationType in operationTypes {
            var tempOprationType = operationType
            tempOprationType.add(prefix: prefix)
            mutatedOperationTypes.append(tempOprationType)
        }
        
        return mutatedOperationTypes
    }
    
    private func isOperationsContainTwoArrayUpdateOperation(operations: [UpdateOperationType]) -> Bool {
        return operations.contains(.pull([:])) && operations.contains(.push([:]))
    }
    
    
    
    private func executeUpdate(operationTypes: [UpdateOperationType], criteria: Criteria) ->StitchTask<Any> {
        if let collection = collection {
            
            let updateOperation = UpdateOperation(criteria: criteria, mongoDBClient: mongoDBClient)
            
            var firstUpdateOperation = operationTypes
            var secondUpdateOperation: [UpdateOperationType]?
            
            let operationContainsTwoArrays = operationTypes.contains(.pull([:])) && operationTypes.contains(.push([:]))
            
            if operationContainsTwoArrays {
                // split the calls to two calls - push operation as the second operation
                if let indexOfPush = firstUpdateOperation.index(where: { $0 == UpdateOperationType.pull([:]) }) {
                    let pushOperation = firstUpdateOperation.remove(at: indexOfPush)
                    secondUpdateOperation = [pushOperation]
                }
            }
            
            // pull & push are both in update operation - pull will execute second
            if let secondUpdateOperation = secondUpdateOperation {
                let finalTask = StitchTask<Any>()
                
                updateOperation.execute(operations: firstUpdateOperation, collection: collection).response(onQueue: DispatchQueue.global(qos: .utility), completionHandler: { (firstResult) in
                    switch (firstResult) {
                    case .success(_):
                        updateOperation.execute(operations: secondUpdateOperation, collection: collection).response(completionHandler: { (secondResult) in
                            switch (secondResult) {
                            case .success(_):
                                finalTask.result = secondResult
                            case .failure(let error):
                                finalTask.result = .failure(OdmError.partialUpdateSuccess(originalError: error))
                            }
                        })
                    case .failure(_):
                        finalTask.result = firstResult
                    }
                    
                })
                
                return finalTask
            }
                
                //regular execution
            else {
                return updateOperation.execute(operations: firstUpdateOperation, collection: collection)
            }
            
        }
        else{
            print("trying to update without a class metadata registration")
            let error = OdmError.classMetaDataNotFound
            return StitchCore.StitchTask(error: error)
        }
    }
    
}
