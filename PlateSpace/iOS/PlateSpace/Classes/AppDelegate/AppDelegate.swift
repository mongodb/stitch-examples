//
//  AppDelegate.swift
//  PlateSpace
//
//  Created by Miko Halevi on 3/2/17.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import UIKit
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        /// NavigationController appearance
        
        let navigationBarAppearace = UINavigationBar.appearance()
        navigationBarAppearace.tintColor = UIColor.white
        navigationBarAppearace.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        navigationBarAppearace.barTintColor = UIColor(colorLiteralRed: 191.0/255.0, green: 54.0/255.0, blue: 12.0/255.0, alpha: 1)
        navigationBarAppearace.isTranslucent = false
        
        /// UISearchBar appearance
        
        let labelAppearance = UILabel.appearance(whenContainedInInstancesOf: [UISearchBar.self])
        labelAppearance.textColor = UIColor.white
        labelAppearance.alpha = 0.5
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).textColor = UIColor.white
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        /// Register Mongo Entities
        OpeningHours.registerClass(entityMetaData: OpeningHoursMetaDataImp())
        Attributes.registerClass(entityMetaData: AttributesMetaDataImp())
        RestaurantLocation.registerClass(entityMetaData: RestaurantLocationMetaDataImp())
        Restaurant.registerClass(entityMetaData: RestaurantMetaDataImp())
        Review.registerClass(entityMetaData: ReviewMetaDataImp())
        
        return true
    }
    
    // MARK: - open url
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return DeepLinkingManager.shared.handle(url: url) ||
            FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return DeepLinkingManager.shared.handle(url: url) ||
            FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }

   
}

