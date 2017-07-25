//
//  RateNowTableViewCell.swift
//  PlateSpace
//
//

import UIKit
import Cosmos

//MARK: - RateNowTableViewCellDelegate (protocol)

protocol RateNowTableViewCellDelegate : class {
    func rateNowTableViewCell(_ cell: RateNowTableViewCell, didRate rate: Int)
    func rateNowTableViewCellDidStartRating()
}

class RateNowTableViewCell: UITableViewCell {

    // MARK: - Properties
    
    @IBOutlet private weak var ratingView: CosmosView!
    
    weak var delegate : RateNowTableViewCellDelegate?
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        ratingView.settings.fillMode = .full
        
        ratingView.didTouchCosmos = { [weak self] value in
            self?.delegate?.rateNowTableViewCellDidStartRating()
        }
        
        ratingView.didFinishTouchingCosmos = { [weak self] value in
            if let strongSelf = self {
                strongSelf.delegate?.rateNowTableViewCell(strongSelf, didRate: Int(value))
            }
        }
    }
    
    // MARK: - Public setters
    
    func set(rating: Int) {
        ratingView.rating = Double(rating)
    }

}
