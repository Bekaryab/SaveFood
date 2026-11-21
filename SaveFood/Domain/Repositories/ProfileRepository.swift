
import Foundation

protocol ProfileRepository: Sendable {
    func fetchUserProfile(uid: String) async throws -> User

    func updateUserFullName(uid: String, fullName: String) async throws -> User

    func fetchVenues(forOwnerUid ownerUid: String) async throws -> [Venue]

    func fetchVenue(byId venueId: String) async throws -> Venue?

    func saveVenue(
        venueId: String?,
        ownerUid: String,
        name: String,
        address: String,
        photoUrl: String
    ) async throws -> Venue

    func deleteVenue(venueId: String, ownerUid: String) async throws
}
