//
//  ReviewMetaDataImp.swift
//  SoLoMoSample
//
//  Created by Ofir Zucker on 09/05/2017.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import Foundation
import ExtendedJson
import MongoDBService
import MongoDBODM

class ReviewMetaDataImp: EntityTypeMetaData {

    /// default behavior of root entity
    func create(document: Document) -> EmbeddedEntity? {
        return nil
    }
    
    func getEntityIdentifier() -> EntityIdentifier {
        return EntityIdentifier(Review.self)
    }
    
    func getSchema() -> [String : EntityIdentifier] {
        return [Review.ownerIdKey         : EntityIdentifier(String.self),
                Review.commentKey         : EntityIdentifier(String.self),
                Review.nameOfCommenterKey : EntityIdentifier(String.self),
                Review.rateKey            : EntityIdentifier(Int.self),
                Review.dateOfCommentKey   : EntityIdentifier(Date.self),
                Review.restaurantIdKey    : EntityIdentifier(ObjectId.self)
        ]
    }
    
    var collectionName: String {
        return MongoDBManager.collectionNameReviewsRatings
    }
    
    var databaseName: String {
        return MongoDBManager.databaseName
    }
    
    
}
