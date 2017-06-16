//
//  MongoDBManager.swift
//  SoLoMoSample
//
//  Created by Miko Halevi on 6/13/17.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import Foundation


import Foundation
import MongoCore
import MongoDB

class MongoDBManager {
    
    // MARK: - Properties
    
    /// Shared Mongo Manager instance
    static let shared = MongoDBManager()
    
    let stitchClient: StitchClient
    let mongoClient: MongoClient

    
    // MARK: - Private Constants, Please change your app id in Stitch-Info.plist
    
    /// The app id can be found on Stitch Dashboard
    private static var appId: String  {
        let path = Bundle.main.path(forResource: "SoLoMoSample-Info", ofType: "plist")
        let infoDic = NSDictionary(contentsOfFile: path!) as? [String: AnyObject]
        let appId = infoDic!["APP_ID"] as! String
        assert(appId != "<Your-App-ID>", "Insert your App ID in SoLoMoSample-Info")
        return appId

    }
    
    /// The service name can be found on Stitch Dashboard
    private static let serviceName: String  = "Solomo-iRest"
    
    /// The user name key inside the authUser data dictionary
    private static let userNameKey          = "name"
    
    /// The user email key inside the authUser data dictionary
    private static let userEmailKey         = "email"
    
    // MARK: - Shared Constants
    
    /// The database name is the defined name in the MongoDB server
    static let databaseName: String         = "iRestDB"
    
    /// The restaurants collection name as defined on the Stitch Dashboard
    static let collectionNameRestaurants    = "restaurants"
    
    /// The reviews & ratings collection name as defined on the Stitch Dashboard
    static let collectionNameReviewsRatings = "reviewsRatings"
    
    init() {
        
        /// Init a Stitch client
        stitchClient = StitchClientImpl(appId: MongoDBManager.appId)
        
        /// Init a mongo client
        mongoClient = MongoClientImpl(stitchClient: stitchClient, serviceName: MongoDBManager.serviceName)
    }
    
    /// Get the logged in user name
    func userName() -> String? {
        return (stitchClient.authUser?.data[MongoDBManager.userNameKey] as? String) ?? userNameFromEmail()
    }
    
    /// If we log in using email, we do not have a username - extract it from the email address
    func userNameFromEmail() -> String? {
        if let email = stitchClient.authUser?.data[MongoDBManager.userEmailKey] as? String {
            let emailComponents = email.components(separatedBy: "@")
            
            /// Extract the first component of the email and use it as the username
            if !emailComponents.isEmpty {
                return emailComponents.first
            }
        }
        
        return nil
    }

}
