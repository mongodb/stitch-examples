import Foundation
import ExtendedJson
import PromiseKit

let prefConfigs: String = "apns.configs"

internal enum DeviceFields: String {
    case service
    case data
    case registrationToken
    case deviceId
    case appId
    case appVersion
    case platform
    case platformVersion
}

internal enum Actions: String {
    case registerPush
    case deregisterPush
}

/**
    A PushClient is responsible for allowing users to register and
    deregister for push notifications sent from Stitch or directly from the provider.
 */
public protocol PushClient {
    /**
        Registers the client with the provider and Stitch
 
        - returns: A task that can be resolved upon registering
    */
    @discardableResult
    func registerToken(token: String) -> Promise<Void>

    /**
        Deregisters the client from the provider and Stitch.
        
        - returns: A task that can be resolved upon deregistering
    */
    @discardableResult
    func deregister() -> Promise<Void>
}

extension PushClient {
    /**
     - parameter info: The push provider info to persist.
     */
    func addInfoToConfigs(info: PushProviderInfo) {
        let userDefaults = UserDefaults(suiteName: Consts.UserDefaultsName)!

        var configs: [String: Any] = userDefaults.value(forKey: prefConfigs) as? [String: Any] ?? [String: Any]()

        configs[info.serviceName] = info.toDict()

        userDefaults.setValue(configs, forKey: prefConfigs)
    }

    /**
     - parameter info: The push provider info to no longer persist
     */
    public func removeInfoFromConfigs(info: PushProviderInfo) {
        let userDefaults = UserDefaults(suiteName: Consts.UserDefaultsName)!

        var configs = [String: Any]()

        let configOpt = userDefaults.value(forKey: prefConfigs)

        if let config = configOpt as? [String: Any] {
            configs = config
        }

        configs[info.serviceName] = nil
        userDefaults.setValue(configs, forKey: prefConfigs)
    }

    /**
     - parameter serviceName: The service that will handle push
     for this client
     - returns: A generic device registration request
     */
    public func getBaseRegisterPushRequest(serviceName: String) -> Document {
        return [
            DeviceFields.service.rawValue: serviceName,
            DeviceFields.data.rawValue: Document()
        ]
    }

    /**
     - parameter serviceName: The service that will handle push
     for this client
     - returns: A generic device deregistration request
     */
    func getBaseDeregisterPushDeviceRequest(serviceName: String) -> Document {
        var request = Document()

        request[DeviceFields.service.rawValue] = serviceName

        return request
    }
}
