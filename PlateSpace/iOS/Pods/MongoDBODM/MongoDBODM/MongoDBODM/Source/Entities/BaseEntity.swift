//
//  BaseEntity.swift
//  MongoDBODM
//

import Foundation
import ExtendedJson
import StitchCore
import StitchLogger

/**
 Represents a MongoDB Entity in the ODM layer, Do not sublass directy from this class - you should subclass RootEntity or EmbeddedEntity
 - Note: This class represents a MongoDB/stitch Document as it is in the DB, Therefore the property names must be identical to the document fields in the DB.
 */

open class BaseEntity : ExtendedJsonRepresentable {
    
    //MARK: Properties
    
    internal var properties: [String : ExtendedJsonRepresentable?] = [:]
    internal var modifiedProperties: [String : ExtendedJsonRepresentable?] = [:]
    
    private var arrayRemovals: [String : [ExtendedJsonRepresentable]] = [:]
    private var arrayAdditionals: [String : [ExtendedJsonRepresentable]] = [:]
    
    //MARK: Init
    
    /**
     Empty constructor - use this contstructor in order to create entities that are created for the first time and are not yet stored in stitch.
     
     - Returns: BaseEntity.
     */
    public init(){}
    
    /**
     This constructor should be used in order to create an entity based on a document returned from Stitch.
     
     - parameter document: The document fetched from Stitch
     
     - Returns: BaseEntity.
     */
    public init(document: Document) {
        let myClassIdentifier = Utils.getIdentifier(any: self)
        if let myEntityMetadata = Utils.entitiesDictionary[myClassIdentifier]{
            
            for (key, value) in document{
                if let value = value as? Document {
                    if let propertyObjectIdentifier = myEntityMetadata.getSchema()[key], let embeddedEntityMetaData = Utils.entitiesDictionary[propertyObjectIdentifier] {
                        let embeddedEntityValue = embeddedEntityMetaData.create(document: value)
                        
                        embeddedEntityValue?.embedIn(parent: self, keyInParent: key, isEmbeddedInArray: false)
                        properties[key] = embeddedEntityValue
                    }
                    else{
                        printLog(LogLevel.warning, text: "While parsing \(key) in a document received an embedded document that is not mapped by the entity meta data")
                    }
                }
                else if let value = value as? BsonArray {
                    var bsonArray = BsonArray()
                    
                    for item in value{
                        if let item = item as? Document {
                            if let propertyObjectIdentifier = myEntityMetadata.getSchema()[key], let embeddedEntityMetaData = Utils.entitiesDictionary[propertyObjectIdentifier] {
                                if let embeddedEntityValue = embeddedEntityMetaData.create(document: item){
                                    embeddedEntityValue.embedIn(parent: self, keyInParent: key, isEmbeddedInArray: true)
                                    bsonArray.append(embeddedEntityValue)
                                }
                            }
                            else{
                                printLog(LogLevel.warning, text: "While parsing an array (\(key))o f a document received an embedded document that is not mapped by the entity meta data")
                            }
                        }
                        else{
                            bsonArray.append(item)
                        }
                    }
                    properties[key] = bsonArray
                    
                }
                    
                else if value is NSNull{
                    properties[key] = nil
                }
                    
                else{
                    properties[key] = value
                }
            }
        }
    }
    
    //MARK: Public properties
    /**
     Getter for '_id' field, returns the entity objectId if exists.
     - important: The id will exist in the following cases:
     - RootEntity that was added to Stitch
     - EmbeddedEntity that is embedded in an array and was added to Stitch
     
     */
    internal(set) public var objectId: ExtendedJson.ObjectId? {
        get{
            if let objectId = self[Utils.Consts.objectIdKey] as? ObjectId {
                return objectId
            }
            return nil
        }
        set(newObjectId){
            if let newObjectId = newObjectId{
                self[Utils.Consts.objectIdKey] = newObjectId
            }
        }
    }
    
    //MARK: Inherit
    
    internal func update(operationTypes: [UpdateOperationType]?, operationTypePrefix: String?, embeddedEntityInArrayObjectId: ObjectId?) -> StitchTask<Any> {
        let error = OdmError.classMetaDataNotFound
        return StitchCore.StitchTask(error: error)
    }
    
