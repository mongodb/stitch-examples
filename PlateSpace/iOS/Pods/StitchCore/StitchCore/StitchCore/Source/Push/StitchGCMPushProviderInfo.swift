import Foundation

import ExtendedJson

/**
 * Stitch GCMPushProviderInfoFields for payload management.
 */
enum StitchGCMProviderInfoFields: String {
    case SenderID = "senderId"
}

/**
 * Stitch GCMPushProviderInfo contains information needed to create a `StitchGCMPushClient`.
 */
public class StitchGCMPushProviderInfo: PushProviderInfo {
    public var providerName: PushProviderName
    public var serviceName: String
    
    public let senderID: String
    public let fromProperties: Bool
    
    private init(serviceName: String, senderID: String, fromProperties: Bool) {
        self.providerName = PushProviderName.fromTypeName(typename: PushProviderName.GCM.rawValue)!
        self.serviceName = serviceName
        
        self.senderID = senderID
        self.fromProperties = fromProperties
    }
    
    /**
     * - parameter serviceName: The service that will handle push for this provider.
     * - parameter config: The persisted configuration of this provider.
     * - returns: A GCMPushProviderInfo sourced from a persisted config.
     */
    public class func fromConfig(serviceName: String, senderId: String) -> StitchGCMPushProviderInfo {
        return StitchGCMPushProviderInfo(serviceName: serviceName, senderID: senderId, fromProperties: false)
    }
    
    /**
     * - parameter serviceName: The service that will handle push for this provider.
     * - parameter senderId: The GCM Sender ID.
     * - returns: A GCMPushProviderInfo sourced from a Sender ID.
     */
    public class func fromSenderId(serviceName: String, senderId: String) -> StitchGCMPushProviderInfo {
        return StitchGCMPushProviderInfo(serviceName: serviceName, senderID: senderId, fromProperties: false);
    }
    
    public func toDict() -> [String : Any] {
        var doc = [String: Any]()
        
        doc[PushProviderInfoFields.FieldType.rawValue] = providerName.rawValue
        
        var config = [String : Any]()
        config[StitchGCMProviderInfoFields.SenderID.rawValue] = self.senderID
        config[PushProviderInfoFields.FieldType.rawValue] = providerName.rawValue

        doc[PushProviderInfoFields.Config.rawValue] = config
        return doc
    }
    /**
     * - returns: The provider info as a serializable document.
     */
    func toDocument() -> Document {
        var doc = Document()
        
        doc[PushProviderInfoFields.FieldType.rawValue] = providerName as? ExtendedJsonRepresentable
        doc[PushProviderInfoFields.Config.rawValue] = Document()
        
        var config = doc[PushProviderInfoFields.Config.rawValue] as! Document
        config[StitchGCMProviderInfoFields.SenderID.rawValue] = self.senderID
        return doc
    }
}
