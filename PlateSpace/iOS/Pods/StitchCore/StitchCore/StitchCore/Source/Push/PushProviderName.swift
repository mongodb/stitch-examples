import Foundation

public enum PushProviderName: String {
    case GCM = "gcm"
    
    static let typeNameToProvider: [String: PushProviderName] = [
        PushProviderName.GCM.rawValue: PushProviderName.GCM
    ]
    
    public static func fromTypeName(typename: String) -> PushProviderName? {
        return typeNameToProvider[typename]
    }
}
