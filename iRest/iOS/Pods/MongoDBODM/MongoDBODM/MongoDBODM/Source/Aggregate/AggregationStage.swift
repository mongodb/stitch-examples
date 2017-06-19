//
//  AggregationStage.swift
//  MongoDBODM
//

import Foundation
import ExtendedJson
import StitchCore
/**
Aggregation stage is used for Stitch Aggregation call, each one of the cases represents a specific aggregation stage in MongoDB.
 - match: Takes criteria as parameter and filter the results according to the query.
 - sort: See sortParameter.
 - limit: Is the max number of results.
 - count: Preform count operator.
 - project: Project any field that you wish to get in result.
 */
public enum AggregationStage {
    case match(query: Criteria?)
    case sort(sortParameters: [SortParameter])
    case limit(value: Int)
    case count(field: String)
    case project(projectionParametes : [ProjectionParameter])
    
    internal var asDocument: Document {
        switch self {
            case .match(let query):
                if let criteria = query {
                    return Document(key: "$match", value: criteria.asDocument)
                }
                else {
                    return Document(key: "$match", value: Document())
                }
            
            case .sort(let sortParameters):
                var sortDocument = Document()
                for sortParameter in sortParameters {
                    sortDocument[sortParameter.field] = sortParameter.direction.rawValue
                }
                return  Document(key: "$sort", value: sortDocument)

            case .limit(let value):
                return Document(key: "$limit", value: value)
            
            case .count(let field):
                return Document(key: "$count", value: field)
            
            case .project(let projectionParameters):
                var projectDocument = Document()
                for projectionParameter in projectionParameters {
                    projectDocument[projectionParameter.field] = projectionParameter.expression
            }
                return Document(key: "$project", value: projectDocument)
        }
    }
    
}
