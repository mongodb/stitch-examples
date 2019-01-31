import UIKit
import StitchCore
import StitchRemoteMongoDBService

private let todoListsDatabase = "todo"
private let todoItemsCollection = "items"
private let todoListsCollection = "lists"
private let todoIndexSwapsCollection = "index_swaps"

let stitch = try! Stitch.initializeAppClient(withClientAppID: "<APP_ID>")

var itemsCollection: RemoteMongoCollection<TodoItem>!
var listsCollection: RemoteMongoCollection<TodoList>!
var indexSwapsCollection: RemoteMongoCollection<IndexSwap>!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let mongoClient = try! stitch.serviceClient(fromFactory: remoteMongoClientFactory,
                                                    withName: "mongodb-atlas")

        // Set up collections
        itemsCollection = mongoClient
            .db(todoListsDatabase)
            .collection(todoItemsCollection, withCollectionType: TodoItem.self)
        listsCollection = mongoClient
            .db(todoListsDatabase)
            .collection(todoListsCollection, withCollectionType: TodoList.self)
        indexSwapsCollection = mongoClient
            .db(todoListsDatabase)
            .collection(todoIndexSwapsCollection, withCollectionType: IndexSwap.self)

        return true
    }
}
