//
//  NSObject+StringFromClass.swift
//  PlateSpace
//

import Foundation

extension NSObject{
   class func stringFromClass() -> String {
        return String(describing: self)
    }
}
