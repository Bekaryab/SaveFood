import Foundation
import FirebaseFirestore

enum OfferRepositoryError: LocalizedError {
    case offerNotFound
    case invalidOfferData
    case unauthorizedSeller

    var errorDescription: String? {
        switch self {
        case .offerNotFound:
            return "Предложение не найдено или было удалено."
        case .invalidOfferData:
            return "Некорректные данные предложения в базе данных."
        case .unauthorizedSeller:
            return "Нельзя редактировать чужое предложение."
        }
    }
}

final class RemoteOfferRepository: OfferRepository, @unchecked Sendable {

    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func fetchActiveOffers() async throws -> [FoodOffer] {
        let snapshot = try await db.collection("offers")
            .whereField("isAvailable", isEqualTo: true)
            .getDocuments()

        let venuesMap = await fetchVenuesNameMap(for: snapshot.documents)
        let startOfToday = Calendar.current.startOfDay(for: Date())

        return snapshot.documents
            .compactMap { doc -> FoodOffer? in
                let venueId = doc.data()["venueId"] as? String ?? ""
                return OfferDTO(document: doc, fallbackVenueName: venuesMap[venueId])?.toDomain()
            }
            .filter { $0.isAvailable && $0.quantity > 0 && $0.expiresAt >= startOfToday }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Сатушы тауарды салған сәтте сатып алушының экранына бірден жеткізетін Real-Time тыңдаушы
    func observeActiveOffers() -> AsyncThrowingStream<[FoodOffer], Error> {
        AsyncThrowingStream { continuation in
            let listener = db.collection("offers")
                .whereField("isAvailable", isEqualTo: true)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    guard let documents = snapshot?.documents else {
                        continuation.yield([])
                        return
                    }

                    let startOfToday = Calendar.current.startOfDay(for: Date())
                    let offers = documents
                        .compactMap { OfferDTO(document: $0)?.toDomain() }
                        .filter { $0.isAvailable && $0.quantity > 0 && $0.expiresAt >= startOfToday }
                        .sorted { $0.createdAt > $1.createdAt }

                    continuation.yield(offers)
                }

            nonisolated(unsafe) let activeListener = listener
            continuation.onTermination = { _ in
                activeListener.remove()
            }
        }
    }

    func fetchOffers(forSellerUid sellerUid: String) async throws -> [FoodOffer] {
        let snapshot = try await db.collection("offers")
            .whereField("sellerUid", isEqualTo: sellerUid)
            .getDocuments()

        let venuesMap = await fetchVenuesNameMap(for: snapshot.documents)

        return snapshot.documents
            .compactMap { doc -> FoodOffer? in
                let venueId = doc.data()["venueId"] as? String ?? ""
                return OfferDTO(document: doc, fallbackVenueName: venuesMap[venueId])?.toDomain()
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func fetchOffer(byId offerId: String) async throws -> FoodOffer {
        let snapshot = try await db.collection("offers").document(offerId).getDocument()
        guard snapshot.exists else {
            throw OfferRepositoryError.offerNotFound
        }
        guard let dto = OfferDTO(document: snapshot) else {
            throw OfferRepositoryError.invalidOfferData
        }
        return dto.toDomain()
    }

    func createOffer(_ input: CreateOfferInput) async throws -> FoodOffer {
        try Validators.validateOffer(
            title: input.title,
            category: input.category,
            oldPrice: input.oldPrice,
            newPrice: input.newPrice,
            quantity: input.quantity,
            photoUrl: input.photoUrl,
            producedAt: input.producedAt,
            expiresAt: input.expiresAt,
            pickupUntil: input.pickupUntil,
            requirePositiveQuantity: true
        )

        let docRef = db.collection("offers").document()
        let dto = OfferDTO(from: input, id: docRef.documentID)
        try await docRef.setData(dto.toFirestoreCreateData())
        return dto.toDomain()
    }

    func updateOffer(_ offer: FoodOffer) async throws -> FoodOffer {
        try Validators.validateOffer(
            title: offer.title,
            category: offer.category,
            oldPrice: offer.oldPrice,
            newPrice: offer.newPrice,
            quantity: offer.quantity,
            photoUrl: offer.photoUrl,
            producedAt: offer.producedAt,
            expiresAt: offer.expiresAt,
            pickupUntil: nil,
            requirePositiveQuantity: false
        )

        let resolvedAvailability = offer.quantity > 0 ? offer.isAvailable : false
        let normalizedOffer = FoodOffer(
            id: offer.id,
            sellerUid: offer.sellerUid,
            venueId: offer.venueId,
            venueName: offer.venueName,
            title: offer.title.trimmingCharacters(in: .whitespacesAndNewlines),
            category: offer.category.trimmingCharacters(in: .whitespacesAndNewlines),
            oldPrice: offer.oldPrice,
            newPrice: offer.newPrice,
            quantity: max(0, offer.quantity),
            photoUrl: offer.photoUrl.trimmingCharacters(in: .whitespacesAndNewlines),
            isAvailable: resolvedAvailability,
            description: offer.description.trimmingCharacters(in: .whitespacesAndNewlines),
            reason: offer.reason.trimmingCharacters(in: .whitespacesAndNewlines),
            producedAt: offer.producedAt,
            expiresAt: offer.expiresAt,
            pickupUntil: offer.pickupUntil,
            createdAt: offer.createdAt
        )

        let dto = OfferDTO(from: normalizedOffer)
        try await db.collection("offers")
            .document(offer.id)
            .updateData(dto.toFirestoreUpdateData())

        return normalizedOffer
    }

    func updateOfferQuantity(offerId: String, quantity: Int) async throws -> FoodOffer {
        let safeQuantity = max(0, quantity)
        var updates: [String: Any] = ["quantity": safeQuantity]
        if safeQuantity == 0 {
            updates["isAvailable"] = false
        }

        try await db.collection("offers")
            .document(offerId)
            .updateData(updates)

        return try await fetchOffer(byId: offerId)
    }

    func updateOfferAvailability(offerId: String, isAvailable: Bool) async throws -> FoodOffer {
        let current = try await fetchOffer(byId: offerId)
        let resolvedAvailability = current.quantity > 0 ? isAvailable : false

        try await db.collection("offers")
            .document(offerId)
            .updateData(["isAvailable": resolvedAvailability])

        return try await fetchOffer(byId: offerId)
    }

    func deleteOffer(offerId: String) async throws {
        try await db.collection("offers")
            .document(offerId)
            .delete()
    }

    private func fetchVenuesNameMap(for offerDocuments: [QueryDocumentSnapshot]) async -> [String: String] {
        let missingNameVenueIds = Set(
            offerDocuments.compactMap { doc -> String? in
                let data = doc.data()
                if let name = data["venueName"] as? String, !name.isEmpty {
                    return nil
                }
                return data["venueId"] as? String
            }
        )
        guard !missingNameVenueIds.isEmpty else { return [:] }

        var result: [String: String] = [:]
        for venueId in missingNameVenueIds {
            if let venueDoc = try? await db.collection("venues").document(venueId).getDocument(),
               let name = venueDoc.data()?["name"] as? String {
                result[venueId] = name
            }
        }
        return result
    }
}
