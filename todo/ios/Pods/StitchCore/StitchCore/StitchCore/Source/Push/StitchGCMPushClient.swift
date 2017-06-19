import Foundation
import UserNotifications
import ExtendedJson

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
    
    public let userDefaults: UserDefaults = UserDefaults(suiteName: Consts.UserDefaultsName)!

    public let stitchClient: StitchClient
    
    private let _info: StitchGCMPushProviderInfo
    
    public init(stitchClient: StitchClient, info: StitchGCMPushProviderInfo) {
        self.stitchClient = stitchClient
        self._info = info
    }
    
    /**
        -parameter registrationToken: The registration token from GCM.
        -returns: The request payload for registering for push for GCM.
     */
    private func getRegisterPushDeviceRequest(registrationToken: String) -> [String : ExtendedJsonRepresentable] {
        var request = getBaseRegisterPushRequest(serviceName: Props.GCMServiceName.rawValue)
        var data = request[DeviceFields.Data.rawValue] as! [String : ExtendedJsonRepresentable]
        data[DeviceFields.RegistrationToken.rawValue] = registrationToken
        request[DeviceFields.Data.rawValue] = data as ExtendedJsonRepresentable
        return request
    }

    @discardableResult
    public func registerToken(token: String) -> StitchTask<Any> {
        userDefaults.setValue(token, forKey: DeviceFields.RegistrationToken.rawValue)
        let pipeline: Pipeline = Pipeline(action: Actions.RegisterPush.rawValue,
                                          args: getRegisterPushDeviceRequest(registrationToken: token))
        
        return stitchClient.executePipeline(pipeline: pipeline).response(completionHandler: { (task: StitchResult<Any>) -> Void in
            if (task.error != nil) {
                print(task.error ?? "")
            } else {
                self.addInfoToConfigs(info: self._info)
            }
        })
    }
    
    /**
        Deregisters the client from the provider and Stitch.
     
     - returns: A task that can be resolved upon deregistering
     */
    public func deregister() -> StitchTask<Any> {
        let deviceToken = userDefaults.string(forKey: DeviceFields.RegistrationToken.rawValue)
        let pipeline: Pipeline = Pipeline(action: Actions.RegisterPush.rawValue,
                                          args: getRegisterPushDeviceRequest(registrationToken: deviceToken!))
        
        return stitchClient.executePipeline(pipeline: pipeline).response(completionHandler: { (task: StitchResult<Any>) -> Void in
            if (task.error != nil) {
                print(task.error ?? "")
            } else {
                self.removeInfoFromConfigs(info: self._info)
            }
        })
    }
}
