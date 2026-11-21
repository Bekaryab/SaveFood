
import Foundation
import FirebaseFirestore

enum ReservationRepositoryError: LocalizedError {
    case invalidQuantity
    case offerNotAvailable
    case insufficientStock(available: Int)
    case reservationNotFound
    case invalidPickupCode
    case unauthorizedAction
    case alreadyProcessed

    var errorDescription: String? {
        switch self {
        case .invalidQuantity:
            return "Количество для бронирования должно быть больше 0."
        case .offerNotAvailable:
            return "Это предложение больше недоступно для бронирования."
        case .insufficientStock(let available):
            return "Недостаточно товара в наличии (доступно: \(available) шт)."
        case .reservationNotFound:
            return "Бронирование не найдено."
        case .invalidPickupCode:
            return "Неверный код получения заказа."
        case .unauthorizedAction:
            return "У вас нет прав для выполнения этого действия."
        case .alreadyProcessed:
            return "Это бронирование уже завершено или отменено."
        }
    }
}

final class RemoteReservationRepository: ReservationRepository, @unchecked Sendable {

    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func createReservation(
        customerUid: String,
        offer: FoodOffer,
        quantity: Int
    ) async throws -> Reservation {
        guard quantity > 0 else {
            throw ReservationRepositoryError.invalidQuantity
        }

        let offerRef = db.collection("offers").document(offer.id)
        let reservationRef = db.collection("reservations").document()
        let pickupCode = Self.generatePickupCode()
        let unitPrice = offer.newPrice
        let totalPrice = PriceCalculator.totalPrice(unitPrice: unitPrice, quantity: quantity)

        let reservation = Reservation(
            id: reservationRef.documentID,
            customerUid: customerUid,
            sellerUid: offer.sellerUid,
            venueId: offer.venueId,
            venueName: offer.venueName,
            offerId: offer.id,
            offerTitle: offer.title,
            offerPhotoUrl: offer.photoUrl,
            quantity: quantity,
            unitPrice: unitPrice,
            totalPrice: totalPrice,
            pickupCode: pickupCode,
            status: .active,
            pickupUntil: offer.pickupUntil,
            createdAt: Date()
        )
        let reservationData = ReservationDTO(from: reservation).toFirestoreCreateData()

        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            let offerSnapshot: DocumentSnapshot
            do {
                offerSnapshot = try transaction.getDocument(offerRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard let data = offerSnapshot.data(),
                  let isAvailable = data["isAvailable"] as? Bool,
                  isAvailable else {
                errorPointer?.pointee = Self.nsError(from: ReservationRepositoryError.offerNotAvailable)
                return nil
            }

            let currentQuantity = (data["quantity"] as? Int)
                ?? (data["quantity"] as? NSNumber)?.intValue
                ?? 0

            guard currentQuantity >= quantity else {
                errorPointer?.pointee = Self.nsError(
                    from: ReservationRepositoryError.insufficientStock(available: currentQuantity)
                )
                return nil
            }

            let remainingQuantity = currentQuantity - quantity
            let updatedAvailability = remainingQuantity > 0

            transaction.updateData(
                [
                    "quantity": remainingQuantity,
                    "isAvailable": updatedAvailability
                ],
                forDocument: offerRef
            )
            transaction.setData(reservationData, forDocument: reservationRef)
            return reservationRef.documentID
        }

        return reservation
    }

    func fetchCustomerReservations(customerUid: String) async throws -> [Reservation] {
        let snapshot = try await db.collection("reservations")
            .whereField("customerUid", isEqualTo: customerUid)
            .getDocuments()

        return snapshot.documents
            .compactMap { ReservationDTO(document: $0)?.toDomain() }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func fetchSellerReservations(sellerUid: String) async throws -> [Reservation] {
        let snapshot = try await db.collection("reservations")
            .whereField("sellerUid", isEqualTo: sellerUid)
            .getDocuments()

        return snapshot.documents
            .compactMap { ReservationDTO(document: $0)?.toDomain() }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func confirmPickup(
        reservationId: String,
        pickupCode: String,
        sellerUid: String
    ) async throws -> Reservation {
        let normalizedCode = try Validators.validatePickupCode(pickupCode)
        let docRef = db.collection("reservations").document(reservationId)
        let snapshot = try await docRef.getDocument()

        guard let dto = ReservationDTO(document: snapshot) else {
            throw ReservationRepositoryError.reservationNotFound
        }
        let current = dto.toDomain()

        guard current.sellerUid == sellerUid else {
            throw ReservationRepositoryError.unauthorizedAction
        }
        guard current.status == .active else {
            throw ReservationRepositoryError.alreadyProcessed
        }
        guard current.pickupCode.uppercased() == normalizedCode else {
            throw ReservationRepositoryError.invalidPickupCode
        }

        try await docRef.updateData([
            "status": ReservationStatus.completed.rawValue
        ])

        return Reservation(
            id: current.id,
            customerUid: current.customerUid,
            sellerUid: current.sellerUid,
            venueId: current.venueId,
            venueName: current.venueName,
            offerId: current.offerId,
            offerTitle: current.offerTitle,
            offerPhotoUrl: current.offerPhotoUrl,
            quantity: current.quantity,
            unitPrice: current.unitPrice,
            totalPrice: current.totalPrice,
            pickupCode: current.pickupCode,
            status: .completed,
            pickupUntil: current.pickupUntil,
            createdAt: current.createdAt
        )
    }

    func cancelReservation(reservationId: String, actorUid: String) async throws -> Reservation {
        let reservationRef = db.collection("reservations").document(reservationId)

        let updated = try await db.runTransaction { transaction, errorPointer -> Any? in
            let resSnapshot: DocumentSnapshot
            do {
                resSnapshot = try transaction.getDocument(reservationRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard let dto = ReservationDTO(document: resSnapshot) else {
                errorPointer?.pointee = Self.nsError(from: ReservationRepositoryError.reservationNotFound)
                return nil
            }
            let current = dto.toDomain()

            guard current.customerUid == actorUid || current.sellerUid == actorUid else {
                errorPointer?.pointee = Self.nsError(from: ReservationRepositoryError.unauthorizedAction)
                return nil
            }
            guard current.status == .active else {
                errorPointer?.pointee = Self.nsError(from: ReservationRepositoryError.alreadyProcessed)
                return nil
            }

            let offerRef = self.db.collection("offers").document(current.offerId)
            if let offerSnapshot = try? transaction.getDocument(offerRef),
               let offerData = offerSnapshot.data() {
                let currentQty = (offerData["quantity"] as? Int)
                    ?? (offerData["quantity"] as? NSNumber)?.intValue
                    ?? 0
                let restoredQty = currentQty + current.quantity
                transaction.updateData(
                    [
                        "quantity": restoredQty,
                        "isAvailable": restoredQty > 0
                    ],
                    forDocument: offerRef
                )
            }

            transaction.updateData(
                ["status": ReservationStatus.cancelled.rawValue],
                forDocument: reservationRef
            )

            return Reservation(
                id: current.id,
                customerUid: current.customerUid,
                sellerUid: current.sellerUid,
                venueId: current.venueId,
                venueName: current.venueName,
                offerId: current.offerId,
                offerTitle: current.offerTitle,
                offerPhotoUrl: current.offerPhotoUrl,
                quantity: current.quantity,
                unitPrice: current.unitPrice,
                totalPrice: current.totalPrice,
                pickupCode: current.pickupCode,
                status: .cancelled,
                pickupUntil: current.pickupUntil,
                createdAt: current.createdAt
            )
        }

        guard let cancelledReservation = updated as? Reservation else {
            throw ReservationRepositoryError.reservationNotFound
        }
        return cancelledReservation
    }

    private static func generatePickupCode() -> String {
        let digits = Int.random(in: 1000...9999)
        return "SF-\(digits)"
    }

    private static func nsError(from error: ReservationRepositoryError) -> NSError {
        NSError(
            domain: "SaveFood.ReservationRepository",
            code: 400,
            userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]
        )
    }
}
