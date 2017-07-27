//
//  AppDelegate.swift
//  MongoDBSample
//
//

import UIKit
import FBSDKLoginKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Facebook
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)                
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: open url
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        var openUrl = GIDSignIn.sharedInstance().handle(url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String, annotation: options[UIApplicationOpenURLOptionsKey.annotation]) || FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
        
        
        if !openUrl && url.scheme! == "stitchtodo" {
            openUrl = true
            if let navVC = window?.rootViewController as? UINavigationController,
                let todoVC = navVC.topViewController as? TodoListViewController{
                
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                guard let queryItems = components?.queryItems else {
                    return false
                }
                
                var params: [String : String] = [:]
                for item in queryItems {
                    params[item.name] = item.value
                }
                
                guard let token = params["token"],
                    let tokenId = params["tokenId"] else {
                        return false
                }
                
                if let host = url.host {
                    var emailAuthOpType: EmailAuthOperationType?
                    if host == "confirmEmail" {
                        emailAuthOpType = .confirmEmail(token: token, tokenId: tokenId)
                    }
                    if host == "resetPassword" {
                        emailAuthOpType = .resetPassword(token: token, tokenId: tokenId)
                    }
                    
                    guard let emailAuthOperationType = emailAuthOpType else {
                        return false
                    }
                    
                    if todoVC.isViewLoaded {
                        todoVC.presentEmailAuthViewController(operationType: emailAuthOperationType)
                    }
                    else {
                        todoVC.emailAuthOpToPresentWhenOpened = emailAuthOperationType
                    }
                }                
            }
        }
        return openUrl
    }    

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation) || FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
}

