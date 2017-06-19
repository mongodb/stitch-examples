//
//  ProjectionExpressionRepresentable.swift
//  MongoDBODM
//

import Foundation
import ExtendedJson

public protocol ProjectionExpressionRepresentable: ExtendedJsonRepresentable {
    
}

extension Bool: ProjectionExpressionRepresentable {

}
