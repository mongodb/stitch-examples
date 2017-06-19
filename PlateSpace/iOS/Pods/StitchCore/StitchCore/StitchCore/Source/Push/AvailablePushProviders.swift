import Foundation
import ExtendedJson

/**
    AvailablePushProviders is a collection of available push providers for an app and the information
    needed to utilize them.
 */
public class AvailablePushProviders {
    public var gcm: StitchGCMPushProviderInfo?
    
    typealias AvailablePushProvidersBuilder = (AvailablePushProviders) -> Void
    
    private init(build: AvailablePushProvidersBuilder) {
        build(self)
    }
    
    init(gcm: StitchGCMPushProviderInfo?) {
        self.gcm = gcm
    }
    
    /**
        Fetch available push providers from a Stitch query.
     
        -parameter json: The data returned from Stitch about the providers.
        -returns: A manifest of available push providers.
     */
    static func fromQuery(doc: Document) -> AvailablePushProviders {
        let builder: AvailablePushProvidersBuilder = { builder in
            doc.forEach { configEntry in
                let info = configEntry.value as! Document
                
                let providerName = PushProviderName.fromTypeName(typename: info[PushProviderInfoFields.FieldType.rawValue] as! String)
                let config = info[PushProviderInfoFields.Config.rawValue] as! Document
                
                if let providerName = providerName {
                    switch (providerName) {
                    case .GCM:
                        let provider = StitchGCMPushProviderInfo.fromConfig(serviceName: configEntry.key,
                                                                            senderId: config[StitchGCMProviderInfoFields.SenderID.rawValue] as! String)
                        builder.gcm = provider
                        break
                    }
                }
            }
        }
        
        return AvailablePushProviders(build: builder)
    }
}
