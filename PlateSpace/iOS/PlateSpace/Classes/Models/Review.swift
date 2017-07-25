//
//  Review.swift
//  PlateSpace
//

import Foundation
import ExtendedJson
import MongoDBService
import MongoDBODM

class Review: RootEntity {
    
    static let ownerIdKey         = "owner_id"
    static let commentKey         = "comment"
    static let nameOfCommenterKey = "nameOfCommenter"
    static let rateKey            = "rate"
    static let dateOfCommentKey   = "dateOfComment"
    static let restaurantIdKey    = "restaurantId"
    
    var owner_id: String? {
        get {
            return self[Review.ownerIdKey] as? String
        }
        set(newOwner_id) {
            self[Review.ownerIdKey] = newOwner_id
        }
    }

    var comment: String? {
        get {
            return self[Review.commentKey] as? String
        }
        set(newComment) {
            self[Review.commentKey] = newComment
        }
    }

    var nameOfCommenter: String? {
        get {
            return self[Review.nameOfCommenterKey] as? String
        }
        set(newNameOfCommenter) {
            self[Review.nameOfCommenterKey] = newNameOfCommenter
        }
    }
    
    var rate: Int? {
        get {
            return self[Review.rateKey] as? Int
        }
        set(newRate) {
            self[Review.rateKey] = newRate
        }
    }
    
    var dateOfComment: Date? {
        get {
            return self[Review.dateOfCommentKey] as? Date
        }
        set(newDateOfComment) {
            self[Review.dateOfCommentKey] = newDateOfComment
        }
    }

    var restaurantId: ObjectId? {
        get {
            return self[Review.restaurantIdKey] as? ObjectId
        }
        set(newRestaurantId) {
            self[Review.restaurantIdKey] = newRestaurantId
        }
    }

}
