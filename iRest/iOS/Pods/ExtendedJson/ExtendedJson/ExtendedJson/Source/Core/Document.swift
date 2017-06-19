//
//  Document.swift
//  ExtendedJson
//

import Foundation

public struct Document {
    
    fileprivate var storage: [String : ExtendedJsonRepresentable] = [:]
    fileprivate var orderedKeys: [String] = []

    private let writeQueue = DispatchQueue.global(qos: .utility)
    
    public init() {}
    
    public init(key: String, value: ExtendedJsonRepresentable) {
        self[key] = value
    }
    
    public init(dictionary: [String: ExtendedJsonRepresentable?]){
        for (key, value) in dictionary{
            let concreteValue = value ?? NSNull()
            self[key] = concreteValue
        }
    }
    
    public init(extendedJson json: [String : Any]) throws {
        
        func read(value: Any) throws -> ExtendedJsonRepresentable {
            
            if let json = value as? [String : Any] {
                if let objectIdHexString = json[String(describing: ExtendedJsonKeys.objectid)] as? String {
                    return try ObjectId(hexString: objectIdHexString)
                }
                else if let numberIntString = json[String(describing: ExtendedJsonKeys.numberInt)] as? String,
                    let numberInt = Int(numberIntString) {
                    return numberInt
                }
                else if let numberLongString = json[String(describing: ExtendedJsonKeys.numberLong)] as? String,
                    let numberLong = Int(numberLongString)
                    {
                    return numberLong
                }
                else if let numberDoubleString = json[String(describing: ExtendedJsonKeys.numberDouble)] as? String,
                    let numberDouble = Double(numberDoubleString)
                {
                    return numberDouble
                }
                else if let binaryString = json[String(describing: ExtendedJsonKeys.binary)] as? String,
                    let typeString = json[String(describing: ExtendedJsonKeys.type)] as? String {
                    
                    let fixedTypeString = typeString.hasHexadecimalPrefix() ? String(typeString.characters.dropFirst(2)) : typeString
                    guard let data = Data(base64Encoded: binaryString),
                        let typeInt = UInt8(fixedTypeString, radix: 16),
                        let type = BsonBinarySubType(rawValue: typeInt) else {
                            throw BsonError.parseValueFailure(message: "failed parsing binary value: \(json)")
                    }
                    
                    return BsonBinary(type: type, data: [UInt8](data))
                }
                else if let timeString = json[String(describing: ExtendedJsonKeys.timestamp)] as? String,
                    let time = TimeInterval(timeString) {
                    return BsonTimestamp(time: time)
                }
                else if let pattern = json[String(describing: ExtendedJsonKeys.regex)] as? String,
                    let options = json[String(describing: ExtendedJsonKeys.options)] as? String {                    
                    return try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options(extendedJsonString: options))
                }
                else if let dateDictionary = json[String(describing: ExtendedJsonKeys.date)] as? [String : String],
                    let dateString = dateDictionary[String(describing: ExtendedJsonKeys.numberLong)],
                    let date = TimeInterval(dateString) {
                    return Date(timeIntervalSince1970: date / 1000)
                }                
                else if let minKey = json[String(describing: ExtendedJsonKeys.minKey)] as? Int, minKey == 1 {
                    return MinKey()
                }
                else if let maxKey = json[String(describing: ExtendedJsonKeys.maxKey)] as? Int, maxKey == 1 {
                    return MaxKey()
                }
                else if let undefined = json[String(describing: ExtendedJsonKeys.undefined)] as? Bool, undefined {
                    return BsonUndefined()
                }
                return try Document(extendedJson: json)
            }
            else if let array = value as? [Any] {
                var bsonArray = BsonArray()
                for item in array {
                    bsonArray.append(try read(value: item))
                }
                return bsonArray
            }
            else if let stringValue = value as? String {                
                return stringValue
            }
            else if let boolValue = value as? Bool {
                return boolValue
            }
            else if let nullValue = value as? NSNull {
                return nullValue
            }
            else {
                throw BsonError.parseValueFailure(message: "failed parsing value: \(value)")
            }
        }
        
        for (key, value) in json {
            self[key] = try read(value: value)
        }
    }
    
    // MARK: - Subscript
    
    /// Accesses the value associated with the given key for reading and writing, like a `Dictionary`.
    /// Document keeps the order of entry while iterating over itskey-value pair.
    /// Writing `nil` removes the stored value from the document and takes O(n), all other read/write action take O(1).
    /// If you wish to set a MongoDB value to `null`, set the value to `NSNull`.
    public subscript(key: String) -> ExtendedJsonRepresentable? {
        get {
            return storage[key]
        }
        set {
            writeQueue.sync {
                if newValue == nil {
                    if let index = orderedKeys.index(of: key) {
                        orderedKeys.remove(at: index)
                    }
                }
                else if storage[key] == nil {
                    orderedKeys.append(key)
                }
                
                storage[key] = newValue
            }
        }
    }
}

extension Document: Sequence {
    
    public typealias KeyValuPair = (key: String, value: ExtendedJsonRepresentable)
    
    //There is no concurency handling, therefor modifying the Document while itereting over it might cause unexpected behaviour
    public func makeIterator() -> AnyIterator<KeyValuPair> {
        
        var iterator = orderedKeys.makeIterator()
        return AnyIterator {            
            guard let nextKey = iterator.next(), let nextValue = self.storage[nextKey] else {
                return nil
            }
            return (key: nextKey, value: nextValue)
        }        
    }
}

extension Document: Equatable {
    
    public static func ==(lhs: Document, rhs: Document) -> Bool {
        let lKeySet = Set(lhs.storage.keys)
        let rKeySet = Set(rhs.storage.keys)
        if lKeySet == rKeySet {
            for key in lKeySet {
                if let lValue = lhs.storage[key], let rValue = rhs.storage[key] {
                    if !lValue.isEqual(toOther: rValue) {
                        return false
                    }
                }
            }
            return true
        }
        
        return false
    }

    
}

