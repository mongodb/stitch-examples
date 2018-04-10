import Foundation

/**
    PushManager is responsible for handling the creation of PushClient while handling
    any events from the [StitchClient] that require changes to the clients.
 */
public class PushManager: AuthDelegate {
    private let stitchClient: StitchClient
    private var clients: [PushClientKey: PushClient] = [:]

    private struct PushClientKey: Hashable {
        let clientAppId: String
        let providerName: PushProviderName

        var hashValue: Int {
            return "\(clientAppId) \(providerName)".hashValue
        }

        static func == (left: PushClientKey, right: PushClientKey) -> Bool {
            return left.clientAppId == left.clientAppId && left.providerName == right.providerName
        }
    }

    init(client: StitchClient) {
        self.stitchClient = client
        stitchClient.addAuthDelegate(delegate: self)
    }

    /**
        - parameter info: Information required to build a client.
        - returns: A [[PushClient]] representing the given provider.
     */
    func forProvider(info: PushProviderInfo) throws -> PushClient {
        let key = PushClientKey(clientAppId: stitchClient.appId, providerName: info.providerName)
        if let client = clients[key] {
            return client
        }

        var pClient: PushClient! = nil
        switch info {
        case let gcmInfo as StitchGCMPushProviderInfo:
            pClient = StitchGCMPushClient(stitchClient: self.stitchClient,
                                          info: gcmInfo)
        default:
            throw StitchError.illegalAction(message: "unknown push provider info \(info)")
        }

        clients[key] = pClient
        return pClient
    }

    /**
        Does nothing on login
    */
    public func onLogin() {}

    /**
        Deregisters all active and previously active clients. This is only a best effort and
        there may be a period of time where the application will still receive notifications.
     */
    public func onLogout() {
        do {
            // Create any missing clients from saved data
            try PushProviderInfoHelper.fromPreferences().forEach { info in
                 try _ = self.forProvider(info: info)
            }
        } catch _ {
            // Ignore errors
        }

        // Notify Stitch that we no longer want updates
        clients.values.forEach { client in client.deregister() }

        clients.removeAll()
    }
}
