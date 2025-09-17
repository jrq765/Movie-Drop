import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let displayName: String
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
