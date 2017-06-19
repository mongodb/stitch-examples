//
//  Aggregate.swift
//  MongoDBODM
//

import Foundation
import StitchCore
import MongoDBService
import ExtendedJson
import StitchLogger

/**
 Represents an MongoDB aggregate call, Use this struct to preform aggregate calls to MongoDB service. see example
        
        let stage: AggregationStage = .count(field: "name")
        let aggregate = Aggregate<Restaurant>(mongoDBClient: mongoDBClient, stages: [stage])
        aggregate.execute().response { (result) in
            switch result {
            case .failure(let error):
            print("got error :" + error.localizedDescription)
            case .success(let val):
            // do something with value...
            }
        }
 
 */
public struct Aggregate<Entity: RootEntity> {
    let mongoDBClient: MongoDBClientType
    var aggregationPipeline: [AggregationStage]
    
    public init(mongoDBClient: MongoDBClientType, stages: [AggregationStage]) {
        self.mongoDBClient = mongoDBClient
        self.aggregationPipeline = stages
    }
    
    public func execute() -> StitchTask<Any> {
        if let classMetaData = Utils.entitiesDictionary[Utils.getIdentifier(type: Entity.self)] {
            
            let databaseName = classMetaData.databaseName
            let collectionName = classMetaData.collectionName
            
            let aggregationPipelineDocument = aggregationPipeline.map{ $0.asDocument }
            return mongoDBClient.database(named: databaseName).collection(named: collectionName).aggregate(pipeline: aggregationPipelineDocument)
        }
        else {
            printLog(.error, text: "Metadata is missing for class \(Entity.self)")
            return StitchTask<Any>(error: OdmError.classMetaDataNotFound)
        }
    }
    
}
