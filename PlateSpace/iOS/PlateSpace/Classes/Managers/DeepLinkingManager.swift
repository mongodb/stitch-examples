//
//  DeepLinkingManager.swift
//  PlateSpace
//
//  Created by Ofir Zucker on 04/06/2017.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import Foundation

protocol DeepLinkingManagerDelegate: class {
    func deepLinkManagerDidRecieveEmailConfirmation(withToken token: String, tokenId: String)
    func deepLinkManagerDidRecieveResetPassword(withToken token: String, tokenId: String)

}

class DeepLinkingManager {
    
    // MARK: - Properties
    private struct Consts {
        
        /// This should match the URL Scheme added in the info pList, and to the app scheme as defined on Stitch dashboard
       static let appScheme = "platespace"
        
        /// Deep link types should match the keys returned from the server
        static let deepLinkConfirmEmail = "confirmEmail"
        static let deepLinkResetPassword = "resetPassword"
        
    }
    
    static let shared = DeepLinkingManager()
    
    weak var delegate: DeepLinkingManagerDelegate?
    
    // MARK: - URL Handling
    func handle(url: URL) -> Bool {
        
        if let scheme = url.scheme, scheme == Consts.appScheme {
            
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            guard let queryItems = components?.queryItems else {
                print("Deep link URL does not have query items")
                return false
            }
            
            var params: [String : String] = [:]
            for item in queryItems {
                params[item.name] = item.value
            }
            
            /// Make sure the url contained a token and token id
            guard let token = params["token"],
                let tokenId = params["tokenId"] else {
                    print("Deep link does not have token or token Id")
                    return false
            }
        
            if let host = url.host {
                
                /// Handle email confirmation deep link
                if host == Consts.deepLinkConfirmEmail {
                    delegate?.deepLinkManagerDidRecieveEmailConfirmation(withToken: token, tokenId: tokenId)
                    return true
                }
                
                /// Handle reset password deep link (Not implemented in Sample app)
                if host == Consts.deepLinkResetPassword {
                    delegate?.deepLinkManagerDidRecieveResetPassword(withToken: token, tokenId: tokenId)
                    return true
                }
            }
        }
        
        return false
    }
}
