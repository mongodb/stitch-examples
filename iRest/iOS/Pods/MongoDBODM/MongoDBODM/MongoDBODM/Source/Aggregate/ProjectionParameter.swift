//
//  ProjectionParameter.swift
//  MongoDBODM
//

import Foundation
/**
 Used as a parameter in AggregationStage.project
 */
public struct ProjectionParameter {
    let field: String
    let expression: ProjectionExpressionRepresentable
    
    public init(field: String, expression: ProjectionExpressionRepresentable) {
        self.field = field
        self.expression = expression
    }
}

