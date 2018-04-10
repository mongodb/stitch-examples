import Foundation

// MARK: - Identity
/**
 Identity is an alias by which this user can be authenticated in as.
 */
public struct Identity: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, providerId = "provider_id", providerType = "provider_type"
    }

    /// The provider specific Unique ID.
    let id: String
    /// The provider of this identity.
    let providerId: String
    /// The provider of this identity.
    let providerType: String
}

public struct Role: Codable {
    private enum CodingKeys: String, CodingKey {
        case roleName = "role_name", groupId = "group_id"
    }

    let roleName: String
    let groupId: String
}

/**
    UserProfile represents an authenticated user.
 */
public struct UserProfile: Codable {
    private enum CodingKeys: String, CodingKey {
        case id = "user_id", type, identities, data, roles
    }

    /// The Unique ID of this user within Stitch.
    public let id: String
    /// What type of user this is
    public let type: String
    /// The set of identities that this user is known by.
    public let identities: [Identity]
    /// The extra data associated with this user.
    public let data: [String: String]
    internal let roles: [Role]?
}
