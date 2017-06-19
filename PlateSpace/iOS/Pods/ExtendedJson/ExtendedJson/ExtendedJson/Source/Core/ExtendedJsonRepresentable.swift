//
//  ExtendedJsonRepresentable.swift
//  ExtendedJson
//

import Foundation

public protocol ExtendedJsonRepresentable {
    var toExtendedJson: Any {get}
    func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool
}

extension ObjectId: ExtendedJsonRepresentable {
    
    public var toExtendedJson: Any {
        return [String(describing: ExtendedJsonKeys.objectid) : hexString]
    }
    
    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? ObjectId {
            return self == other
        }
        return false
    }
}

extension String: ExtendedJsonRepresentable {
    
    public var toExtendedJson: Any {
        return self
    }
    
    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? String {
            return self == other
        }
        return false
    }
}

extension Int: ExtendedJsonRepresentable {
    
    public var toExtendedJson: Any {
        // check if we're on a 32-bit or 64-bit platform and act accordingly
        if MemoryLayout<Int>.size == MemoryLayout<Int32>.size {
            let int32: Int32 = Int32(self)
            return int32.toExtendedJson
        }
        
        let int64: Int64 = Int64(self)
        return int64.toExtendedJson
    }
    
    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? Int {
            return self == other
        }
        return false
    }
}

extension Int32: ExtendedJsonRepresentable {
    
    public var toExtendedJson: Any {
        return [String(describing: ExtendedJsonKeys.numberInt) : String(self)]
    }
    
    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? Int32 {
            return self == other
        }
        return false
    }
}

extension Int64: ExtendedJsonRepresentable {
    
    public var toExtendedJson: Any {
        return [String(describing: ExtendedJsonKeys.numberLong) : String(self)]
    }
    
    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? Int64 {
            return self == other
        }
        return false
    }
}

extension Double: ExtendedJsonRepresentable {
    
    public var toExtendedJson: Any {
        return [String(describing: ExtendedJsonKeys.numberDouble) : String(self)]
    }
    
    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? Double {
            return self == other
        }
        return false
    }
}

extension BsonBinary: ExtendedJsonRepresentable {
    
    public var toExtendedJson: Any {
        let base64String = Data(bytes: data).base64EncodedString()
        let type = String(self.type.rawValue, radix: 16)
        return [String(describing: ExtendedJsonKeys.binary) : base64String, String(describing: ExtendedJsonKeys.type) : "0x\(type)"]
    }
    
    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? BsonBinary {
            return self == other
        }
        return false
    }
}

extension Document: ExtendedJsonRepresentable {
    
    //Documen's `makeIterator()` has no concurency handling, therefor modifying the Document while itereting over it might cause unexpected behaviour
    public var toExtendedJson: Any {
        return reduce([:]) { (result, dic) -> [String : Any] in
            var result = result
            result[dic.key] = dic.value.toExtendedJson
            return result
        }
    }
    
    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? Document {
            return self == other
        }
        return false
    }
}

extension BsonTimestamp: ExtendedJsonRepresentable {
    
    public var toExtendedJson: Any {
        return [String(describing: ExtendedJsonKeys.timestamp) : String(UInt64(self.time.timeIntervalSince1970))]
    }
    
    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? BsonTimestamp {
            return self == other
        }
        return false
    }
}

extension NSRegularExpression: ExtendedJsonRepresentable {
    
    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? NSRegularExpression {
            return self.pattern == other.pattern &&
                self.options == other.options
        }
        return false
        
    }
    
    public var toExtendedJson: Any {
        return [String(describing: ExtendedJsonKeys.regex) : pattern, String(describing: ExtendedJsonKeys.options) : options.toExtendedJson]
    }
}

extension Date: ExtendedJsonRepresentable {
    
    public var toExtendedJson: Any {
        return [String(describing: ExtendedJsonKeys.date) : [String(describing: ExtendedJsonKeys.numberLong) : String(Int64(timeIntervalSince1970 * 1000))]]
    }
    
    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? Date {
            return self == other
        }
        return false
    }
    
}

extension MinKey: ExtendedJsonRepresentable {
    
    public var toExtendedJson: Any {
        return [String(describing: ExtendedJsonKeys.minKey) : 1]
    }
    
    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? MinKey {
            return self == other
        }
        return false
    }
}

