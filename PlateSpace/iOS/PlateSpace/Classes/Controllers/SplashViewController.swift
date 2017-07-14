//
//  SplashViewController.swift
//  PlateSpace
//
//  Created by Ofir Zucker on 08/05/2017.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {
   
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        checkLoginStatus()
    }
    
    // MARK: - UI
    
    private func setupUI() {
        navigationController?.isNavigationBarHidden = true
    }
    
    // MARK: - Navigation
    
    private func checkLoginStatus() {
        
        /// Navigate to the main screen if user is logged in
        /// Navigate to tht login screen if user is not logged in
        
        if MongoDBManager.shared.stitchClient.isAuthenticated {
            navigateToRestaurantList()
        } else {
            navigateToSignup()
        }
    }
    
    private func navigateToSignup() {
        if let controller = storyboard?.instantiateViewController(withIdentifier: LoginViewController.stringFromClass()) as? LoginViewController {
            controller.controllerType = .signup
            navigationController?.pushViewController(controller, animated: false)
        }
    }
    
    private func navigateToRestaurantList(){
        if let controller = storyboard?.instantiateViewController(withIdentifier: RestaurantListViewController.stringFromClass()) as? RestaurantListViewController {
            navigationController?.pushViewController(controller, animated: false)
        }
    }
}
