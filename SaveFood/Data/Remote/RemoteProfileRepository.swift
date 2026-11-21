import Foundation
import FirebaseFirestore

enum ProfileRepositoryError: LocalizedError {
    case userNotFound
    case venueNotFound
    case unauthorizedVenueAccess

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "Профиль пользователя не найден."
        case .venueNotFound:
            return "Заведение не найдено."
        case .unauthorizedVenueAccess:
            return "У вас нет прав на изменение этого заведения."
        }
    }
}

final class RemoteProfileRepository: ProfileRepository, @unchecked Sendable {

    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func fetchUserProfile(uid: String) async throws -> User {
        let snapshot = try await db.collection("users").document(uid).getDocument()
        guard let dto = AuthDTO(document: snapshot) else {
            throw ProfileRepositoryError.userNotFound
        }
        return dto.toDomain()
    }

    func updateUserFullName(uid: String, fullName: String) async throws -> User {
        let current = try await fetchUserProfile(uid: uid)
        let validName = try Validators.validateFullName(fullName, role: current.role)

        try await db.collection("users")
            .document(uid)
            .updateData(["fullName": validName])

        return User(
            id: current.id,
            fullName: validName,
            email: current.email,
            role: current.role,
            createdAt: current.createdAt
        )
    }

    func fetchVenues(forOwnerUid ownerUid: String) async throws -> [Venue] {
        let snapshot = try await db.collection("venues")
            .whereField("ownerUid", isEqualTo: ownerUid)
            .getDocuments()

        return snapshot.documents
            .compactMap { VenueDTO(document: $0)?.toDomain() }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func fetchVenue(byId venueId: String) async throws -> Venue? {
        let snapshot = try await db.collection("venues").document(venueId).getDocument()
        return VenueDTO(document: snapshot)?.toDomain()
    }

    func saveVenue(
        venueId: String?,
        ownerUid: String,
        name: String,
        address: String,
        photoUrl: String
    ) async throws -> Venue {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhoto = photoUrl.trimmingCharacters(in: .whitespacesAndNewlines)

        try Validators.validateVenue(
            name: trimmedName,
            address: trimmedAddress,
            photoUrl: trimmedPhoto
        )

        if let venueId, !venueId.isEmpty {
            let docRef = db.collection("venues").document(venueId)
            let existingSnapshot = try await docRef.getDocument()
            guard let existing = VenueDTO(document: existingSnapshot) else {
                throw ProfileRepositoryError.venueNotFound
            }
            guard existing.ownerUid == ownerUid else {
                throw ProfileRepositoryError.unauthorizedVenueAccess
            }

            let updatedDTO = VenueDTO(
                id: venueId,
                ownerUid: ownerUid,
                name: trimmedName,
                address: trimmedAddress,
                photoUrl: trimmedPhoto,
                createdAt: existing.createdAt
            )
            try await docRef.updateData(updatedDTO.toFirestoreUpdateData())
            return updatedDTO.toDomain()
        } else {
            let newDocRef = db.collection("venues").document()
            let dto = VenueDTO(
                id: newDocRef.documentID,
                ownerUid: ownerUid,
                name: trimmedName,
                address: trimmedAddress,
                photoUrl: trimmedPhoto
            )
            try await newDocRef.setData(dto.toFirestoreCreateData())
            return dto.toDomain()
        }
    }

    func deleteVenue(venueId: String, ownerUid: String) async throws {
        let docRef = db.collection("venues").document(venueId)
        let snapshot = try await docRef.getDocument()
        guard let existing = VenueDTO(document: snapshot) else {
            throw ProfileRepositoryError.venueNotFound
        }
        guard existing.ownerUid == ownerUid else {
            throw ProfileRepositoryError.unauthorizedVenueAccess
        }
        try await docRef.delete()
    }
}
