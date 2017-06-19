import Foundation

public enum StitchError: Error {
    
    public enum ServerErrorReason {
        case invalidSession(message: String)
        case domainNotAllowed(message: String)
        case stageSourceRequired(message: String)
        case invalidParameter(message: String)
        case twilioError(message: String)
        case pubNubError(message: String)
        case httpError(message: String)
        case awsError(message: String)
        case mongoDBError(message: String)
        case slackError(message: String)
        case authProviderNotFound(message: String)
        case noMatchingRuleFound(message: String)
        case other(message: String)
        
        internal var isInvalidSession: Bool {
            switch self {
            case .invalidSession:
                return true
            default:
                return false
            }
        }
        
        init(errorCode: String, errorMessage: String) {
            switch errorCode {
            case "InvalidSession":
                self = .invalidSession(message: errorMessage)
                break
            case "DomainNotAllowed":
                self = .domainNotAllowed(message: errorMessage)
                break
            case "StageSourceRequired":
                self = .stageSourceRequired(message: errorMessage)
                break
            case "InvalidParameter":
                self = .invalidParameter(message: errorMessage)
                break
            case "TwilioError":
                self = .twilioError(message: errorMessage)
                break
            case "PubNubError":
                self = .pubNubError(message: errorMessage)
                break
            case "HTTPError":
                self = .httpError(message: errorMessage)
                break
            case "AWSError":
                self = .awsError(message: errorMessage)
                break
            case "MongoDBError":
                self = .mongoDBError(message: errorMessage)
                break
            case "SlackError":
                self = .slackError(message: errorMessage)
                break
            case "AuthProviderNotFound":
                self = .authProviderNotFound(message: errorMessage)
                break
            case "NoMatchingRuleFound":
                self = .noMatchingRuleFound(message: errorMessage)
                break
                
            default:
                self = .other(message: errorMessage)
            }
        }
    }
    
    case serverError(reason: ServerErrorReason)
    case responseParsingFailed(reason: String)
    case unauthorized(message: String)
    case illegalAction(message: String)
    case clientReleased
}


// MARK: - Error Descriptions

extension StitchError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .responseParsingFailed(let reason):
            return reason
        case .serverError(let reason):
            return reason.errorDescription
        case .unauthorized(let message):
            return message
        case .illegalAction(let message):
            return message
        case .clientReleased:
            return "StitchClient was released while performing the task."
        }
    }
}

extension StitchError.ServerErrorReason: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidSession(let message):
            return message
        case .domainNotAllowed(let message):
            return message
        case .stageSourceRequired(let message):
            return message
        case .invalidParameter(let message):
            return message
        case .twilioError(let message):
            return message
        case .pubNubError(let message):
            return message
        case .httpError(let message):
            return message
        case .awsError(let message):
            return message
        case .mongoDBError(let message):
            return message
        case .slackError(let message):
            return message
        case .authProviderNotFound(let message):
            return message
        case .noMatchingRuleFound(let message):
            return message
        case .other(let message):
            return message
        }
    }
}
