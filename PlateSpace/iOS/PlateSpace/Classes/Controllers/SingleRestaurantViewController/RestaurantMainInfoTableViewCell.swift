//
//  RestaurantMainInfoTableViewCell.swift
//  PlateSpace
//

import UIKit
import Alamofire

// MARK: - RestaurantMainInfoTableViewCellDelegate (protocol)

protocol RestaurantMainInfoTableViewCellDelegate : class {
    func restaurantMainInfoTableViewCellDidPressMapButton()
}

class RestaurantMainInfoTableViewCell: UITableViewCell {
    
    // MARK: - Properties

    @IBOutlet private weak var restaurantNameLabel: UILabel!
    @IBOutlet private weak var opneningTimeLabel: UILabel!
    @IBOutlet private weak var restaurantImage: UIImageView!
    
    weak var delegate : RestaurantMainInfoTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        restaurantImage.image = nil
        restaurantImage.alpha = 0.0
    }
    
    // MARK: - Public
    
    func set(restaurantName: String, openingHours: String, imageUrl: String){
        restaurantNameLabel.text = restaurantName
        opneningTimeLabel.text = openingHours
        
        /// Load the restaurant's image
        guard restaurantImage.image == nil, let url = URL(string: imageUrl) else { return }
        
        OperationQueue().addOperation({ [weak self] in
            do {
                let data = try Data(contentsOf: url)
                let image = UIImage(data: data) ?? UIImage(named: "iStock")
                
                self?.set(image: image)
                
            } catch {
                print("Error creating data from url")
                
                self?.set(image: UIImage(named: "iStock"))
            }
        })

    }
    
    // MARK: - Private
    
    private func set(image: UIImage?) {
        OperationQueue.main.addOperation({ [weak self] in
            self?.restaurantImage.image = image
            
            UIView.animate(withDuration: 0.2, animations: {
                self?.restaurantImage.alpha = 1.0
            })
        })
    }
    
    // MARK: - Actions

    @IBAction private func mapButtonPressed(_ sender: Any) {
        delegate?.restaurantMainInfoTableViewCellDidPressMapButton()
    }
}