extension MaxKey: ExtendedJsonRepresentable {
    
    public var toExtendedJson: Any {
        return [String(describing: ExtendedJsonKeys.maxKey) : 1]
    }
    
    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? MaxKey {
            return self == other
        }
        return false
    }
}

extension BsonUndefined: ExtendedJsonRepresentable {
    
    public var toExtendedJson: Any {
        return [String(describing: ExtendedJsonKeys.undefined) : true]
    }
    
    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? BsonUndefined {
            return self == other
        }
        return false
    }
}

extension BsonArray: ExtendedJsonRepresentable {
    
    public var toExtendedJson: Any {
        return map{$0.toExtendedJson}
    }
    
    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? BsonArray, other.count == self.count {
            for i in 0..<other.count {
                let myExtendedJsonRepresentable = self[i]
                let otherExtendedJsonRepresentable = other[i]
                
                if !myExtendedJsonRepresentable.isEqual(toOther: otherExtendedJsonRepresentable) {
                    return false
                }
            }
        }
        else{
            return false
        }
        return true
    }
}

extension Bool: ExtendedJsonRepresentable {
    
    public var toExtendedJson: Any {
        return self
    }
    
    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? Bool {
            return self == other
        }
        return false
    }
}

extension Dictionary: ExtendedJsonRepresentable {
    public var toExtendedJson: Any {
        return self
    }
    
    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? Dictionary {
            if self.count == other.count {
                return self.reduce(true, { (result, tup: (key: Key, value: Value)) -> Bool in
                    if other[tup.key] != nil {
                        return result && true
                    } else {
                        return false
                    }
                })
            }
        }
        return false
    }
}

extension NSNull: ExtendedJsonRepresentable {
    
    public var toExtendedJson: Any {
        return self
    }
    
    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        if let other = other as? NSNull {
            return self == other
        }
        return false
    }
}

// MARK: - Helpers

internal enum ExtendedJsonKeys: CustomStringConvertible {
    case objectid, numberInt, numberLong, numberDouble, date, binary, type, timestamp, regex, options, minKey, maxKey, undefined
    
    var description: String {
        switch self {
        case .objectid:
            return "$oid"
        case .numberInt:
            return "$numberInt"
        case .numberLong:
            return "$numberLong"
        case .numberDouble:
            return "$numberDouble"
        case .date:
            return "$date"
        case .binary:
            return "$binary"
        case .type:
            return "$type"
        case .timestamp:
            return "$timestamp"
        case .regex:
            return "$regex"
        case .options:
            return "$options"
        case .minKey:
            return "$minKey"
        case .maxKey:
            return "$maxKey"
        case .undefined:
            return "$undefined"
            
        }
    }
}

extension NSRegularExpression.Options {
    
    private struct ExtendedJsonOptions {
        static let caseInsensitive =            "i"
        static let anchorsMatchLines =          "m"
        static let dotMatchesLineSeparators =   "s"
        static let allowCommentsAndWhitespace = "x"
    }
    
    internal var toExtendedJson: Any {
        var description = ""
        if contains(.caseInsensitive) {
            description.append(ExtendedJsonOptions.caseInsensitive)
        }
        if contains(.anchorsMatchLines) {
            description.append(ExtendedJsonOptions.anchorsMatchLines)
        }
        if contains(.dotMatchesLineSeparators) {
            description.append(ExtendedJsonOptions.dotMatchesLineSeparators)
        }
        if contains(.allowCommentsAndWhitespace) {
            description.append(ExtendedJsonOptions.allowCommentsAndWhitespace)
        }
        
        return description
    }
    
    internal init(extendedJsonString: String) {
        self = []
        if extendedJsonString.contains(ExtendedJsonOptions.caseInsensitive) {
            self.insert(.caseInsensitive)
        }
        if extendedJsonString.contains(ExtendedJsonOptions.anchorsMatchLines) {
            self.insert(.anchorsMatchLines)
        }
        if extendedJsonString.contains(ExtendedJsonOptions.dotMatchesLineSeparators) {
            self.insert(.dotMatchesLineSeparators)
        }
        if extendedJsonString.contains(ExtendedJsonOptions.allowCommentsAndWhitespace) {
            self.insert(.allowCommentsAndWhitespace)
        }
    }
}

// MARK: ISO8601

internal extension DateFormatter {
    
    static let iso8601DateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
}
