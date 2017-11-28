import Foundation

/**
     An AuthListener provides an observer interface for users to listen in on auth
     events from a StitchClient.
 */
public protocol AuthDelegate: class {
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
