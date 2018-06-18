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
    
    var stitchClient: StitchAppClient!
    static var provider: StitchProviderType?
    
    var delegate: AuthenticationViewControllerDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.stitchClient = Stitch.defaultAppClient!
        
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
        
        handleAuthenticationProviders()
    }
    
    //MARK: - Helpers
    
    func handleAuthenticationProviders() {
        
        DispatchQueue.main.async { [weak self] in
            
            guard let strongSelf = self else { return }
            
            // Google authentication
            GIDSignIn.sharedInstance().clientID = "<iOS-application-client-id>"
            GIDSignIn.sharedInstance().serverClientID = "<Web-application-client-id>"
            GIDSignIn.sharedInstance().uiDelegate = self
            GIDSignIn.sharedInstance().delegate = self

            strongSelf.googleSignInButton.isHidden = false
            strongSelf.authOptionsStackView.addArrangedSubview(strongSelf.googleSignInButton)
            
            // Facebook authentication
            let fbAppId = Bundle.main.object(forInfoDictionaryKey: "FacebookAppID") as? String
            if fbAppId != nil && fbAppId != "<Your-FacebookAppID>" {
                if let token = AccessToken.current {
                    strongSelf.loginWithFacebook(token: token)
                    return
                }
                
                let readPermissions: [FacebookCore.ReadPermission] = []
                
                let loginButton = LoginButton(readPermissions: readPermissions)
                loginButton.delegate = self
                loginButton.center = CGPoint(x: strongSelf.fbLoginButtonContainer.bounds.midX, y: strongSelf.fbLoginButtonContainer.bounds.midY)
                strongSelf.fbLoginButtonContainer.addSubview(loginButton)
                strongSelf.authOptionsStackView.addArrangedSubview(strongSelf.fbLoginButtonContainer)
            }
            else {
                strongSelf.fbLoginButtonContainer.removeFromSuperview()
            }
            
            // Email/password authentication
            strongSelf.emailPasswordContainer.isHidden = false
            strongSelf.authOptionsStackView.addArrangedSubview(strongSelf.emailPasswordContainer)
            
            // Anonymous authentication
            strongSelf.skipButton.isHidden = false
            strongSelf.authOptionsStackView.addArrangedSubview(strongSelf.skipButton)
            
            strongSelf.show(show: true, errorMessage: "")
        }        
    }
    
    // MARK: - Actions
    @IBAction private func googleSignInPressed(_ sender: GIDSignInButton) {
        show(show: false, errorMessage: nil)
    }
    
    @IBAction private func skipButtonPressed(_ sender: Any) {
        
        stitchClient.auth.login(withCredential: AnonymousCredential.init()) { result in
            switch result {
            case .success(_):
                AuthenticationViewController.provider = StitchProviderType.anonymous
                self.delegate?.authenticationViewControllerDidLogin()
            case .failure(let error):
                print("failed logging in Stitch with Anonymous Authentication. error: \(error)")
                self.show(show: true, errorMessage: error.localizedDescription)
            }
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
            let credential = GoogleCredential.init(withAuthCode: user.serverAuthCode)
            stitchClient.auth.login(withCredential: credential) { result in
                switch result {
                case .success(_):
                    AuthenticationViewController.provider = StitchProviderType.google
                    self.delegate?.authenticationViewControllerDidLogin()
                case .failure(let error):
                    print("failed logging in Stitch with Google. error: \(error)")
                    GIDSignIn.sharedInstance().signOut()
                    self.show(show: true, errorMessage: error.localizedDescription)
                }
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
            loginWithFacebook(token: token)
        case .failed(let error):
            print("error received when logging in with Facebook: \(error.localizedDescription)")
            self.show(show: true, errorMessage: error.localizedDescription)
        default:
            break
        }
    }
    
    func loginWithFacebook(token: AccessToken) {
        let credential = FacebookCredential.init(withAccessToken: token.authenticationToken)
        stitchClient.auth.login(withCredential: credential) {result in
            AuthenticationViewController.provider = StitchProviderType.facebook
            switch result {
            case .success(_):
                self.delegate?.authenticationViewControllerDidLogin()
            case .failure(let error):
                print("failed logging in Stitch with Facebook. error: \(error)")
                LoginManager().logOut()
                self.show(show: true, errorMessage: error.localizedDescription)
            }
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
