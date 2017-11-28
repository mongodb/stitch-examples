//
//  AuthenticationViewController.swift
//  MongoDBSample
//
//

import UIKit
import FacebookCore
import FacebookLogin
import StitchCore

protocol AuthenticationViewControllerDelegate {
    func authenticationViewControllerDidLogin()
}

class AuthenticationViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate, LoginButtonDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var authOptionsStackView: UIStackView!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var googleSignInButton: GIDSignInButton!
    @IBOutlet private weak var fbLoginButtonContainer: UIView!
    @IBOutlet weak var emailPasswordContainer: UIStackView!
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailSignUpButton: UIButton!
    @IBOutlet weak var emailLoginButton: UIButton!
    
    @IBOutlet weak var errorLable: UILabel!
    
    var stitchClient: StitchClient?
    
    var delegate: AuthenticationViewControllerDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Google
        googleSignInButton.isHidden = true
        authOptionsStackView.removeArrangedSubview(googleSignInButton)
        
        //Facebook
        authOptionsStackView.removeArrangedSubview(fbLoginButtonContainer)
        
        //EmailPassword
        emailPasswordContainer.isHidden = true
        authOptionsStackView.removeArrangedSubview(emailPasswordContainer)
        
        //Anonymous
        skipButton.isHidden = true
        authOptionsStackView.removeArrangedSubview(skipButton)
        
        // fetch auth providers
        stitchClient?.fetchAuthProviders().then { (authProviderInfo: AuthProviderInfo) in
            
            self.handleAuthenticationProviders(authInfo: authProviderInfo)
            
            }.catch { error in
                print("failed to get Authentication Providers. error: \(error)")
                
        }
        
    }
    
    //MARK: - Helpers
    
    func handleAuthenticationProviders(authInfo: AuthProviderInfo) {
        
        DispatchQueue.main.async { [weak self] in
            
            guard let strongSelf = self else { return }
            var authAvailable = false
            
            if let googleAuthInfo = authInfo.googleProviderInfo {
                authAvailable = true
                
                var configureError: NSError?
                GGLContext.sharedInstance().configureWithError(&configureError)
                assert(configureError == nil, "Error configuring Google services: \(configureError)")
                
                GIDSignIn.sharedInstance().uiDelegate = self
                GIDSignIn.sharedInstance().delegate = self
                GIDSignIn.sharedInstance().serverClientID = googleAuthInfo.config.clientId
                
                GIDSignIn.sharedInstance().scopes = googleAuthInfo.metadataFields?.map { $0.name }
                strongSelf.googleSignInButton.isHidden = false
                strongSelf.authOptionsStackView.addArrangedSubview(strongSelf.googleSignInButton)
            }
            else {
                strongSelf.googleSignInButton.removeFromSuperview()
            }
            
            if let facebookAuthInfo = authInfo.facebookProviderInfo {
                authAvailable = true
                var readPermissions: [FacebookCore.ReadPermission] = []
                
                let loginButton = LoginButton(readPermissions: readPermissions)
                loginButton.delegate = self
                loginButton.center = CGPoint(x: strongSelf.fbLoginButtonContainer.bounds.midX, y: strongSelf.fbLoginButtonContainer.bounds.midY)
                strongSelf.fbLoginButtonContainer.addSubview(loginButton)
                strongSelf.authOptionsStackView.addArrangedSubview(strongSelf.fbLoginButtonContainer)
            }
            else {
                strongSelf.fbLoginButtonContainer.removeFromSuperview()
            }
            
            if let _ = authInfo.emailPasswordAuthProviderInfo {
                authAvailable = true
                strongSelf.emailPasswordContainer.isHidden = false
                strongSelf.authOptionsStackView.addArrangedSubview(strongSelf.emailPasswordContainer)
            }
            else {
                strongSelf.skipButton.removeFromSuperview()
            }
            
            if let _ = authInfo.anonymousAuthProviderInfo {
                authAvailable = true
                strongSelf.skipButton.isHidden = false
                strongSelf.authOptionsStackView.addArrangedSubview(strongSelf.skipButton)
            }
            else {
                strongSelf.skipButton.removeFromSuperview()
            }
            
            strongSelf.show(show: !authAvailable, errorMessage: authAvailable ? "" : "No Auth Providers Available.")
        }        
    }
    
    // MARK: - Actions
    
    @IBAction private func googleSignInPressed(_ sender: GIDSignInButton) {
        show(show: false, errorMessage: nil)
    }
    
    @IBAction private func skipButtonPressed(_ sender: Any) {
        
        stitchClient?.anonymousAuth().then { (userId: String) in
            self.delegate?.authenticationViewControllerDidLogin()
            
            }.catch { error in
                print("failed logging in Stitch with Anonymous Authentication. error: \(error)")
                self.show(show: true, errorMessage: error.localizedDescription)
        }
        
    }
    
    @IBAction func emailSignUpButtonPressed(_ sender: Any) {
        view.endEditing(true)
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            return
        }
        
        
    }
    
    @IBAction func emailLoginButtonPressed(_ sender: Any) {
        view.endEditing(true)
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            return
        }
        
        
    }
    
    //MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        }
        
        if textField == passwordTextField {
            passwordTextField.resignFirstResponder()
        }
        
        return true
    }
    
    @IBAction func textFieldDidChange(_ sender: UITextField) {
        var shouldEnableEmailLogin = false
        if let emailText = emailTextField.text,
            let passwordText = passwordTextField.text {
            shouldEnableEmailLogin = !emailText.isEmpty && !passwordText.isEmpty
        }
        
        emailSignUpButton.isEnabled = shouldEnableEmailLogin
        emailLoginButton.isEnabled = shouldEnableEmailLogin
    }
    
    // MARK: - GIDSignInDelegate (Google)
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            guard let stitchClient = stitchClient else {
                show(show: true, errorMessage: "Stitch client not found")
                return
            }
            
            stitchClient.login(withProvider: GoogleAuthProvider(authCode: user.serverAuthCode)).then { (userId: String) in
                MongoDBManager.shared.provider = Provider.google
                self.delegate?.authenticationViewControllerDidLogin()
                }.catch { error in
                    print("failed logging in Stitch with Google. error: \(error)")
                    GIDSignIn.sharedInstance().signOut()
                    self.show(show: true, errorMessage: error.localizedDescription)
            }
            
        } else {
            print("error received when logging in with Google: \(error.localizedDescription)")
            show(show: true, errorMessage: error.localizedDescription)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("Disconnect from Google. error: \(error.localizedDescription)")
    }
    
    // MARK: - LoginButtonDelegate (Facebook)
    
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        switch result {
        case .success(_, _, let token):
            
            guard let stitchClient = stitchClient else {
                show(show: true, errorMessage: "Stitch client not found")
                return
            }
            
            stitchClient.login(withProvider: FacebookAuthProvider(accessToken: token.authenticationToken)).then { (userId: String) in
                MongoDBManager.shared.provider = Provider.facebook
                self.delegate?.authenticationViewControllerDidLogin()
                }.catch { error in
                    print("failed logging in Stitch with Facebook. error: \(error)")
                    LoginManager().logOut()
                    self.show(show: true, errorMessage: error.localizedDescription)
            }
            
            break
        case .failed(let error):
            print("error received when logging in with Facebook: \(error.localizedDescription)")
            self.show(show: true, errorMessage: error.localizedDescription)
            break
        default:
            break
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        print("Disconnect from Facebook.")
    }
    
    // MARK: - Show Error
    
    func show(show:Bool, errorMessage: String?) {
        DispatchQueue.main.async { [weak self] in
            self?.errorLable.text = errorMessage
            self?.errorLable.isHidden = !show
        }
    }
    
}
