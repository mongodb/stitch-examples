import UIKit
import BEMCheckBox

private func strikeThrough(text: String,
                           isChecked: Bool) -> NSMutableAttributedString {
    let attributeString = NSMutableAttributedString(string: text)

    if isChecked {
        attributeString.addAttribute(
            .strikethroughStyle,
            value: 2,
            range: NSMakeRange(0, attributeString.length))
    } else {
        attributeString.removeAttribute(
            .strikethroughStyle,
            range: NSMakeRange(0, attributeString.length))
    }

    return attributeString
}

class TodoTableViewCell: UITableViewCell, BEMCheckBoxDelegate {
    @IBOutlet weak var taskLabel: UILabel!
    @IBOutlet weak var checkBox: BEMCheckBox!

    private var todoItem: TodoItem?

    override func awakeFromNib() {
        checkBox.onAnimationType = .bounce
        checkBox.offAnimationType = .bounce
        checkBox.delegate = self
    }

    func set(todoItem: TodoItem) {
        self.todoItem = todoItem
        checkBox.on = todoItem.checked
        taskLabel.attributedText = strikeThrough(text: todoItem.task,
                                                 isChecked: checkBox.on)
    }

    func didTap(_ checkBox: BEMCheckBox) {
        guard let text = taskLabel.text else {
            return
        }

        taskLabel.attributedText = strikeThrough(text: text, isChecked: checkBox.on)
        self.todoItem?.checked = checkBox.on
    }
}
