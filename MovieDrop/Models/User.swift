import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let displayName: String
    let createdAt: String
    let avatar: String?
    let bio: String
    let preferences: UserPreferences
    
    struct UserPreferences: Codable {
        let favoriteGenres: [String]
        let notifications: Bool
        let privacy: String // 'public', 'friends', 'private'
    }
}

struct AuthResponse: Codable {
    let message: String
    let user: User
    let token: String
}

struct UserResponse: Codable {
    let user: User
}

struct AuthError: Codable {
    let error: String
}