    internal func getUpdateOperationTypes() -> [UpdateOperationType] {
        var result: [UpdateOperationType] = []
        
        var setDictionary: [String : ExtendedJsonRepresentable] = [:]
        var unsetDictionary: [String : ExtendedJsonRepresentable] = [:]
        var pushDictionary: [String : ExtendedJsonRepresentable] = [:]
        var pullDictionary: [String : ExtendedJsonRepresentable] = [:]
        
        let modifiedArrayKeys: Set<String> = Set(arrayRemovals.keys).union(Set(arrayAdditionals.keys))
        
        for (key,value) in arrayAdditionals {
            pushDictionary[key] = Document(key: "$each", value: BsonArray(array: value))
        }
        
        for (key,value) in arrayRemovals {
            if value.first is EmbeddedEntity {
                var criteria: Criteria?
                for entity in value {
                    if let entity = entity as? EmbeddedEntity, let objectId = entity.objectId {
                        criteria = criteria || .equals(field: Utils.Consts.objectIdKey, value: objectId)
                    }
                }
                pullDictionary[key] = criteria?.asDocument
            } else {
                pullDictionary[key] = Document(key: "$in", value: BsonArray(array: value))
            }
        }
        
        for (key,value) in modifiedProperties {
            
            if modifiedArrayKeys.contains(key) {
                continue
            }
            
            if value == nil {
                unsetDictionary[key] = ""
            }
            else  {
                setDictionary[key] = value
            }
        }
        
        if !setDictionary.isEmpty {
            result.append(.set(setDictionary))
        }
        if !pushDictionary.isEmpty {
            result.append(.push(pushDictionary))
        }
        if !pullDictionary.isEmpty {
            result.append(.pull(pullDictionary))
        }
        if !unsetDictionary.isEmpty {
            result.append(.unset(unsetDictionary))
        }
        
        
        return result
    }
    
    
    internal func handleOperationResult(stitchResult: StitchResult<Any>) {
        switch (stitchResult) {
        case .failure(let error):
            if let error = error as? OdmError{
                switch error {
                case .partialUpdateSuccess:
                    revertProperties(partially: true)
                default: break
                    // properties stays as before - do nothing
                }
            }
            
        case .success(_):
            revertProperties(partially: false)
        }
    }
    
    
    //MARK: subscript
    /**
     Accesses the Entity associated properties with the given key for reading and writing. usually from computed variables from your class
     Writing `nil` removes the property value from the Entity.
     
     - parameter key: Property name
     */
    public subscript(key: String) -> ExtendedJsonRepresentable?{
        get{
            if let value = modifiedProperties[key] {
                return value
            }
            if let value = properties[key]{
                return value
            }
            return nil
        }
        set{
            modifiedProperties[key] = newValue
            if let newValue = newValue as? EmbeddedEntity{
                newValue.embedIn(parent: self, keyInParent: key, isEmbeddedInArray: false)
            }
            else if let newValue = newValue as? BsonArray {
                for jsonExtendable in newValue {
                    if let embeddedEntity = jsonExtendable as? EmbeddedEntity {
                        embeddedEntity.embedIn(parent: self, keyInParent: key, isEmbeddedInArray: true)
                    }
                }
            }
        }
        
    }
    
    //MARK: Public
    
    /**
     Use this method to easily convert a property that is stored as a BsonArray to an array of a specific type.
     
     - parameter bsonArray: The stored bsonArray.
     
     - throws: OdmError in case that the BsonArray contains elements with a type that does not match the provided type
     
     - Returns: An empty array if the original bson-array is nil or empty, otherwise return the corresponding array.
     
     */
    public func asArray<T>(bsonArray: BsonArray?) throws -> [T]{
        if let bsonArray = bsonArray{
            return try bsonArray.map({ (element) -> T in
                if let converted = element as? T {
                    return converted
                }
                throw OdmError.corruptedData(message: "Type mismatch")
            })
        }
        return []
    }
    
