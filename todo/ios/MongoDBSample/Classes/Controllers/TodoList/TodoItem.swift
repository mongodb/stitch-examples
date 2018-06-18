//
//  TodoItem.swift
//  MongoDBSample
//

import Foundation
import MongoSwiftMobile

struct TodoItem: Equatable {
    
    struct Keys {
        static let objectIdKey =    "_id"
        static let textKey =        "text"
        static let checkedKey =     "checked"
        
    }
    
    let objectId: ObjectId
    let text: String
    let checked: Bool
    
    //MARK: - Init
    
    init?(document: Document) {
        
        guard let objectId = document[Keys.objectIdKey] as? ObjectId,
            let text = document[Keys.textKey] as? String else {
            return nil
        }
        
        self.objectId = objectId
        self.text = text
        self.checked = document[Keys.checkedKey] as? Bool ?? false
    }
    
    // MARK: - Equatable
    
    public static func ==(lhs: TodoItem, rhs: TodoItem) -> Bool {
        return lhs.objectId.oid == rhs.objectId.oid
    }
}
