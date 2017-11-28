import Foundation

/// Generic results structure that contains success and failure values.
public enum StitchResult<Value> {
    /// If the Task was successful with a value
    case success(Value)
    /// If the Task failed with a value
    case failure(Error)

    /// Value from the `StitchTask` in the event of success
    public var value: Value? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }

    /// Error from the `StitchTask` in the event of failure
    public var error: Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}

public protocol ExecutionContext {
    func execute(_ work: @escaping () -> Void)
}

extension DispatchQueue: ExecutionContext {
    public func execute(_ work: @escaping () -> Void) {
        self.async(execute: work)
    }
}

public final class InvalidatableQueue: ExecutionContext {

    private var valid = true

    private let queue: DispatchQueue

    public init(queue: DispatchQueue = .main) {
        self.queue = queue
    }

    public func invalidate() {
        valid = false
    }

    public func execute(_ work: @escaping () -> Void) {
        guard valid else { return }
        self.queue.async(execute: work)
    }
}

struct Callback<Value> {
    let onFulfilled: (Value) -> Void
    let onRejected: (Error) -> Void
    let queue: ExecutionContext

    func callFulfill(_ value: Value) {
        queue.execute({
            self.onFulfilled(value)
        })
    }

    func callReject(_ error: Error) {
        queue.execute({
            self.onRejected(error)
        })
    }
}

enum State<Value>: CustomStringConvertible {

    /// The promise has not completed yet.
    /// Will transition to either the `fulfilled` or `rejected` state.
    case pending

    /// The promise now has a value.
    /// Will not transition to any other state.
    case fulfilled(value: Value)

    /// The promise failed with the included error.
    /// Will not transition to any other state.
    case rejected(error: Error)

    var isPending: Bool {
        if case .pending = self {
            return true
        } else {
            return false
        }
    }

    var isFulfilled: Bool {
        if case .fulfilled = self {
            return true
        } else {
            return false
        }
    }

    var isRejected: Bool {
        if case .rejected = self {
            return true
        } else {
            return false
        }
    }

    var value: Value? {
        if case let .fulfilled(value) = self {
            return value
        }
        return nil
    }

    var error: Error? {
        if case let .rejected(error) = self {
            return error
        }
        return nil
    }

    var description: String {
        switch self {
        case .fulfilled(let value):
            return "Fulfilled (\(value))"
        case .rejected(let error):
            return "Rejected (\(error))"
        case .pending:
            return "Pending"
        }
    }
}

public final class StitchTask<Value> {

    private var state: State<Value>
    private let lockQueue = DispatchQueue(label: "promise_lock_queue",
                                          qos: .userInitiated)
    private var callbacks: [Callback<Value>] = []

    public init() {
        state = .pending
    }

    public init(value: Value) {
        state = .fulfilled(value: value)
    }

    public init(error: Error) {
        state = .rejected(error: error)
    }

    public convenience init(queue: DispatchQueue = DispatchQueue.global(qos: .userInitiated),
                            work: @escaping (_ task: StitchTask<Value>,
                                             _ fulfill: @escaping (Value) -> Void,
                                             _ reject: @escaping (Error) -> Void ) throws -> Void) {
        self.init()
        queue.async(execute: {
            do {
                try work(self, self.fulfill, self.reject)
            } catch let error {
                self.reject(error)
            }
        })
    }

    public static func withSuccess<T>(_ value: T) -> StitchTask<T> {
        return StitchTask<T>(value: value)
    }

    public static func withFailure<T>(_ error: Error) -> StitchTask<T> {
        return StitchTask<T>(error: error)
    }

    @discardableResult
    public func response(onQueue: ExecutionContext = DispatchQueue.main,
                         completionHandler: @escaping (StitchTask<Value>) -> Void) -> StitchTask<Value> {
        return StitchTask<Value>(work: { task, fullfill, reject in
            self.addCallbacks(
                on: onQueue,
                onFulfilled: { (value) in
                    fullfill(value)
                    task._result = StitchResult.success(value)
                    completionHandler(task)
                }, onRejected: { (error) in
                    reject(error)
                    task._result = StitchResult.failure(error)
                    completionHandler(task)
                }
            )
        })
    }

