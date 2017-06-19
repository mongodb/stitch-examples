//
//  ObjectId.swift
//  ExtendedJson
//

import Foundation

public struct ObjectId: Equatable {
    
    private var byteArray = [UInt8]()
    
    private static var counter: UInt32 = arc4random()
    
    private static let lock = DispatchSemaphore(value: 1)
    
    public  var hexString: String {
        get {
            var hexStr = String()
            for byte in byteArray {
                let firstBits = byte / 16
                let secondBits = byte % 16
                
                hexStr.append(String(format:"%x",firstBits ))
                hexStr.append(String(format:"%x",secondBits ))
            }
            return hexStr
        }
    }
    
    //MARK: Init
    
    public init(hexString: String) throws {
        guard ObjectId.isValid(hexString: hexString) else {
            throw BsonError.illegalArgument(message: "invalid hexadecimal representation of an ObjectId: [\(hexString)]")
        }
        
        var characterIterator = hexString.characters.makeIterator()
        while let c1 = characterIterator.next(), let c2 = characterIterator.next() {
            let singleByteString = String([c1, c2])
            
            guard let stringAsBytes = UInt8(singleByteString, radix: 16) else {
                throw BsonError.illegalArgument(message: "invalid hexadecimal representation of characters in object with with caracters: \(c1), \(c2)")
            }
            
            byteArray.append(stringAsBytes)
        }
        
        guard ObjectId.isValid(byteArray: byteArray) else {
            throw BsonError.illegalArgument(message: "invalid hexadecimal representation of an ObjectId: [\(hexString)]")
        }
        
    }
    
    public init() {
        let currentTimeStamp = byteArrayFrom(integer: UInt32(Date().timeIntervalSince1970))
        let randomNumber = byteArrayFrom(integer: arc4random())
        let counterNum = byteArrayFrom(integer: getCounterNumber())
        
        byteArray.append(contentsOf: currentTimeStamp)
        byteArray.append(contentsOf: randomNumber)
        byteArray.append(contentsOf: counterNum)
        
    }
    
    //MARK: Helpers
    
    private func byteArrayFrom(integer numToConvert: UInt32) -> [UInt8] {
        
        var numToConvertBigEndian = numToConvert.bigEndian
        let count = MemoryLayout<UInt32>.size
        
        let bytePtr = withUnsafePointer(to: &numToConvertBigEndian) {
            $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                UnsafeBufferPointer(start: $0, count: count)
            }
        }
        
        return Array(bytePtr)
    }
    
    private func getCounterNumber() -> UInt32 {
        
        ObjectId.lock.wait()
        defer { ObjectId.lock.signal() }
        ObjectId.counter += 1
        let returnValue = ObjectId.counter
        return returnValue
    }
    
    //MARK: Equatable
    
    public static func ==(lhs: ObjectId, rhs: ObjectId) -> Bool {
        if lhs.byteArray.count != rhs.byteArray.count{
            return false
        }
        for i in 0...lhs.byteArray.count - 1 {
            if lhs.byteArray[i] != rhs.byteArray[i] {
                return false
            }
        }
        
        return true
    }
    
}


