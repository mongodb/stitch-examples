import Foundation

import ExtendedJson

/**
 * Stitch GCMPushProviderInfoFields for payload management.
 */
enum StitchGCMProviderInfoFields: String {
    case senderId
}

/**
 * Stitch GCMPushProviderInfo contains information needed to create a `StitchGCMPushClient`.
 */
public class StitchGCMPushProviderInfo: PushProviderInfo {
    /// Name of this provider
    public var providerName: PushProviderName
    /// Name of the associated service
    public var serviceName: String

    /// SenderId provided by Google
    public let senderID: String
    /// Whether or not this was read from properties
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
        return StitchGCMPushProviderInfo(serviceName: serviceName, senderID: senderId, fromProperties: false)
    }

    /**
        Convert this into dictionary to be read/wrote to storage
        
        - Returns: A dictionary containing providerName, senderId, and config fields
    */
    public func toDict() -> [String: Any] {
        var doc = [String: Any]()

        doc[PushProviderInfoFields.type.rawValue] = providerName.rawValue

        var config = [String: Any]()
        config[StitchGCMProviderInfoFields.senderId.rawValue] = self.senderID
        config[PushProviderInfoFields.type.rawValue] = providerName.rawValue

        doc[PushProviderInfoFields.config.rawValue] = config
        return doc
    }

    /**
     * - returns: The provider info as a serializable document.
     */
    func toDocument() -> Document {
        var doc = Document()

        doc[PushProviderInfoFields.type.rawValue] = providerName as? ExtendedJsonRepresentable
        doc[PushProviderInfoFields.config.rawValue] = Document()

        var config = doc[PushProviderInfoFields.config.rawValue] as? Document
        config?[StitchGCMProviderInfoFields.senderId.rawValue] = self.senderID
        return doc
    }
}
