import MongoSwift

/// A todo item from a MongoDB document
struct TodoItem: Codable, Hashable, Comparable {
    static func < (lhs: TodoItem, rhs: TodoItem) -> Bool {
        return lhs.index < rhs.index
    }

    static func == (lhs: TodoItem, rhs: TodoItem) -> Bool {
        return bsonEquals(lhs.id, rhs.id)
    }

    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case ownerId = "owner_id"
        case task, checked
        case doneDate = "done_date"
        case index
    }

    let id: ObjectId
    let ownerId: String
    let task: String

    var doneDate: Date? {
        didSet {
            itemsCollection.sync.updateOne(
                filter: ["_id": id],
                update: ["$set": [CodingKeys.doneDate.rawValue: doneDate ?? BSONNull()] as Document],
                options: nil) { _ in

            }
        }
    }

    var index: Int {
        didSet {
            itemsCollection.sync.updateOne(
                filter: ["_id": id],
                update: ["$set": [CodingKeys.index.rawValue: index] as Document],
                options: nil) { _ in

            }
        }
    }
    var checked: Bool {
        didSet {
            itemsCollection.sync.updateOne(
                filter: ["_id": id],
                update: ["$set": [CodingKeys.checked.rawValue: checked] as Document],
                options: nil) { _ in
                
            }
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id.oid)
    }
}
