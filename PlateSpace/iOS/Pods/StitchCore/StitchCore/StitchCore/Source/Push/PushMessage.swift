import Foundation
import ExtendedJson

@objc public class PushMessage: NSObject {
    enum MessageKeys: String {
        case StitchData = "stitch.data";
        case StitchAppId = "stitch.appId";
        case StitchProviderId = "stitch.providerId";
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
     * -parameter data: The data from the GCM push notification.
     * -returns: PushMessage constructed from a GCM push notification.
     */
    public class func fromGCM(data: [AnyHashable: Any]) ->  PushMessage {
        var stitchData: Document?
        
        if let json = data[MessageKeys.StitchData.rawValue] {
            stitchData = try? Document(extendedJson: JSONSerialization.jsonObject(with: (json as! String).data(using: .utf8)!, options: JSONSerialization.ReadingOptions.allowFragments) as! [String : Any])
        }
    
        let appId = data[MessageKeys.StitchAppId.rawValue]
        let providerId = data[MessageKeys.StitchProviderId.rawValue]
        
        return PushMessage(rawData: data, appId: appId as! String, providerId: providerId as! String, data: stitchData);
    }
}
