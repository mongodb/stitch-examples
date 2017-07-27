//
//  TodoItemTableViewCell.swift
//  MongoDBSample
//


import UIKit

protocol TodoItemTableViewCellDelegate {
    func todoItem(cell: TodoItemTableViewCell, checkBoxValueChanged checked: Bool)
}

class TodoItemTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var checkBox: CheckBox!
    
    var delegate: TodoItemTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    // MARK: - Actions
    
    @IBAction func checkBoxTapped(_ sender: Any) {
        if sender is CheckBox {
            checkBox.checked = !checkBox.checked
            delegate?.todoItem(cell: self, checkBoxValueChanged: checkBox.checked)
        }
    }
}
