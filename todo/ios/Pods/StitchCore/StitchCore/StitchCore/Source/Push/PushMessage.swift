import Foundation
import ExtendedJson

/// Simple data holder for push messages with Stitch formatting.
@objc public class PushMessage: NSObject {
    enum MessageKeys: String {
        case stitchData = "stitch.data"
        case stitchAppId = "stitch.appId"
        case stitchProviderId = "stitch.providerId"
    }

    let rawData: [AnyHashable: Any]
    let appId: String
    let providerId: String
    let data: Document?

    init(rawData: [AnyHashable: Any], appId: String, providerId: String, data: Document?) {
        self.rawData = rawData
        self.appId = appId
        self.providerId = providerId
        self.data = data
    }

    /**
     Convert rawData to a PushMessage struct
        - parameter data: The data from the GCM push notification.
        - returns: PushMessage constructed from a GCM push notification.
     */
    public class func fromGCM(data: [AnyHashable: Any]) throws -> PushMessage {
        var stitchData: Document?

        if let strData = data[MessageKeys.stitchData.rawValue] as? String,
            let json = strData.data(using: .utf8),
            let rawJson = try? JSONSerialization.jsonObject(with: json,
                                                            options: JSONSerialization.ReadingOptions.allowFragments),
            let xjson = rawJson as? [String: Any?] {
            stitchData = try? Document(extendedJson: xjson)
        }

        guard let appId = data[MessageKeys.stitchAppId.rawValue] as? String,
            let providerId = data[MessageKeys.stitchProviderId.rawValue] as? String else {
            throw StitchError.responseParsingFailed(reason: "\(data) did not contain valid appId or providerId")
        }

        return PushMessage(rawData: data, appId: appId, providerId: providerId, data: stitchData)
    }
}
