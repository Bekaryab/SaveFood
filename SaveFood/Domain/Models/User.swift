
import Foundation

struct User: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let fullName: String
    let email: String
    let role: UserRole
    let createdAt: Date

    var uid: String { id }

    init(
        id: String,
        fullName: String,
        email: String,
        role: UserRole,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.role = role
        self.createdAt = createdAt
    }
}
