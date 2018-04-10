import Foundation
import PromiseKit

/// Protocol to be used to handle requests if Alamofire is not desired
public protocol NetworkAdapter {
    /**
     Make a network request using Json encoding for the params.
     
     - Parameters:
         - url: Resource to call
         - method: HTTP verb to use with this call
         - parameters: JsonEncoded parameters as a dictionary
         - headers: Array of key value pairs to send as headers
     
     - Returns: A new `StitchTask`
     */
    func requestWithJsonEncoding(url: String,
                                 method: NAHTTPMethod,
                                 data: Data?,
                                 headers: [String: String]?) ->  Promise<(Int, Data?)>
    /**
     Cancel all active requests.
     */
    func cancelAllRequests()
}

/// Enum of commonly used HTTP Verbs
public enum NAHTTPMethod: String {
    /// Used to describe comm options for the resource
    case options = "OPTIONS"
    /// Used to retrieve information from a resource
    case get     = "GET"
    /// Identitical to get but must not return a message body in the response
    case head    = "HEAD"
    /// Used to request an entity be accepted by a resource
    case post    = "POST"
    /// Used to request an entity be stored by a resource
    case put     = "PUT"
    /// Used to request an entity be modified by a resource
    case patch   = "PATCH"
    /// Used to request a resource be deleted by the origin
    case delete  = "DELETE"
    /// Invoke a loop-back of the request
    case trace   = "TRACE"
    /// For use with a proxy that can be switched to a tunnel
    case connect = "CONNECT"
}
