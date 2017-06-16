//
//  RestaurantAdditionalInfoTabelViewcell.swift
//  SoLoMoSample
//
//  Created by Miko Halevi on 3/12/17.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import UIKit
import Cosmos

class RestaurantAdditionalInfoTabelViewcell: UITableViewCell {
    
    // MARK: - Properties

    @IBOutlet private weak var avgReviewContainerView: UIView!
    @IBOutlet private weak var avgReviewLabel: UILabel!
    @IBOutlet private weak var numOfReviewsLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var websiteLabel: UILabel!
    @IBOutlet private weak var phoneLabel: UILabel!
    @IBOutlet private weak var starsRating: CosmosView!
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        avgReviewContainerView.layer.cornerRadius = 11
        starsRating.settings.fillMode = .half
    }
    
    // MARK: - Public setters
    
    func set(adress: String, website : String, phone: String, avarageReview: Double, numberOfReviews: Double){
        addressLabel.text = adress
        websiteLabel.text = website
        phoneLabel.text = phone
        avgReviewLabel.text = String(format: "%.1f", avarageReview)
        numOfReviewsLabel.text = "\(Int(numberOfReviews)) Ratings"
        starsRating.rating = Double(avarageReview)
    }

}
