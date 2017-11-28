//
//  TodoListViewController.swift
//  MongoDBSample
//

import UIKit
import FacebookLogin
import FacebookCore
import StitchCore
import ExtendedJson
import MongoDBService


class TodoListViewController: UIViewController, AuthenticationViewControllerDelegate, EmailAuthViewControllerDelegate, TodoItemTableViewCellDelegate, UITableViewDataSource {
    
    private struct Consts {
        
        static var AppId: String {
            let path = Bundle.main.path(forResource: "Stitch-Info", ofType: "plist")
            let infoDic = NSDictionary(contentsOfFile: path!) as? [String: AnyObject]
            let appId = infoDic!["APP_ID"] as! String
            assert(appId != "<Your-App-ID>", "Insert your App ID in Stitch-Info.plist")
            return appId
        }
    }
    
    private let stitchClient = StitchClient(appId: Consts.AppId)
    
    private var mongoClient: MongoDBClient
    
    private var authVC: AuthenticationViewController?
    private var emailAuthVC: EmailAuthViewController?
    
    private var todoItems: [TodoItem] = []
    @IBOutlet weak var todoItemsTableView: UITableView!
    
    var emailAuthOpToPresentWhenOpened : EmailAuthOperationType?
    
    
    var collection: MongoDBService.Collection {
        return mongoClient.database(named: "todo").collection(named: "items")
    }
    
    // MARK: - Init
    
    required init?(coder aDecoder: NSCoder) {
        mongoClient = MongoDBClient(stitchClient: stitchClient, serviceName: "mongodb-atlas")
        super.init(coder: aDecoder)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        todoItemsTableView.tableFooterView = UIView(frame: .zero)
        
        if !stitchClient.isAuthenticated {
            presentAuthViewController(animated: false)
        }
        else {
            refreshList()
        }
        
        if let emailAuthOpToPresentWhenOpened = emailAuthOpToPresentWhenOpened {
            presentEmailAuthViewController(operationType: emailAuthOpToPresentWhenOpened)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func refreshButtonClicked(_ sender: Any) {
        refreshList()
    }
    
    @IBAction private func logoutButtonPressed(_ sender: Any) {
        stitchClient.logout().then { Void in
            self.handleLogout(provider: MongoDBManager.shared.provider)
        }
    }
    
    @IBAction func clearButtonPressed(_ sender: Any) {
        var document = Document()
        document["owner_id"] = stitchClient.auth?.userId
        document["checked"] = true
        
        collection.deleteMany(query: document).then{ (result: Document) in
            self.refreshList()
        }
    }
    
    @IBAction func linkButtonPressed(_ sender: Any) {
        presentAuthViewController(animated: true)
    }
    
    @IBAction func addBarButtonItemPressed(_ sender: Any) {
        let alertController = UIAlertController(title: nil, message: "Add an item.", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in }
        
        
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] action in
            if let textFields = alertController.textFields {
                let addItemTextField = textFields[0] as UITextField
                if let text = addItemTextField.text {
                    self?.add(item: text)
                }
            }
        }
        
        addAction.isEnabled = false
        alertController.addTextField { textField in
            textField.placeholder = "Fetch the kids"
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object: textField, queue: OperationQueue.main) { notification in
                addAction.isEnabled = textField.text?.replacingOccurrences(of: " ", with: "") != ""
            }
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(addAction)
        
        present(alertController, animated: true)
    }
    
    // MARK: - Helpers
    
    private func update(item: ObjectId, checked: Bool) -> StitchTask<Document> {
        let query = Document(key: "_id", value: item)
        let set = Document(key: "checked", value: checked)
        let update = Document(key: "$set", value: set)
        return collection.updateOne(query: query, update: update)
    }
    
    private func add(item text: String) {
        var itemDoc = Document()
        itemDoc["owner_id"] = stitchClient.auth?.userId
        itemDoc["text"] = text
        itemDoc["checked"] = false
        collection.insertOne(document: itemDoc).then{ (result: ObjectId) in
            self.refreshList()
            }.catch {error in
                print("failed inserting item: \(error.localizedDescription)")

            }
        
    }
    
