import Foundation

/**
 * PushProviderNames are the set of reserved push providers and their respective services.
 */
public enum PushProviderName: String {
    /// Google Cloud Messaging - Currently accessed via the gcm service.
    case GCM = "gcm"

    internal static let typeNameToProvider: [String: PushProviderName] = [
        PushProviderName.GCM.rawValue: PushProviderName.GCM
    ]

    /**
     - parameter typeName: The type claiming to be a provider.
     - returns: The mapped provider name.
     */
    public static func fromTypeName(typename: String) -> PushProviderName? {
        return typeNameToProvider[typename]
    }
}
