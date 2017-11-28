import Foundation
import ExtendedJson

/**
    AvailablePushProviders is a collection of available push providers for an app and the information
    needed to utilize them.
 */
public class AvailablePushProviders: Codable {
    /// Google Cloud Messaging provider info
    public var gcm: StitchGCMPushProviderInfo?

    typealias AvailablePushProvidersBuilder = (AvailablePushProviders) throws -> Void

    private init(build: AvailablePushProvidersBuilder) throws {
        try build(self)
    }

    init(gcm: StitchGCMPushProviderInfo?) {
        self.gcm = gcm
    }

    public func encode(to encoder: Encoder) throws {

    }

    public required init(from decoder: Decoder) throws {

    }
    /**
        Fetch available push providers from a Stitch query.
     
        -parameter json: The data returned from Stitch about the providers.
        -returns: A manifest of available push providers.
     */
    static func fromQuery(doc: BSONArray) throws -> AvailablePushProviders {
        let builder: AvailablePushProvidersBuilder = { builder in
            try doc.forEach { configEntry in
                guard let info = configEntry as? Document,
                    let typename = info[PushProviderInfoFields.type.rawValue] as? String,
                    let providerName = PushProviderName.fromTypeName(typename: typename),
                    let config = info[PushProviderInfoFields.config.rawValue] as? Document else {
                    throw BsonError.parseValueFailure(value: configEntry, attemptedType: Document.self)
                }

                switch providerName {
                case .GCM:
                    guard let senderId = config[StitchGCMProviderInfoFields.senderId.rawValue] as? String,
                        let name = info["name"] as? String else {
                        throw StitchError.responseParsingFailed(
                            reason: "gcm provider info fields did not contain valid senderId: \(config)")
                    }
                    let provider = StitchGCMPushProviderInfo.fromConfig(serviceName: name,
                                                                        senderId: senderId)
                    builder.gcm = provider
                }
            }
        }

        return try AvailablePushProviders(build: builder)
    }
}
