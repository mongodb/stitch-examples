//
//  Int+PhonePresentation.swift
//  PlateSpace
//
//

import Foundation

extension Int{
    func asPhoneString() -> String{
        var phoneAsString = String(format:"%d", self)
        if phoneAsString.characters.count > 7 {
            phoneAsString.insert("-", at: phoneAsString.index(phoneAsString.startIndex, offsetBy: 3))
            phoneAsString.insert("-", at: phoneAsString.index(phoneAsString.startIndex, offsetBy: 7))
        }
        return phoneAsString
    }
    
}
