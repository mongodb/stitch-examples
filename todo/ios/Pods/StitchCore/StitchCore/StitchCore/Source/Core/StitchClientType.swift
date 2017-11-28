import Foundation
import ExtendedJson

/// Protocol to lay out basic methods and fields for a StitchClient.
public protocol StitchClientType {
    typealias UserId = String

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
    func register(email: String, password: String) -> StitchTask<Void>

    /**
     * Confirm a newly registered email in this context
     * - parameter token: confirmation token emailed to new user
     * - parameter tokenId: confirmation tokenId emailed to new user
     * - returns: A task containing whether or not the email was confirmed successfully
     */
    @discardableResult
    func emailConfirm(token: String, tokenId: String) -> StitchTask<Void>

    /**
     * Send a confirmation email for a newly registered user
     * - parameter email: email address of user
     * - returns: A task containing whether or not the email was sent successfully.
     */
    @discardableResult
    func sendEmailConfirm(toEmail email: String) -> StitchTask<Void>

    /**
     * Reset a given user's password
     * - parameter token: token associated with this user
     * - parameter tokenId: id of the token associated with this user
     * - returns: A task containing whether or not the reset was successful
     */
    @discardableResult
    func resetPassword(token: String, tokenId: String) -> StitchTask<Void>

    /**
     * Send a reset password email to a given email address
     * - parameter email: email address to reset password for
     * - returns: A task containing whether or not the reset email was sent successfully
     */
    @discardableResult
    func sendResetPassword(toEmail email: String) -> StitchTask<Void>

    /**
     Logs the current user in anonymously.
     
     - Returns: A task containing whether or not the login as successful
     */
    @discardableResult
    func anonymousAuth() -> StitchTask<UserId>

    /**
        Logs the current user in using a specific auth provider.
     
        - Parameters:
            - withProvider: The provider that will handle the login.
        - Returns: A task containing whether or not the login as successful
     */
    @discardableResult
    func login(withProvider provider: AuthProvider) -> StitchTask<UserId>

    /**
     * Logs out the current user.
     *
     * - returns: A task that can be resolved upon completion of logout.
     */
    @discardableResult
    func logout() -> StitchTask<Void>

    // MARK: - Requests

    /**
        Adds a delegate for auth events.
     
        - parameter delegate: The delegate that will receive auth events.
     */
    func addAuthDelegate(delegate: AuthDelegate)
}
