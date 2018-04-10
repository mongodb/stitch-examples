import Foundation
import UserNotifications
import ExtendedJson
import PromiseKit

/**
 * StitchGCMPushClient is the PushClient for GCM. It handles the logic of registering and
 * deregistering with both GCM and Stitch.
 *
 * It does not actively handle updates to the Instance ID when it is refreshed.
 */
public class StitchGCMPushClient: PushClient {
    enum Props: String {
        case GCMServiceName = "gcm"
        case GCMSenderID = "push.gcm.senderId"
    }

    internal let userDefaults: UserDefaults = UserDefaults(suiteName: Consts.UserDefaultsName)!
    private let stitchClient: StitchClient

    private let _info: StitchGCMPushProviderInfo

    /**
        - Parameters:
            - stitchClient: Current `StitchClient` you want to be associated with this push client
            - info: Provider info for your applications gcm
    */
    public init(stitchClient: StitchClient, info: StitchGCMPushProviderInfo) {
        self.stitchClient = stitchClient
        self._info = info
    }

    /**
        - parameter registrationToken: The registration token from GCM.
        - returns: The request payload for registering for push for GCM.
     */
    private func getRegisterPushDeviceRequest(registrationToken: String) throws -> Document {
        return Document(key: DeviceFields.registrationToken.rawValue, value: registrationToken)
    }

    /**
     Registers the client with the provider and Stitch
     
     - returns: A task that can be resolved upon registering
     */
    @discardableResult
    public func registerToken(token: String) -> Promise<Void> {
        return stitchClient.httpClient.doRequest {
            $0.method = .put
            $0.endpoint = self
                .stitchClient
                .routes
                .pushProvidersRegistartionRoute(provider: self._info.providerName.rawValue)
            try $0.encode(withData: self.getRegisterPushDeviceRequest(registrationToken: token))
        }.done { _ in
            self.addInfoToConfigs(info: self._info)
        }
    }

    /**
        Deregisters the client from the provider and Stitch.
     
     - returns: A task that can be resolved upon deregistering
     */
    public func deregister() -> Promise<Void> {
        return stitchClient.httpClient.doRequest {
            $0.method = .delete
            $0.endpoint = self
                .stitchClient
                .routes
                .pushProvidersRegistartionRoute(provider: self._info.providerName.rawValue)
        }.done { _ in
            self.removeInfoFromConfigs(info: self._info)
        }
    }
}
