import Foundation

public protocol AuthDelegate {
    /**
        Called when a user is logged in
    */
    func onLogin()
    
    /**
        Called when a user is logged out
 
        - parameter lastProvider: The last provider this user
            logged in with
    */
    func onLogout()
}
