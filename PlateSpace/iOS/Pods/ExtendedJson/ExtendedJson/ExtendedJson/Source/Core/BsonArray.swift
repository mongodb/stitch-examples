//
//  BsonArray.swift
//  ExtendedJson
//

import Foundation

public struct BsonArray {
    
    fileprivate var underlyingArray: [ExtendedJsonRepresentable] = []
    
    public init(){}
    
    public init(array: [ExtendedJsonRepresentable]) {
        underlyingArray = array
    }
    
    public mutating func remove(object: ExtendedJsonRepresentable) -> Bool {
        for i in 0..<underlyingArray.count {
            let currentObject = underlyingArray[i]
            if currentObject.isEqual(toOther: object) {
                underlyingArray.remove(at: i)
                return true
            }
        }
        return false
    }
}

// MARK: - Collection

extension BsonArray: Collection {
    
    public typealias Index = Int
    
    public var startIndex: Index {
        return underlyingArray.startIndex
    }
    
    public var endIndex: Index {
        return underlyingArray.endIndex
    }
    
    public func makeIterator() -> IndexingIterator<[ExtendedJsonRepresentable]> {
        return underlyingArray.makeIterator()
    }
    
    public subscript(index:Int) -> ExtendedJsonRepresentable {
        get {
            return underlyingArray[index]
        }
        set(newElement) {
            underlyingArray.insert(newElement, at: index)
        }
    }
    
    public func index(after i: Index) -> Index {
        return underlyingArray.index(after: i)
    }
    
    // MARK: Mutating
    
    public mutating func append(_ newElement: ExtendedJsonRepresentable) {
        underlyingArray.append(newElement)
    }
    
    public mutating func remove(at index: Int) {
        underlyingArray.remove(at: index)
    }

}

extension BsonArray: ExpressibleByArrayLiteral{
    public init(arrayLiteral elements: ExtendedJsonRepresentable...) {
        self.init()
        underlyingArray = elements
    }
}
