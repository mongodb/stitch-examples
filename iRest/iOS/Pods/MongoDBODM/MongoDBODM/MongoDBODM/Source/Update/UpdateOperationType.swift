//
//  UpdateOperationType.swift
//  MongoDBODM
//

import Foundation
import ExtendedJson
/**
Represents the updateDucument in the UpdateOperation call, takes as argument dictionary of fields and values. The UpdateOperation call takes an array of UpdateOperationType in order to execute.  
 */
public enum UpdateOperationType {
    
    case set([String : ExtendedJsonRepresentable?])
    case unset([String : ExtendedJsonRepresentable?])
    case push([String : ExtendedJsonRepresentable?])
    case pull([String : ExtendedJsonRepresentable?])
    case pop([String : ExtendedJsonRepresentable?])
    case inc([String : ExtendedJsonRepresentable?])
    case mul([String : ExtendedJsonRepresentable?])
    case min([String : ExtendedJsonRepresentable?])
    case max([String : ExtendedJsonRepresentable?])
    
    //MARK: Private
    
    private struct Consts{
        static let updateEntrySetKey         = "$set"
        static let updateEntryUnsetKey       = "$unset"
        static let updateEntryPushKey        = "$push"
        static let updateEntryPullKey        = "$pull"
        static let updateEntryPopKey         = "$pop"
        static let updateEntryIncKey         = "$inc"
        static let updateEntryMulKey         = "$mul"
        static let updateEntryMinKey         = "$min"
        static let updateEntryMaxKey         = "$max"
    }
    
    private func changePrefix(withPrefix prefix: String, dictionary: [String : ExtendedJsonRepresentable?]) -> [String : ExtendedJsonRepresentable?] {
        var newValuesDict = [String : ExtendedJsonRepresentable?]()
        
        for (key, value) in dictionary {
            let newKey = prefix + key
            newValuesDict[newKey] = value
        }
        
        return newValuesDict
    }
    
    //MARK: Internal
    
    internal var key: String {
        switch self {
        case .set:
            return Consts.updateEntrySetKey
        case .unset:
            return Consts.updateEntryUnsetKey
        case .push:
            return Consts.updateEntryPushKey
        case .pull:
            return Consts.updateEntryPullKey
        case .pop:
            return Consts.updateEntryPopKey
        case .inc:
            return Consts.updateEntryIncKey
        case .mul:
            return Consts.updateEntryMulKey
        case .min:
            return Consts.updateEntryMinKey
        case .max:
            return Consts.updateEntryMaxKey
        }
        
    }
    
    internal var valueAsDocument: Document {
        switch self {
        case .set(let value),
             .unset(let value),
             .push(let value),
             .pull(let value),
             .pop(let value),
             .inc(let value),
             .mul(let value),
             .min(let value),
             .max(let value):
            return Document(dictionary: value)
        }
    }
    
    internal mutating func add(prefix: String) {
        switch self {
        case .set(let value):
            self = .set(changePrefix(withPrefix: prefix, dictionary: value))
        case .unset(let value):
            self = .unset(changePrefix(withPrefix: prefix, dictionary: value))
        case .push(let value):
            self = .push(changePrefix(withPrefix: prefix, dictionary: value))
        case .pull(let value):
            self = .pull(changePrefix(withPrefix: prefix, dictionary: value))
        case .pop(let value):
            self = .pop(changePrefix(withPrefix: prefix, dictionary: value))
        case .inc(let value):
            self = .inc(changePrefix(withPrefix: prefix, dictionary: value))
        case .mul(let value):
            self = .mul(changePrefix(withPrefix: prefix, dictionary: value))
        case .min(let value):
            self = .min(changePrefix(withPrefix: prefix, dictionary: value))
        case .max(let value):
            self = .max(changePrefix(withPrefix: prefix, dictionary: value))
        }
    }
    
}

extension UpdateOperationType: Equatable {
   public static func ==(lhs: UpdateOperationType, rhs: UpdateOperationType) -> Bool {
        switch (lhs, rhs) {
        case (.set, .set):
            return true
        case (.unset, .unset):
            return true
        case (.push, .push):
            return true
        case (.pull, .pull):
            return true
        case (.pop, .pop):
            return true
        case (.inc, .inc):
            return true
        case (.mul, .mul):
            return true
        case (.min, .min):
            return true
        case (.max, .max):
            return true
        default: return false
        }
    }
}



