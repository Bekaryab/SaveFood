
import Foundation

struct Venue: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let ownerUid: String
    let name: String
    let address: String
    let photoUrl: String
    let createdAt: Date

    init(
        id: String,
        ownerUid: String,
        name: String,
        address: String,
        photoUrl: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.ownerUid = ownerUid
        self.name = name
        self.address = address
        self.photoUrl = photoUrl
        self.createdAt = createdAt
    }
}
