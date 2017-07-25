//
//  MongoDBManager.swift
//  PlateSpace
//

import Foundation

import StitchCore
import MongoDBService

class MongoDBManager {
    
    // MARK: - Properties
    
    /// Shared Mongo Manager instance
    static let shared = MongoDBManager()
    
    let stitchClient: StitchClient
    let mongoClient: MongoDBClient

    var authProvider: AuthProvider?
    
    // MARK: - Private Constants, Please change your app id in Stitch-Info.plist
    
    /// The app id can be found on Stitch Dashboard
    private static var appId: String  {
        let path = Bundle.main.path(forResource: "PlateSpace-Info", ofType: "plist")
        let infoDic = NSDictionary(contentsOfFile: path!) as? [String: AnyObject]
        let appId = infoDic!["APP_ID"] as! String
        assert(appId != "<Your-App-ID>", "Insert your App ID in PlateSpace-Info")
        return appId

    }
    
    
    /// The user name key inside the authUser data dictionary
    private static let userNameKey          = "name"
    
    /// The user email key inside the authUser data dictionary
    private static let userEmailKey         = "email"
    
    // MARK: - Shared Constants
    
    /// The database name is the defined name in the MongoDB server
    static let databaseName: String         = "platespace"
    
    /// The restaurants collection name as defined on the Stitch Dashboard
    static let collectionNameRestaurants    = "restaurants"
    
    /// The reviews & ratings collection name as defined on the Stitch Dashboard
    static let collectionNameReviewsRatings = "reviewsRatings"
    
    init() {
        
        /// Init a Stitch client
        stitchClient = StitchClient(appId: MongoDBManager.appId)
        
        
        /// Init a Mongodb client
        mongoClient =  MongoDBClient(stitchClient: stitchClient, serviceName: "mongodb-atlas")
    }
    
    func isAnonymous() -> Bool {
        return authProvider is AnonymousAuthProvider
    }
    
    /// Get the logged in user name
    func userName(completionHandler: @escaping (String?) -> Void) -> Void {
        self.stitchClient.fetchUserProfile().response(completionHandler: { (userProfile) in
            if let userProfile = userProfile.value {
                if let userName = userProfile.data[MongoDBManager.userNameKey] as? String {
                    completionHandler(userName)
                } else {
                    self.userNameFromEmail(completionHandler: completionHandler)
                }
            }
        })
    }
    
    /// If we log in using email, we do not have a username - extract it from the email address
    func userNameFromEmail(completionHandler: @escaping (String?) -> Void) -> Void {
        self.stitchClient.fetchUserProfile().response(completionHandler: { (userProfile) in
            if let userProfile = userProfile.value {
                if let email = userProfile.data[MongoDBManager.userEmailKey] as? String {
                    let emailComponents = email.components(separatedBy: "@")
                    
                    /// Extract the first component of the email and use it as the username
                    if !emailComponents.isEmpty {
                        completionHandler(emailComponents.first)
                    }
                }
            }
        })
    }

}
