//
//  AddReviewTableViewCell.swift
//  PlateSpace
//
//

import UIKit

// MARK: - AddReviewTableViewCellDelegate (protocol)

protocol AddReviewTableViewCellDelegate : class {
    func addReviewTableViewCellDidPressAddReview()
}


class AddReviewTableViewCell: UITableViewCell {
    
    // MARK: - Properties

    @IBOutlet private weak var addReviewButton: UIButton!
    
    weak var delegate : AddReviewTableViewCellDelegate?

    // MARK: - Public setters
    
    func set(isReviewEnabled: Bool) {
        addReviewButton.isEnabled = isReviewEnabled
    }
    
    // MARK: - Actions
    
    @IBAction private func addReviewButtonPressed(_ sender: Any) {
        delegate?.addReviewTableViewCellDidPressAddReview()
    }
}
