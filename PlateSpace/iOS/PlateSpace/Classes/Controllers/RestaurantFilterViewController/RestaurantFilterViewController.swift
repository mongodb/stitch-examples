//
//  RestaurantFilterViewController.swift
//  PlateSpace
//

import UIKit

// MARK: - RestaurantFilterViewControllerDelegate (protocol)

protocol RestaurantFilterViewControllerDelegate : class {
    func restaurantFilterViewControllerdidCancel(_ restaurantFilterViewController : RestaurantFilterViewController)
    func restaurantFilterViewControllerdidFinish(_ restaurantFilterViewController : RestaurantFilterViewController)
}

class RestaurantFilterViewController: UIViewController,ActionsTableViewCellDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var currentFilter : RestaurantFilter = .none
    weak var delegate : RestaurantFilterViewControllerDelegate?
    @IBOutlet weak var tableViewButtomConstraint: NSLayoutConstraint!

    
    // MARK: - Public
    
    func animateView(){
        view.layoutIfNeeded()
        tableViewButtomConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - ActionsTableViewCellDelegate

    func actionsTableViewCelldidCancel() {
        self.delegate?.restaurantFilterViewControllerdidCancel(self)
    }
    func actionsTableViewCelldidFinish() {
        self.delegate?.restaurantFilterViewControllerdidFinish(self)
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellFilter : RestaurantFilter = restaurantFilterForIndexPath(indexPath: indexPath)
        
        if currentFilter.contains(cellFilter) {
            currentFilter.remove(cellFilter)
        }
        else{
            currentFilter.insert(cellFilter)
        }
        
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Actions cell
        var cell : UITableViewCell
        if indexPath.row == 0 {
            let actionCell : ActionsTableViewCell = tableView.dequeueReusableCell(withIdentifier: ActionsTableViewCell.stringFromClass(), for: indexPath) as! ActionsTableViewCell
            actionCell.delegate = self
            cell = actionCell
        }
        else{
            
            let filterCell = tableView.dequeueReusableCell(withIdentifier: FilterCategoryTableViewCell.stringFromClass(), for: indexPath) as! FilterCategoryTableViewCell
            let filter = restaurantFilterForIndexPath(indexPath: indexPath)
            let filterChosen = currentFilter.contains(filter)
            
            filterCell.accessoryType = filterChosen ? .checkmark : .none
            filterCell.filterNameLabel.text = String(describing:filter)
            
            cell = filterCell
        }
        
        return cell
    }
    
    // MARK: - Helper
    
    func restaurantFilterForIndexPath(indexPath:IndexPath) -> RestaurantFilter {
        var filter : RestaurantFilter = []
        switch indexPath.row {
        case 1:
            filter  = .all
        case 2:
            filter = .freeParking
        case 3:
            filter = .openWeekends
        case 4:
            filter = .vegan
        case 5:
            filter = .hasWifi
        default:
            break
        }
        return filter
    }

}
