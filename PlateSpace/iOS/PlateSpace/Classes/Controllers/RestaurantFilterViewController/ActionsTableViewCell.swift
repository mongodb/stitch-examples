//
//  ActionsTableViewCell.swift
//  PlateSpace
//

import UIKit

// MARK: - ActionsTableViewCellDelegate (protocol)

protocol ActionsTableViewCellDelegate : class {
    func actionsTableViewCelldidCancel()
    func actionsTableViewCelldidFinish()
}

class ActionsTableViewCell: UITableViewCell {
    
    // MARK: - Properties

    weak var delegate : ActionsTableViewCellDelegate?
    
    // MARK: - Actions
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        delegate?.actionsTableViewCelldidCancel()
    }

    @IBAction func doneButtonPressed(_ sender: Any) {
        delegate?.actionsTableViewCelldidFinish()
    }
}
