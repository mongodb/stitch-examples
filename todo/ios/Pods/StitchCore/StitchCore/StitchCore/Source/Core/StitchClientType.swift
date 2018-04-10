import Foundation
import ExtendedJson
import PromiseKit

public typealias UserId = String

/// Protocol to lay out basic methods and fields for a StitchClient.
public protocol StitchClientType {
    // MARK: - Properties
    /// Id of this application
    var appId: String { get }
    /// The currently authenticated user (if authenticated).
    var auth: Auth? { get }
    /// Whether or not this client is authenticated.
    var isAuthenticated: Bool { get }

    /**
        Registers the current user using email and password.
     
        - parameter email: email for the given user
        - parameter password: password for the given user
        - returns: A task containing whether or not registration was successful.
     */
    @discardableResult
    func register(email: String, password: String) -> Promise<Void>

    /**
     * Confirm a newly registered email in this context
     * - parameter token: confirmation token emailed to new user
     * - parameter tokenId: confirmation tokenId emailed to new user
     * - returns: A task containing whether or not the email was confirmed successfully
     */
    @discardableResult
    func emailConfirm(token: String, tokenId: String) -> Promise<Void>

    /**
     * Send a confirmation email for a newly registered user
     * - parameter email: email address of user
     * - returns: A task containing whether or not the email was sent successfully.
     */
    @discardableResult
    func sendEmailConfirm(toEmail email: String) -> Promise<Void>

    /**
     * Reset a given user's password
     * - parameter token: token associated with this user
     * - parameter tokenId: id of the token associated with this user
     * - returns: A task containing whether or not the reset was successful
     */
    @discardableResult
    func resetPassword(token: String, tokenId: String, password: String) -> Promise<Void>

    /**
     * Send a reset password email to a given email address
     * - parameter email: email address to reset password for
     * - returns: A task containing whether or not the reset email was sent successfully
     */
    @discardableResult
    func sendResetPassword(toEmail email: String) -> Promise<Void>

    /**
     Logs the current user in anonymously.
     
     - Returns: A task containing whether or not the login as successful
     */
    @discardableResult
    func anonymousAuth() -> Promise<UserId>

    /**
        Logs the current user in using a specific auth provider.
     
        - Parameters:
            - withProvider: The provider that will handle the login.
        - Returns: A task containing whether or not the login as successful
     */
    @discardableResult
    func login(withProvider provider: AuthProvider) -> Promise<UserId>

    /**
     * Logs out the current user.
     *
     * - returns: A task that can be resolved upon completion of logout.
     */
    @discardableResult
    func logout() -> Promise<Void>

    // MARK: - Requests

    /**
        Adds a delegate for auth events.
     
        - parameter delegate: The delegate that will receive auth events.
     */
    func addAuthDelegate(delegate: AuthDelegate)
}
