//
//  CollectionType.swift
//  MongoDBService
//

import Foundation
import StitchCore
import ExtendedJson

public protocol CollectionType {
            
    @discardableResult
    func find(query: Document, projection: Document?, limit: Int?) -> StitchTask<[Document]>
    
    @discardableResult
    func update(query: Document, update: Document?, upsert: Bool, multi: Bool) -> StitchTask<Any>
    
    @discardableResult
    func insert(document: Document) ->  StitchTask<Any>
    
    @discardableResult
    func insert(documents: [Document]) ->  StitchTask<Any>
    
    @discardableResult
    func delete(query: Document, singleDoc: Bool) -> StitchTask<Any>
    
    @discardableResult
    func count(query: Document) -> StitchTask<Int>
    
    @discardableResult
    func aggregate(pipeline: [Document]) -> StitchTask<Any>
}


// MARK: - Default Values

extension CollectionType {
    
    @discardableResult
    public func find(query: Document, projection: Document? = nil, limit: Int? = nil) -> StitchTask<[Document]> {
        return find(query: query, projection: projection, limit: limit)
    }
    
    @discardableResult
    public func update(query: Document, update: Document? = nil, upsert: Bool = false, multi: Bool = false) -> StitchTask<Any> {
        return self.update(query: query, update: update, upsert: upsert, multi: multi)
    }
    
    @discardableResult
    public func delete(query: Document, singleDoc: Bool = true) -> StitchTask<Any> {
        return delete(query: query, singleDoc: singleDoc)
    }
}
