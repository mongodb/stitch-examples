import Foundation
import ExtendedJson

public enum PushProviderInfoFields: String {
    case FieldType = "type"
    case Config = "config"
}

public protocol PushProviderInfo {
    var providerName: PushProviderName { get }
    var serviceName: String { get }
    
    func toDict() -> [String : Any]
}

public class PushProviderInfoHelper {
    public class func fromPreferences() throws -> [PushProviderInfo] {
        let userDefaults: UserDefaults = UserDefaults(suiteName: Consts.UserDefaultsName)!

        let configs = userDefaults.value(forKey: PrefConfigs) as? [String: Any] ?? [String : Any]()
        
        print(configs)
        return try configs.map { configEntry in
            let info: [String: Any]  = configEntry.value as! [String : Any]
            
            let providerNameOpt = PushProviderName.fromTypeName(typename: info[PushProviderInfoFields.FieldType.rawValue] as! String)
            
            if let providerName = providerNameOpt {
                let config = info[PushProviderInfoFields.Config.rawValue] as! [String: Any]
                
                switch (providerName) {
                case .GCM: return StitchGCMPushProviderInfo.fromConfig(serviceName: configEntry.key, senderId: config[StitchGCMProviderInfoFields.SenderID.rawValue] as! String)
                }
            } else {
                throw StitchError.illegalAction(message: "Provider does not exist")
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
        doc[PushProviderInfoFields.FieldType.rawValue] = providerName as? ExtendedJsonRepresentable
        doc[PushProviderInfoFields.Config.rawValue] = Document()
        return doc
    }
}
