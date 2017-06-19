import Foundation

public protocol NetworkAdapter {
    func requestWithArray(url: String, method: NAHTTPMethod, parameters: [[String : Any]]?, headers: [String : String]?) ->  StitchTask<Any>
    func requestWithJsonEncoding(url: String, method: NAHTTPMethod, parameters: [String : Any]?, headers: [String : String]?) ->  StitchTask<Any>
    func cancelAllRequests()
    
}

public enum NAHTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}
