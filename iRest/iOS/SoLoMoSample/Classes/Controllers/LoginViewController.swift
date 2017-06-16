//
//  LoginViewController.swift
//  SoLoMoSample
//
//  Created by Miko Halevi on 3/2/17.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import MongoCore

enum LoginViewControllerType {
    case signup
    case login
}

class LoginViewController: UIViewController, UITextFieldDelegate, DeepLinkingManagerDelegate {
    
    // MARK: - Properties
    
    @IBOutlet weak var passwordBlurView: UIVisualEffectView!
    @IBOutlet weak var emailBlurView: UIVisualEffectView!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var authenticateButton: UIButton!
    @IBOutlet weak var otherAuthenticationButton: UIButton!
    
    var controllerType : LoginViewControllerType = .signup
    
    var enteredEmail: String?
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Try silent login to FB if we have an access token
        if let accessToken = FBSDKAccessToken.current() {
            login(withAccessToken: accessToken)
        }
        
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /// If we opened this screen with an email already entered - fill it
        emailTextField.text = enteredEmail
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        DeepLinkingManager.shared.delegate = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        /// Assign the delegate of DeepLinkManager to handle confirm email deep link.
        DeepLinkingManager.shared.delegate = self
    }
    
    // MARK: - UI
    
    private func setupUI() {
        navigationController?.isNavigationBarHidden = true
        
        passwordBlurView.layer.cornerRadius = 20
        emailBlurView.layer.cornerRadius = 20
        
        let font = UIFont.systemFont(ofSize: 14.0)
        let color = UIColor.white
        let attributes = [NSForegroundColorAttributeName : color, NSFontAttributeName : font]
        
        emailTextField.attributedPlaceholder = NSAttributedString(string: "Email", attributes: attributes)
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "Password", attributes: attributes)
        
        if controllerType == .login {
            authenticateButton.setTitle("Log In", for: .normal)
            otherAuthenticationButton.setTitle("Create New Account", for: .normal)
        }
        
    }
    
    // MARK: - Navigation

    private func navigateToRestaurantsList(){
        if let controller = storyboard?.instantiateViewController(withIdentifier: RestaurantListViewController.stringFromClass()) as? RestaurantListViewController {
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    private func navigateToLogin(){
        if let controller = storyboard?.instantiateViewController(withIdentifier: LoginViewController.stringFromClass()) as? LoginViewController {
            controller.controllerType = .login
            controller.enteredEmail = emailTextField.text
            navigationController?.pushViewController(controller, animated: false)
        }
    }
    
    // MARK - UITextField
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
 
    // MARK: - Actions
    
    @IBAction func authenticateButtonPressed(_ sender: Any) {
        
        view.endEditing(true)
        
        /// Input validation (check for missing fields)
        guard
            let email = emailTextField.text,
            let password = passwordTextField.text
            else {
                print("No Email / Password")
                showAlert(withTitle: "Missing Fields", message: "Please fill a valid email and password.")
                return
        }
        
        
        if isValidFields() {
            switch controllerType {
            case .login:
                performLogin(withEmail: email, password: password)
            case .signup:
                performRegister(withEmail: email, password: password)
            }
        }
    }

    @IBAction func otherAuthenticationButtonPressed(_ sender: Any) {
        if controllerType == .login {
            _ = navigationController?.popViewController(animated: false)
        }
        else{
            /// Reset text fields and change to Login state
            emailTextField.text = nil
            passwordTextField.text = nil
            navigateToLogin()
        }
    }
    
    @IBAction func skipButtonPressed(_ sender: Any) {
        /// Perform anonymous login
        performAnonymousLogin()
    }
    
    @IBAction func facebookAuthonticateButtonPressed(_ sender: Any) {
        /// Login to FB
       performFacebookLogin()
    }
    
    // MARK: - Login logic
    
    /// Register + Login validations
    private func isValidFields() -> Bool {
       
        /// Check if email field is valid
        if !String.isValidEmail(emailTextField.text) {
            /// Email invalid
            showAlert(withTitle: "Invalid email", message: "Please fill a valid email")
            return false
        }
        
        /// Check is password is valid
        if !String.isValidPassword(passwordTextField.text) {
            /// Password invalid
            showAlert(withTitle: "Invalid password", message: "Please fill in a password.")
            return false
        }
        
        return true
    }
    
    /// Register Email
    private func performRegister(withEmail email: String, password: String) {
        
        showLoadingView(show: true)
        
        MongoDBManager.shared.stitchClient.register(email: email, password: password).response { [weak self] result in
            
            self?.showLoadingView(show: false)

            switch result {
            case .success(_):
                
                print("Register successful")
                self?.showAlert(withTitle: "Register successful!", message: "Please validate your email address by clicking the link sent to \(email).")
                
                /// A validation link has been sent to the provided email.
                /// In order to complete the registration enter the email address and click the link.
                /// Once the link is clicked, the AppDelegate would catch the deep link, pass it to the DeepLinkManager, which would pass it to its delegate.
                /// The DeepLinkManager delegate has already been assigned on viewDidAppear so it would catch the deep link even if the user has switched between the Login and Signup screens
                
            case .failure(let error):
                
                print("Register failed: \(error.localizedDescription)")
                self?.showAlert(withTitle: "Register Failed", message: error.localizedDescription)
            }
        }
    }
    
    /// Login Email
    private func performLogin(withEmail email: String, password: String) {
        
        showLoadingView(show: true)
        
        /// Create a provider with the email and password
        let provider = EmailPasswordAuthProvider(username: email, password: password)
        
        /// Login with this provider
        login(withProvider: provider)
    }
    
    /// Anonymous Login
    private func performAnonymousLogin() {
        showLoadingView(show: true)
        
        MongoDBManager.shared.stitchClient.anonymousAuth().response { [weak self] (result) in
            self?.showLoadingView(show: false)
            
            switch result {
            case .success:
                self?.navigateToRestaurantsList()
            case .failure(let error):
                print("Error skipping log in: \(error.localizedDescription)")
                self?.showErrorAlert()
            }
        }
    }
    
    /// Facebook Login
    private func performFacebookLogin() {
        showLoadingView(show: true)
        
        FBSDKLoginManager().logIn(withReadPermissions: ["email"], from: self) { [weak self]
            (loginResult: FBSDKLoginManagerLoginResult?, error: Error?) in
            if let accessToken = FBSDKAccessToken.current() {
                self?.login(withAccessToken: accessToken)
            } else {
                print("Error logging in with facebook: \(error?.localizedDescription)")
                OperationQueue.main.addOperation({
                    self?.showLoadingView(show: false)
                    self?.showAlert(withTitle: "Error logging in with Facebook", message: error?.localizedDescription)
                })
            }
        }
    }
    
    /// Login with FB token
    private func login(withAccessToken accessToken: FBSDKAccessToken) {
        
        /// Create provider using the FB token
        let provider = FacebookAuthProvider(accessToken: accessToken.tokenString)
        
        /// Login with this provider
        login(withProvider: provider)
    }
    
    /// Login with provider
    private func login(withProvider provider: AuthProvider) {
        MongoDBManager.shared.stitchClient.login(withProvider: provider).response { [weak self] (result) in
            
            self?.showLoadingView(show: false)
            
            switch result {
            case .success:
                self?.navigateToRestaurantsList()
            case .failure(let error):
                print("failed logging in Stitch. error: \(error.localizedDescription)")
                self?.showAlert(withTitle: "Log In Failed", message: error.localizedDescription)
            }
        }
    }
    
    // MARK: - DeepLinkingManagerDelegate
    
    func deepLinkManagerDidRecieveEmailConfirmation(withToken token: String, tokenId: String) {
        
       confirmEmail(withToken: token, tokenId: tokenId)
    }
    
    func deepLinkManagerDidRecieveResetPassword(withToken token: String, tokenId: String) {
        /// Handle reset password deep link with the StitchClient's resetPassword(token: String, tokenId: String) func.
        /// Currently not implemented in the sample app
    }
    
    // MARK: - Email Confirmation
    
    private func confirmEmail(withToken token: String, tokenId: String) {
        showLoadingView(show: true)
        
        /// Confirm the email with the token & token id returned through the deep link.
        /// Once the email is confirmed, the user would be able to login with this email
        MongoDBManager.shared.stitchClient.emailConfirm(token: token, tokenId: tokenId).response { [weak self] result in
            
            self?.showLoadingView(show: false)
            
            switch result {
            case .success(_):
                print("Email confirmed!")
                
                /// If the user is still in the signup screen, navigate to the login screen
                if self?.controllerType == .signup {
                    self?.navigateToLogin()
                }
                self?.showAlert(withTitle: "Email confirmed!", message: "Please login with you email and password")
            case .failure(let error):
                print("Email confirmation failed with error: \(error.localizedDescription)")
                self?.showAlert(withTitle: "Email confirmation failed", message: error.localizedDescription)
            }
        }
    }
    
}
