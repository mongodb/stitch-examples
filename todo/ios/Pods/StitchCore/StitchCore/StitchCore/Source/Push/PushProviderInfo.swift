import Foundation
import ExtendedJson

internal enum PushProviderInfoFields: String {
    case type, config
}

/// Protocol for the information for any given push provider
public protocol PushProviderInfo {
    /// Name of this provider
    var providerName: PushProviderName { get }
    /// Name of the associated service
    var serviceName: String { get }
    /**
     Convert this into dictionary to be read/wrote to storage
     
     - Returns: A dictionary containing providerName, senderId, and config fields
     */
    func toDict() -> [String: Any]
}

/// Helper class to construct PushProviderInfo from persistent storage
public class PushProviderInfoHelper {
    /**
        Read saved provider information from the UserDefaults
 
        - Throws: `StitchError` if non-existant providers have been saved
 
        - Returns: A list of `PushProviderInfo`
    */
    public class func fromPreferences() throws -> [PushProviderInfo] {
        let userDefaults: UserDefaults = UserDefaults(suiteName: Consts.UserDefaultsName)!

        let configs = userDefaults.value(forKey: prefConfigs) as? [String: Any] ?? [String: Any]()

        print(configs)
        return try configs.map { configEntry in
            guard let info = configEntry.value as? [String: Any],
                let providerName = info[PushProviderInfoFields.type.rawValue] as? String,
                let pushProviderName = PushProviderName.fromTypeName(typename: providerName) else {
                throw StitchError.responseParsingFailed(reason: "\(configs) did not contain valid provider")
            }

            guard let config = info[PushProviderInfoFields.config.rawValue] as? [String: Any] else {
                throw StitchError.responseParsingFailed(reason: "\(configs) did not contain valid configuration")
            }

            switch pushProviderName {
            case .GCM: guard let senderId = config[StitchGCMProviderInfoFields.senderId.rawValue] as? String else {
                throw StitchError.responseParsingFailed(
                    reason: "GCM push provider for \(configs) did not contain valid senderId")
            }
            return StitchGCMPushProviderInfo.fromConfig(serviceName: configEntry.key,
                                                        senderId: senderId)
            }
        }
    }
}

extension PushProviderInfo {
    /**
     Convert PushProviderInfo to a document.
     -returns: The provider info as a serializable document.
     */
    public func toDocument() -> Document {
        var doc = Document()
        doc[PushProviderInfoFields.type.rawValue] = providerName as? ExtendedJsonRepresentable
        doc[PushProviderInfoFields.config.rawValue] = Document()
        return doc
    }
}
