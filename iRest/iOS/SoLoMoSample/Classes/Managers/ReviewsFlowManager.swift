//
//  ReviewsFlowManager.swift
//  SoLoMoSample
//
//  Created by Ofir Zucker on 23/05/2017.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import Foundation
import MongoCore
import MongoDB
import MongoBaasODM
import MongoExtendedJson

// MARK: - ReviewsFlowManagerDelegate
protocol ReviewsFlowManagerDelegate: class {
    func reviewsFlowManagerDidSave(review: Review)
    func reviewsFlowManagerFailedToSaveReview()
    func reviewsFlowManagerDidUpdateRestaurant()
}

class ReviewsFlowManager {
    
    static let shared = ReviewsFlowManager()
    
    weak var delegate: ReviewsFlowManagerDelegate?
    
    private struct Consts {
         
        /// Update Review Pipeline
        static let pipelineCommandName = "ratingsResult"
        static let pipelineResultKey   = "pipelineResult"
        static let pipelineName        = "updateRatings"
        
        /// Update Review Arguments
        static let argsRestaurantIdKey = "restaurantId"
    }
    
    func update(review: Review) {
        review.update().response { [unowned self] response in
            self.handleCompletionSave(review: review, response: response)
        }
    }
    
    func save(review: Review) {
        review.save().response { [unowned self] response in
            self.handleCompletionSave(review: review, response: response)
        }
    }
    
    private func handleCompletionSave(review: Review, response: StitchResult<Any>) {
        
        switch response {
        case .success(_):
            
            /// Inform the delegate that the review has been saved successfully
            delegate?.reviewsFlowManagerDidSave(review: review)
            
            /// If the review contains a rate, update the restaurant's average rating & rate count
            if let restaurantId = review.restaurantId, review.rate != nil {
                updateRating(withRestaurantId: restaurantId)
            }
            print("Save review succeeded")
        case .failure(let error):
            
            delegate?.reviewsFlowManagerFailedToSaveReview()
            print("Save review failed: \(error.localizedDescription)")
        }
    }
    
    private func updateRating(withRestaurantId id: ObjectId) {
        /// Build a custom pipeline to update the restaurant review model
        
        /// Pipeline args item specify the structure in which the query results will be returned
        let argsItems: BsonArray = [Document(dictionary: [Consts.pipelineResultKey : "%%vars.\(Consts.pipelineCommandName)"])]
        
        /// Arguments for the pipeline
        let args = Document(dictionary: [Consts.argsRestaurantIdKey : id])
        
        /// The document which is passed to the 'let' field
        let letDocument = Document(dictionary: ["%pipeline" : Document(dictionary: [
            "name" : Consts.pipelineName,
            "args" : args
            ])])
        
        /// Build the pipeline
        let pipeline = Pipeline (
            action: "literal",
            args: ["items" : argsItems],
            `let`: Document(dictionary: [Consts.pipelineCommandName :  letDocument])
        )
        
        /// Execute the pipeline
        MongoDBManager.shared.stitchClient.executePipeline(pipeline: pipeline).response { [unowned self] result in
            switch result {
            case .success(_):
                self.delegate?.reviewsFlowManagerDidUpdateRestaurant()
                
                print("Updated restaurant review")
            case .failure(let error):
                print("Update restaurant pipeline execution failed with error: \(error.localizedDescription)")
                
            }
        }
    }
    
   }
