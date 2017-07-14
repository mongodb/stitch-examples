//
//  NSObject+StringFromClass.swift
//  PlateSpace
//
//  Created by Miko Halevi on 3/6/17.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import Foundation

extension NSObject{
   class func stringFromClass() -> String {
        return String(describing: self)
    }
}