    /**
     Use this method to add item to an array.
     
     - parameter path: The array's field name in the entity
     - parameter item: The item that will be added to the array
     
     - Returns: True upon successfull operation, An operation will fail if the field name corresponds to a field which is not a BsonArray type
     
     */
    
    @discardableResult
    public func addToArray(path: String, item: ExtendedJsonRepresentable) -> Bool {
        return modifyArray(path: path, item: item, toAdd: true)
    }
    
    /**
     Use this method to remove item from an array.
     
     - parameter path: The array's field name in the entity
     - parameter item: The item that will be removed from the array
     
     - Returns: True upon successfull operation, An operation will fail if the field name corresponds to a field which is not a BsonArray type or that there is no matching item in the BsonArray
     */
    
    @discardableResult
    public func removeFromArray(path: String, item: ExtendedJsonRepresentable) -> Bool {
        return modifyArray(path: path, item: item, toAdd: false)
    }
    
    //MARK: Private
    
    private func modifyArray(path: String, item: ExtendedJsonRepresentable, toAdd: Bool) -> Bool {
        
        //add the item to the currect dictionary
        var modifyDictionary = toAdd ? arrayAdditionals : arrayRemovals
        var modifyArray = modifyDictionary[path] ?? []
        modifyArray.append(item)
        
        //change the current property and save to current dictionary
        let property = getOrGenerateArrayProperty(propertyName: path)
        if var property = property {
            if toAdd {
                property.append(item)
                
                if let item = item as? EmbeddedEntity {
                    item.embedIn(parent: self, keyInParent: path, isEmbeddedInArray: true)
                }
                
                arrayAdditionals[path] = modifyArray
            }
            else {
                let itemWasRemoved = property.remove(object: item)
                if !itemWasRemoved {
                    printLog(.error, text: "item \(item) was not found in the array :\(path) ")
                    return false
                }
                arrayRemovals[path] = modifyArray
                
            }
            
            modifiedProperties[path] = property
        }
        else {
            printLog(.error, text: "Type mismatch, the object in the path: \(path) is not BsonArray type ")
            return false
        }
        
        return true
    }
    
    private func getOrGenerateArrayProperty(propertyName: String) -> BsonArray? {
        let property = getProperty(propertyName: propertyName) ?? BsonArray()
        if let property = property as? BsonArray {
            return property
        }
        return nil
    }
    
    private func getProperty(propertyName: String) -> ExtendedJsonRepresentable? {
        if let property = modifiedProperties[propertyName] {
            return property
        }
        if let propery = properties[propertyName] {
            return propery
        }
        return nil
    }
    
    private func revertProperties(partially: Bool) {
        let arrayRemovalProperties = arrayRemovals.keys
        for (key, value) in modifiedProperties {
            // only if its complete removal or that property is not an array - revert the property
            if !partially || !arrayRemovalProperties.contains(key) {
                properties[key] = value
            }
        }
        
        modifiedProperties = [:]
        arrayRemovals = [:]
        arrayAdditionals = [:]
    }
    
    //MARK: Document
    
    var asDocument: Document {
        var document = Document()
        var deletedKeys: [String] = []
        
        for (key, value) in modifiedProperties {
            if value == nil {
                deletedKeys.append(key)
            }
            else {
                document[key] = value
            }
        }
        
        for (key, value) in properties{
            if document[key] == nil, value != nil,  !deletedKeys.contains(key) {
                document[key] = value
            }
        }
        return document
    }
    
    //MARK: ExtendedJsonRepresentable
    
    public var toExtendedJson: Any {
        return asDocument.toExtendedJson
    }
    
    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? EmbeddedEntity{
            return self === other
        }
        return false
    }
    
    //MARK: Static Registration
    
    /**
     Use this method to register you entity, this action is mandatory for using Stitch ODM.
     for further explenation check EntityTypeMetaData
     
     - important: call this method in AppDelegate 'didFinishLaunchingWithOptions' method
     
     - parameter entityMetaData: The correspond entity meta data class
     
     */
    
    public static func registerClass(entityMetaData: EntityTypeMetaData)  {
        let classIdentifier = entityMetaData.getEntityIdentifier()
        Utils.entitiesDictionary[classIdentifier] = entityMetaData
    }
    
}
