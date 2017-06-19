//
//  EmbeddedEntity.swift
//  MongoDBODM
//

import Foundation


import UIKit
import ExtendedJson
import StitchCore

/**
 Represents Embedded Entity in the ODM layer, sublass this Entity and register it if you wish to model you embedded MongoDB document into swift class, an embedded document instance has to be embedded in another BaseEntity class in order to exist in Stitch. it is added and removed from Stitch via its parent entity. Other changes in the Entity is preformed in its update method.
 - note: Register the class in appDelegate - Teacher.registerClass(entityMetaData: TeacherMetaDataImpl())
 */

open class EmbeddedEntity: BaseEntity {
    
    var parent: BaseEntity?
    var keyInParent: String?
    var isEmbeddedInArray: Bool? {
        willSet(embeddedInArray) {
            if embeddedInArray == true{
                setObjectIdIfNeeded()
            }
        }
    }
    
    public override init(document: Document) {
        super.init(document: document)
    }
    
    public override init(){
        super.init()
    }
    
    //MARK: Private
    
    private func setObjectIdIfNeeded() {
        if (self.objectId == nil){
            self.objectId = ObjectId()
        }
    }
    
    //MARK: Public
    /**
     Use this method when you want to update an existing entity - this method would save all the new values that been changed since the entity was fetched
     
         let query = Query<Restaurant>(criteria: criteria, mongoDBClient: mongoDBClient)
         query.find().response { [weak self] result in
         switch result {
         case .success(let result):
            let restaurant = result.first
            var attributes = restaurant.attributes
            attributes.hasParking = false
            attributes.update()
         case .failure(let error):
            self?.handle(error: error)
         }
     
     - note: The update does not cascade to its existing embedded documents, in order to commit changes of an embedded document, you will need to invoke its update directly. For newly created embedded documents, the update of its parent is cascading.
     - note: If there are changes in an array propery (additionals and removals together) this method will execute two seperate calls to Stitch
     
     - returns: result on success, error otherwise. partialSuccess error is called in a case that are two seperate Stitch calls and the second one fails after first successful call
     */
    @discardableResult
    public func update() -> StitchCore.StitchTask<Any> {
        return update(operationTypes: nil, operationTypePrefix: nil, embeddedEntityInArrayObjectId: nil).response(completionHandler: { (result) in
            self.handleOperationResult(stitchResult: result)
        })
    }
    
    //MARK: Internal
    
    internal func embedIn(parent baseEntity: BaseEntity, keyInParent: String, isEmbeddedInArray: Bool){
        parent = baseEntity
        self.keyInParent = keyInParent
        self.isEmbeddedInArray = isEmbeddedInArray
    }
    
    override internal func update(operationTypes: [UpdateOperationType]?, operationTypePrefix: String?, embeddedEntityInArrayObjectId: ObjectId?) -> StitchTask<Any> {
        
        let updateTypesToReturn = operationTypes ?? getUpdateOperationTypes()
        var prefixToReturn = operationTypePrefix ?? ""
        var objectIdToReturn: ObjectId?
        
        guard let keyInParent = keyInParent,
            let parent = parent,
            let isEmbeddedInArray = isEmbeddedInArray else {
                let error = OdmError.updateParametersMissing
                return StitchCore.StitchTask(error: error)
        }
        
        let prefixToAdd = isEmbeddedInArray ? ".$." : "."
        prefixToReturn = keyInParent + prefixToAdd + prefixToReturn
        
        
        if isEmbeddedInArray && embeddedEntityInArrayObjectId == nil {
            if let objectId = objectId {
                objectIdToReturn = objectId
            }
            else{
                return StitchTask(error: OdmError.objectIdNotFound)
            }
        }
        
        return parent.update(operationTypes: updateTypesToReturn, operationTypePrefix: prefixToReturn, embeddedEntityInArrayObjectId: objectIdToReturn)
    }
    
}
