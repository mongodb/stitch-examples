//
//  Validators.swift
//  ExtendedJson
//

import Foundation

internal extension ObjectId {

    static func isValid(hexString: String) -> Bool {
        return hexString.characters.count == 24 && hexString.isHexadecimal()
    }

    static func isValid(byteArray array: [UInt8]) -> Bool {
        return array.count == 12
    }
}

extension String {

    func isHexadecimal() -> Bool {
        let hexadecimalRegex = "[0-9a-fA-F]+"
        let regexText = NSPredicate(format: "SELF MATCHES %@", hexadecimalRegex)
        return regexText.evaluate(with: self)
    }

    func hasHexadecimalPrefix() -> Bool {
        return hasPrefix("0x") || hasPrefix("0X")
    }
}
