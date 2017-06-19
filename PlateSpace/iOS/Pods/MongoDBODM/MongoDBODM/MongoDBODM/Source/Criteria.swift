//
//  Criteria.swift
//  MongoDBODM
//

import Foundation
import ExtendedJson
/**
  Represents a query document in the ODM Layer, acts as a parameter in Query, Aggregation and UpdateOperation calls. the following example shows how to create criteria for a person who name is George and his age above 18
 
         let nameCriteria: Criteria = .equals(field: "name", value: "George")
         let ageCriteria: Criteria = .greaterThan(field: "age", value: 18)
         let criteria = nameCriteria && ageCriteria
 */
public indirect enum Criteria {
    
    case contains(field: String, value: NSRegularExpression)
    
    //Comparison Query Operators
    case greaterThan(field: String, value: ExtendedJsonRepresentable)
    
    case equals(field: String, value: ExtendedJsonRepresentable)
    
    case greaterThanOrEqual(field: String, value: ExtendedJsonRepresentable)
    
    case lessThan(field: String, value: ExtendedJsonRepresentable)
    
    case lessThanOrEqual(field: String, value: ExtendedJsonRepresentable)
    
    case notEqual(field: String, value: ExtendedJsonRepresentable)
    
    case `in`(field: String, values: [ExtendedJsonRepresentable])
    
    case nin(field: String, values: [ExtendedJsonRepresentable])
    
    //Logical Query Operators
    case and([Criteria])
    
    case or([Criteria])
    
    case not(Criteria)
    
    case nor([Criteria])
    
    //Evaluation Query Operators
    case text(search: String, language: String?, caseSensitive: Bool?, diacriticSensitive: Bool?)
    
    //Element Query Operators
    case exists(field: String, value: Bool)
    
    
    public var asDocument: Document {
        switch self {
        case .greaterThan(let field, let value):
            return Document(key: field, value: Document(key: key, value: value))
            
        case .contains(let field, let value):
            return Document(key: field, value: value)
            
        case .equals(let field, let value):
            return Document(key: field, value: Document(key: key, value: value))
            
        case .and(let criterias):
            return Document(key: key, value: BsonArray(array: criterias.map{ $0.asDocument} ))
            
        case .or(let criterias):
            return Document(key: key, value: BsonArray(array: criterias.map{ $0.asDocument }))
            
        case .greaterThanOrEqual(let field, let value):
            return Document(key: field, value: Document(key: key, value: value))
            
        case .lessThan(let field, let value):
            return Document(key: field, value: Document(key: key, value: value))
            
        case .lessThanOrEqual(let field, let value):
            return Document(key: field, value: Document(key: key, value: value))
            
        case .notEqual(let field, let value):
            return Document(key: field, value: Document(key: key, value: value))
            
        case .in(let field, let values):
            return Document(key: field, value: Document(key: key, value: BsonArray(array: values)))
            
        case .nin(let field, let values):
            return Document(key: field, value: Document(key: key, value: BsonArray(array: values)))
            
        case .not(let criteria):
            let criteriaDoc = criteria.asDocument
            var notCriteria = Document()
            for (key, value) in criteriaDoc {
                notCriteria[key] = Document(key: self.key, value: value)
            }
            
            return notCriteria
            
        case .nor(let criterias):
            return Document(key: key, value: BsonArray(array: criterias.map{ $0.asDocument }))
            
        case .text(let search, let language ,let caseSensitive, let diacriticSensitive):
            var textParams = Document()
            textParams["$search"] = search
            if let language = language {
                textParams["$language"] = language
            }
            if let caseSensitive = caseSensitive {
                textParams["$caseSensitive"] = caseSensitive
            }
            if let diacriticSensitive = diacriticSensitive {
                textParams["$diacriticSensitive"] = diacriticSensitive
            }
            return Document(dictionary: [key : textParams])
            
        case .exists(let field, let value):
            return Document(key: field, value: Document(key: key, value: value))
            
        }
        
    }
    
    
    
    // MARK: - Helpers
    
    private var key: String {
        switch self {
        case .greaterThan:
            return "$gt"
        case .equals:
            return "$eq"
        case .and:
            return "$and"
        case .or:
            return "$or"
        case .greaterThanOrEqual:
            return "$gte"
        case .lessThan:
            return "$lt"
        case .lessThanOrEqual:
            return "$lte"
        case .notEqual:
            return "$ne"
        case .in:
            return "$in"
        case .nin:
            return "$nin"
        case .not:
            return "$not"
        case .nor:
            return "$nor"
        case .text:
            return "$text"
        case .exists:
            return "$exists"
            
        case .contains:
            return ""
        }
    }
}


// MARK: - Operators

public func &&(lhs: Criteria, rhs: Criteria) -> Criteria {
    
    // check if one of the criterias (or both) is an `and` criteria, if so, append the other criteria (or its content) to it.
    if case .and(var lhsAnd) = lhs {
        if case .and(let rhsAnd) = rhs {
            lhsAnd.append(contentsOf: rhsAnd)
            return .and(lhsAnd)
        }
        else {
            lhsAnd.append(rhs)
            return .and(lhsAnd)
        }
    }
    else if case .and(var rhsAnd) = rhs {
        rhsAnd.append(lhs)
        return .and(rhsAnd)
    }
    
    // both criterias are not an `and` criteria so create a new `and` criteria out of them
    return .and([lhs, rhs])
}

public func &&(lhs: Criteria?, rhs: Criteria?) -> Criteria? {
    if let lhs = lhs {
        return rhs.map({ lhs && $0 }) ?? lhs
    }
    return rhs
}

public func ||(lhs: Criteria, rhs: Criteria) -> Criteria {
    
    // check if one of the criterias (or both) is an `or` criteria, if so, append the other criteria (or its content) to it.
    if case .or(var lhsOr) = lhs {
        if case .or(let rhsOr) = rhs {
            lhsOr.append(contentsOf: rhsOr)
            return .or(lhsOr)
        }
        else {
            lhsOr.append(rhs)
            return .or(lhsOr)
        }
    }
    else if case .or(var rhsOr) = rhs {
        rhsOr.append(lhs)
        return .or(rhsOr)
    }
    
    // both criterias are not an `or` criteria so create a new `or` criteria out of them
    return .or([lhs, rhs])
}

public func ||(lhs: Criteria?, rhs: Criteria?) -> Criteria? {
    if let lhs = lhs {
        return rhs.map({ lhs || $0 }) ?? lhs
    }
    return rhs
}

public prefix func !(criteria: Criteria) -> Criteria {
    return .not(criteria)
}


