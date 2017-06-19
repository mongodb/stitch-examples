//
//  Query.swift
//  MongoDBODM
//

import Foundation
import StitchCore
import ExtendedJson
import MongoDBService
import StitchLogger

/**
Used to perform querys to Stitch on top of a MongoDB collection
 */
public struct Query<Entity: RootEntity> {
    
    private(set) var criteria: Criteria?
    let mongoDBClient: MongoDBClientType
    
    private var asDocument: Document {
        return criteria?.asDocument ?? Document()
    }
    
    public init(criteria: Criteria? = nil, mongoDBClient: MongoDBClientType) {
        self.criteria = criteria
        self.mongoDBClient = mongoDBClient
    }
    /**
     Use this method to get number of enties in Stitch db for an that matches the `criteria` provided

     - Returns: number of objects in the Db, otherwise stitch Error
     
     */
    public func count() -> StitchTask<Int> {
        
        do {
            let collection = try getCollection()
            return collection.count(query: asDocument)
        }
        catch {
            return StitchTask<Int>(error: error)
        }
    }
    
    /**
     Use this method to fetch entities from Stitch that matches the `criteria` provided
     
     - Parameter limit: maximal number of entities to return
     
     - Returns: An array of entities upon success, otherwise stitch Error
     
     */
    public func find(limit: Int? = nil) -> StitchTask<[Entity]> {
        var projection: Projection?
        if let schema = Entity.schema {
            projection = Projection(schema.map{ return $0.key })
        }
        do{
            let collection = try getCollection()
            return collection.find(query: asDocument, projection: projection?.asDocument, limit: limit).continuationTask{(result: [Document]) -> [Entity] in
                return result.flatMap{ Entity(document: $0, mongoDBClient: self.mongoDBClient) }
            }
        }
        catch{
            return StitchTask<[Entity]>(error: error)
        }
    }
 
    /**
     Use this method to query with paginatation entities from stitch.
     In this example we are querying users that their age grater than or equal 19, the sort parameter is by the user name (sorted lexicographically) 
     
            criteria = Criteria.greaterThanOrEqual(field: "age", value: 18)
            let query = Query<User>(criteria: criteria, mongoDBClient: mongoDBClient)
            let sortParameter = SortParameter(field: "name", direction: .ascending)
            query.find(sortParameter: sortParameter, pageSize: Consts.pageSize).response { [weak self] result in
             switch result {
                case .success(let paginatedResult):
                    self?.handlePaginatedResult(paginatedResult)
                case .failure(let error):
                    self?.handle(error: error)
             }

     
     - Parameter sortParameter: Defines the order of the results returned
     - Parameter pageSize: The maximal nubmer of entities to return in each page
     
     - Returns: paginatedQueryResult which contains the result (array of entities) for more information see `paginatedQueryResult`
     
     */
    public func find(sortParameter: SortParameter, pageSize: Int) -> StitchTask<PaginatedQueryResult<Entity>> {
        return find(originalCriteria: self.criteria, sortParameter: sortParameter, pageSize: pageSize)
    }
    
    internal func find(originalCriteria: Criteria?, sortParameter: SortParameter, pageSize: Int) -> StitchTask<PaginatedQueryResult<Entity>> {
        let pipeline = aggregationPipelineFor(sortParameter: sortParameter, pageSize: pageSize)
        let aggregate = Aggregate<Entity>(mongoDBClient: mongoDBClient, stages: pipeline)
        return aggregate.execute().continuationTask{ (result) -> PaginatedQueryResult<Entity> in
            if let bsonArray = result as? BsonArray {
                do {
                    return try PaginatedQueryResult<Entity>(results: bsonArray, originalCriteria: originalCriteria, sortParameter: sortParameter, pageSize: pageSize, mongoDBClient: self.mongoDBClient)
                }
            }
            else {
                printLog(.error, text: "Unexpected type was received - expecting BsonArray")
                throw OdmError.corruptedData(message: "Unexpected type was received - expecting BsonArray")
            }
        }
    }
    
    //MARK: Private
    
    private func getTypeMetaData() -> EntityTypeMetaData? {
        return Utils.entitiesDictionary[Utils.getIdentifier(type: Entity.self)]
    }
    
    private func getCollection() throws -> MongoDBService.CollectionType {
        guard let metaData = getTypeMetaData() else {
            printLog(.error, text: "not class meta data found on class: \(Entity.self)")
            throw OdmError.classMetaDataNotFound
        }
        
        let databaseName = metaData.databaseName
        let collectionName = metaData.collectionName

        return mongoDBClient.database(named: databaseName).collection(named: collectionName)
    }
    
    //MARK: Sort helpers
    
    //Sort is currently not supported at 'collection.find', so we are using aggregation
    fileprivate func aggregationPipelineFor(sortParameter: SortParameter, pageSize: Int) -> [AggregationStage] {
        var pipeline = [AggregationStage]()
        let matchStage: AggregationStage = .match(query: criteria)
        pipeline.append(matchStage)
        
        let sortStage: AggregationStage
        //We are adding a secondary sort by _id to get the next items in the pagingation mechanism
        if sortParameter.field != "_id" {
            let idSorter = SortParameter(field: "_id", direction: .ascending)
            sortStage = .sort(sortParameters: [sortParameter, idSorter])
        }
        else {
            sortStage = .sort(sortParameters: [sortParameter])
        }
        pipeline.append(sortStage)
        
        let limitStage: AggregationStage = .limit(value: pageSize)
        pipeline.append(limitStage)
        
        let projectionParameters = Entity.schema?.map{
            return ProjectionParameter(field: $0.key, expression: true)
        }
        
        if let projectionParameters = projectionParameters {
            let projectStage: AggregationStage = .project(projectionParametes: projectionParameters)
            pipeline.append(projectStage)
        }
        
        return pipeline
    }
    
    
}
