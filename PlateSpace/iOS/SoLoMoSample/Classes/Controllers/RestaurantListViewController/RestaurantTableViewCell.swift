//
//  RestaurantTableViewCell.swift
//  SoLoMoSample
//
//  Created by Miko Halevi on 3/6/17.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import UIKit

class RestaurantTableViewCell: UITableViewCell {

    // MARK: - Properties
    
    @IBOutlet private weak var restaurantNameLabel: UILabel!
    @IBOutlet private weak var distanceLabelContainerView: UIView!
    @IBOutlet private weak var distanceLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        distanceLabelContainerView.layer.cornerRadius = 10
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        let originalDistanceBacgroundColor = distanceLabelContainerView.backgroundColor
        super.setSelected(selected, animated: animated)
        
        if selected {
            distanceLabelContainerView.backgroundColor = originalDistanceBacgroundColor
        }

    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let originalDistanceBacgroundColor = distanceLabelContainerView.backgroundColor
        super.setHighlighted(highlighted, animated: animated)
        
        if highlighted {
            distanceLabelContainerView.backgroundColor = originalDistanceBacgroundColor
        }
        
    }
    
    // MARK: - Public
    
    func set(restaurantName: String, distance: Double , address: String, phone: String){
        restaurantNameLabel.text = restaurantName
        
        let restaurantInfo = address + "\n" + phone

        informationLabel.text = restaurantInfo
        
        let mileString = distance == 1 ? "Mile" : "Miles"
        let mileValue = distance >= 10 ? "\(Int(distance))" : String(format: "%.1f", distance)
        distanceLabel.text = "\(mileValue) \(mileString)"
    }
    
    

}