    @discardableResult
    public func then<NewValue>(parser: @escaping (Value) throws -> NewValue) -> StitchTask<NewValue> {
        // return a new `StitchTask` with an async block adding a new callback
        // passing the value fulfilled from this task to the next task
        return StitchTask<NewValue>(work: { _, fulfill, reject in
            self.addCallbacks(
                on: DispatchQueue.main,
                onFulfilled: { value in
                    do {
                        // pass the value fulfilled from the current task to be worked
                        // in a new task
                        try StitchTask<NewValue>(value: parser(value)).then(fulfill, reject)
                    } catch let error {
                        reject(error)
                    }
            },
                onRejected: reject
            )
        })
    }

    @discardableResult
    public func then<NewValue>(onQueue: ExecutionContext = DispatchQueue.main,
                               _ onFulfilled: @escaping (Value) throws -> StitchTask<NewValue>)
        -> StitchTask<NewValue> {
        return StitchTask<NewValue>(work: { _, fulfill, reject in
            self.addCallbacks(
                on: onQueue,
                onFulfilled: { value in
                    do {
                        try onFulfilled(value).then(fulfill, reject)
                    } catch let error {
                        reject(error)
                    }
            },
                onRejected: reject
            )
        })
    }

    @discardableResult
    public func then(onQueue: ExecutionContext = DispatchQueue.main,
                     _ onFulfilled: @escaping (Value) -> Void,
                     _ onRejected: @escaping (Error) -> Void = { _ in }) -> StitchTask<Value> {
        _ = StitchTask<Value>(work: { _, fulfill, reject in
            self.addCallbacks(
                on: onQueue,
                onFulfilled: { value in
                    do {
                        fulfill(value)
                        onFulfilled(value)
                    } catch let error {
                        reject(error)
                        onRejected(error)
                    }
                },
                onRejected: { error in
                    reject(error)
                    onRejected(error)
                }
            )
        })
        return self
    }

    @discardableResult
    public func `catch`(onQueue: ExecutionContext = DispatchQueue.main,
                        _ onRejected: @escaping (Error) -> Void) -> StitchTask<Value> {
        return then(onQueue: onQueue, { _ in }, onRejected)
    }

    public func reject(_ error: Error) {
        updateState(.rejected(error: error))
    }

    public func fulfill(_ value: Value) {
        updateState(.fulfilled(value: value))
    }

    public var isPending: Bool {
        return !isFulfilled && !isRejected
    }

    public var isFulfilled: Bool {
        return _result != nil
    }

    public var isRejected: Bool {
        return error != nil
    }

    private var _result: StitchResult<Value>? {
        get {
            return lockQueue.sync(execute: {
                if let value = self.state.value {
                    return StitchResult.success(value)
                } else {
                    return StitchResult.failure(StitchError.ServerErrorReason.other(message: "Unknown"))
                }
            })
        }
        set(value) {
            if let value = value?.value {
                fulfill(value)
            } else {
                reject(value?.error ?? StitchError.ServerErrorReason.other(message: "Unknown"))
            }
        }
    }

    public var result: StitchResult<Value> {
        get {
            return _result ?? .failure(StitchError.ServerErrorReason.other(message: "Unknown"))
        }
        set(value) {
            _result = value
        }
    }
    public var error: Error? {
        return lockQueue.sync(execute: {
            return self.state.error
        })
    }

    private func updateState(_ state: State<Value>) {
        lockQueue.sync(execute: {
            self.state = state
        })
        fireCallbacksIfCompleted()
    }

    private func addCallbacks(on queue: ExecutionContext = DispatchQueue.main,
                              onFulfilled: @escaping (Value) -> Void,
                              onRejected: @escaping (Error) -> Void) {
        let callback = Callback(onFulfilled: onFulfilled,
                                onRejected: onRejected,
                                queue: queue)
        lockQueue.async(execute: {
            self.callbacks.append(callback)
        })
        fireCallbacksIfCompleted()
    }

    private func fireCallbacksIfCompleted() {
        lockQueue.async(execute: {
            guard !self.state.isPending else { return }
            self.callbacks.forEach { callback in
                switch self.state {
                case let .fulfilled(value):
                    callback.callFulfill(value)
                case let .rejected(error):
                    callback.callReject(error)
                default:
                    break
                }
            }
            self.callbacks.removeAll()
        })
    }
}
