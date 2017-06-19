import Foundation

open class StitchTask<Result> {
    
    private let queue: OperationQueue
    
    public var result: StitchResult<Result>? {
        didSet{
            queue.isSuspended = false
        }
    }
    
    // MARK: - Init
    
    public init() {
        queue = {
            let operationQueue = OperationQueue()
            
            operationQueue.maxConcurrentOperationCount = 1
            operationQueue.isSuspended = true
            operationQueue.qualityOfService = .utility
            
            return operationQueue
        }()
    }
    
    public convenience init(error: Error) {
        self.init()
        
        // this call is done within `defer` to make sure the `didSet` observers gets called, since observers are not called when a property is first initialized
        defer {
            result = .failure(error)
        }
    }
    
    // MARK: - Public
    
    @discardableResult
    public func response(onQueue queue: DispatchQueue? = nil, completionHandler: @escaping (_ result: StitchResult<Result>) -> Swift.Void) -> StitchTask<Result> {
        self.queue.addOperation {
            (queue ?? DispatchQueue.main).async {
                completionHandler(self.result!)
            }
        }
        return self
    }
    
}

// MARK: - Continuation Task

extension StitchTask {
    
    @discardableResult
    public func continuationTask<NewResultType>(parser: @escaping (_ oldResult: Result) throws -> NewResultType) -> StitchTask<NewResultType>{
        let newTask = StitchTask<NewResultType>()
        response(onQueue: DispatchQueue.global(qos: .utility)) { (stitchResult: StitchResult<Result>) in
            switch stitchResult {
            case .success(let oldResult):
                do {
                    let newResult = try parser(oldResult)
                    newTask.result = .success(newResult)
                }
                catch {
                    newTask.result = .failure(error)
                }
                break
            case .failure(let error):
                newTask.result = .failure(error)
                break
            }
        }
        return newTask
    }
    
}



public enum StitchResult<Value> {
    case success(Value)
    case failure(Error)
    
    public var value: Value? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    public var error: Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
    
}
