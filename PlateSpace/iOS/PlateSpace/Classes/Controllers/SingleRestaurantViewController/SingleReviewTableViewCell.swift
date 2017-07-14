//
//  SingleReviewTableViewCell.swift
//  PlateSpace
//
//  Created by Miko Halevi on 3/13/17.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import UIKit

// MARK: - SingleReviewTableViewCellDelegate (protocol)

protocol SingleReviewTableViewCellDelegate : class {
    func singleReviewTableViewCellDidPressEditReview()
}

class SingleReviewTableViewCell: UITableViewCell {
    
    // MARK: - Properties

    @IBOutlet private weak var authorLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var reviewLabel: UILabel!
    @IBOutlet private weak var editButton: UIButton!
    
    weak var delegate: SingleReviewTableViewCellDelegate?
    
    // MARK: - Public
    
    func set(author : String, date: Date, content: String, enableEdit: Bool){
        authorLabel.text = author
        reviewLabel.text = content
        reviewLabel.sizeToFit()
        
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.medium
        dateLabel.text = formatter.string(from: date)
        
        editButton.isHidden = !enableEdit
    }

    // MARK: - Actions
    
    @IBAction func editButtonTouched(_ sender: Any) {
        delegate?.singleReviewTableViewCellDidPressEditReview()
    }
    
}