    func refreshList() {
        collection.find(query: Document(key: "owner_id", value: (stitchClient.auth?.userId)!), limit: 0).then{ (documents: [Document]) in
            var todoItems: [TodoItem] = []
            for document in documents {
                if let item = TodoItem(document: document) {
                    todoItems.append(item)
                }
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.todoItems = todoItems
                self?.todoItemsTableView.reloadData()
            }
            }.catch {error in
                print("failed refreshing item: \(error.localizedDescription)")
                
            }
    }
    
    // MARK: - UITableViewDataSource
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoItems.count        
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TodoItemTableViewCell.self), for: indexPath) as! TodoItemTableViewCell
        let todoItem = todoItems[indexPath.row]
        cell.titleLabel.text = todoItem.text
        cell.checkBox.checked = todoItem.checked
        cell.delegate = self
        return cell
    }
    
    // MARK: - TodoItemTableViewCellDelegate
    
    func todoItem(cell: TodoItemTableViewCell, checkBoxValueChanged checked: Bool) {
        if let indexPath = todoItemsTableView.indexPath(for: cell),
            indexPath.row < todoItems.count {
            let todoItem = todoItems[indexPath.row]
            update(item: todoItem.objectId, checked: checked).catch { err in
                print(err)
            }
        }
    }
    
    // MARK: - Auth
    
    private func presentAuthViewController(animated: Bool) {
        
        if authVC != nil {
            return
        }
        
        if let authVC = self.storyboard?.instantiateViewController(withIdentifier: String(describing: AuthenticationViewController.self)) as? AuthenticationViewController {
            authVC.stitchClient = stitchClient
            authVC.delegate = self
            self.authVC = authVC
            DispatchQueue.main.async { [weak self] in
                self?.present(authVC, animated: animated, completion: nil)
            }
        }
    }
    
    private func dismissAuthViewController(animated: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.authVC?.dismiss(animated: animated, completion: { [weak self] in
                self?.authVC = nil
            })
        }
    }
    
    func presentEmailAuthViewController(operationType: EmailAuthOperationType) {
                
        if let emailAuthVC = emailAuthVC {
            emailAuthVC.operationType = operationType
            switch operationType {
            case .confirmEmail(let token, let tokenId):
                emailAuthVC.confirmEmail(token: token, tokenId: tokenId)
            case .resetPassword(let token, let tokenId):
                emailAuthVC.resetPassword(token: token, tokenId: tokenId)
            }
        }
        else if let emailAuthVC = self.storyboard?.instantiateViewController(withIdentifier: String(describing: EmailAuthViewController.self)) as? EmailAuthViewController {
            emailAuthVC.stitchClient = stitchClient
            emailAuthVC.delegate = self            
            emailAuthVC.operationType = operationType
            self.emailAuthVC = emailAuthVC
            
            DispatchQueue.main.async { [weak self] in
                let presenter = self?.authVC ?? self
                presenter?.present(emailAuthVC, animated: true, completion: nil)
            }
        }
        
        emailAuthOpToPresentWhenOpened = nil
    }
    
    private func dismissEmailAuthViewController(animated: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.emailAuthVC?.dismiss(animated: animated, completion: { [weak self] in
                self?.emailAuthVC = nil
            })
        }
    }
    
    // MARK: - StitchClient events
    
    private func handleLogout(provider: Provider?) {
        if let provider = provider {            
            switch provider {
            case .google:
                GIDSignIn.sharedInstance().signOut()
                break
            case .facebook:
                LoginManager().logOut()
                break
            case .emailPassword,.anonymous:
                break
            }
        }
        
        todoItems.removeAll()
        DispatchQueue.main.async { [weak self] in
            self?.todoItemsTableView.reloadData()
            self?.presentAuthViewController(animated: true)
        }
    }
    
    //MARK: - AuthenticationViewControllerDelegate
    
    func authenticationViewControllerDidLogin() {
        dismissAuthViewController(animated: true)
        refreshList()
    }
    
    //MARK: - EmailAuthViewControllerDelegate
    
    func emailAuthViewControllerDidPressCloseEmail() {
        dismissEmailAuthViewController(animated: true)
    }
}
