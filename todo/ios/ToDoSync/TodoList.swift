import Foundation
import MongoSwift

struct TodoList: Codable {
    enum CodingKeys: String, CodingKey {
        case id = "_id", todos
    }

    let id: String
    let todos: [ObjectId]?

    init(id: String) {
        self.id = id
        self.todos = nil
    }
}

struct IndexSwap: Codable {
    static let sessionId = ObjectId()

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case todoId = "todo_id"
        case fromIndex = "from_index"
        case toIndex = "to_index"
        case generatedBy = "generated_by"
    }
    
    let id: String
    let todoId: ObjectId?
    let fromIndex: Int?
    let toIndex: Int?
    let generatedBy: ObjectId?

    init(id: String) {
        self.id = id
        self.todoId = nil
        self.fromIndex = nil
        self.toIndex = nil
        self.generatedBy = nil
    }

    init(id: String,
         todoId: ObjectId,
         fromIndex: Int,
         toIndex: Int) {
        self.id = id
        self.todoId = todoId
        self.fromIndex = fromIndex
        self.toIndex = toIndex
        self.generatedBy = IndexSwap.sessionId
    }
}
