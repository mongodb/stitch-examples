//
//  Projection.swift
//  MongoDBODM
//

import Foundation
import ExtendedJson

struct Projection {
    
    fileprivate var projecting: [String]
    
    // MARK: - Init
    
    init(_ projecting: [String]) {
        self.projecting = projecting
    }
    
    var asDocument: Document {
        return reduce(Document()) { (result, field) -> Document in
            var result = result
            result[field] = true
            return result
        }
    }
}

extension Projection: ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: String...) {
        projecting = elements
    }
}

// MARK: - Collection

extension Projection: Collection {
    
    public typealias Index = Int
    
    public var startIndex: Index {
        return projecting.startIndex
    }
    
    public var endIndex: Index {
        return projecting.endIndex
    }
    
    public func makeIterator() -> IndexingIterator<[String]> {
        return projecting.makeIterator()
    }
    
    public subscript(index:Int) -> String {
        get {
            return projecting[index]
        }
        set(newElement) {
            projecting.insert(newElement, at: index)
        }
    }
    
    public func index(after i: Index) -> Index {
        return projecting.index(after: i)
    }
    
    // MARK: Mutating
    
    public mutating func append(_ newElement: String) {
        projecting.append(newElement)
    }
    
    public mutating func remove(at index: Int) {
        projecting.remove(at: index)
    }
}
