import Foundation

public struct AuthProviderInfo {
    
    public private(set) var anonymousAuthProviderInfo: AnonymousAuthProviderInfo?
    public private(set) var googleProviderInfo: GoogleAuthProviderInfo?
    public private(set) var facebookProviderInfo: FacebookAuthProviderInfo?
    public private(set) var emailPasswordAuthProviderInfo: EmailPasswordAuthProviderInfo?
    
    //MARK: - Init
    
    init(dictionary: [String : Any]) {
        
        for providerName in dictionary.keys {
            switch providerName {
            case Provider.google.name:
                if let googleProviderInfoDic = dictionary[providerName] as? [String : Any],
                    let googleProviderInfo = GoogleAuthProviderInfo(dictionary: googleProviderInfoDic) {
                    self.googleProviderInfo = googleProviderInfo
                }
            case Provider.facebook.name:
                if let facebookProviderInfoDic = dictionary[providerName] as? [String : Any],
                    let facebookProviderInfo = FacebookAuthProviderInfo(dictionary: facebookProviderInfoDic) {
                    self.facebookProviderInfo = facebookProviderInfo
                }
            case Provider.emailPassword.name:
                emailPasswordAuthProviderInfo = EmailPasswordAuthProviderInfo()
            case Provider.anonymous.name:
                anonymousAuthProviderInfo = AnonymousAuthProviderInfo()
            default:
                break
            }
        }
    }
    
    
}
