//
//  Int+PhonePresentation.swift
//  SoLoMoSample
//
//  Created by Miko Halevi on 3/16/17.
//  Copyright © 2017 Miko Halevi. All rights reserved.
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
