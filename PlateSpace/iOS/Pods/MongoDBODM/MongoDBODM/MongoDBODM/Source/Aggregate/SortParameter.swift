//
//  Sort.swift
//  MongoDBODM
//

import Foundation
/**
 Used as a parameter in the paginated query call or in aggregation call (AggregationStage) - representing the sort definition by which the results will be returned
 */
public struct SortParameter {
    let field: String
    let direction: SortDirection
    
    public init(field: String, direction: SortDirection) {
        self.field = field
        self.direction = direction
    }
}

public enum SortDirection: Int {
    case ascending = 1
    case descending = -1
    
}
