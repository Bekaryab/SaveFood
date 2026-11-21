
import Foundation
import FirebaseFirestore

struct OfferDTO {
    let id: String
    let sellerUid: String
    let venueId: String
    let venueName: String
    let title: String
    let category: String
    let oldPrice: Double
    let newPrice: Double
    let quantity: Int
    let photoUrl: String
    let isAvailable: Bool
    let description: String
    let reason: String
    let producedAt: Timestamp
    let expiresAt: Timestamp
    let pickupUntil: Timestamp
    let createdAt: Timestamp

    init?(document: DocumentSnapshot, fallbackVenueName: String? = nil) {
        guard let data = document.data(),
              let sellerUid = data["sellerUid"] as? String,
              let venueId = data["venueId"] as? String,
              let title = data["title"] as? String,
              let category = data["category"] as? String else {
            return nil
        }

        let oldPrice = Self.parseDouble(data["oldPrice"])
        let newPrice = Self.parseDouble(data["newPrice"])
        let quantity = Self.parseInt(data["quantity"])
        guard oldPrice > 0, newPrice > 0 else { return nil }

        let now = Date()
        let createdAt = (data["createdAt"] as? Timestamp) ?? Timestamp(date: now)
        let producedAt = (data["producedAt"] as? Timestamp) ?? createdAt
        let defaultExpiry = Calendar.current.date(byAdding: .day, value: 1, to: producedAt.dateValue()) ?? now
        let expiresAt = (data["expiresAt"] as? Timestamp) ?? Timestamp(date: defaultExpiry)
        let pickupUntil = (data["pickupUntil"] as? Timestamp) ?? expiresAt

        let rawIsAvailable = (data["isAvailable"] as? Bool) ?? (quantity > 0)
        let resolvedAvailability = quantity > 0 ? rawIsAvailable : false

        self.id = document.documentID
        self.sellerUid = sellerUid
        self.venueId = venueId
        self.venueName = (data["venueName"] as? String) ?? fallbackVenueName ?? "Заведение SaveFood"
        self.title = title
        self.category = category
        self.oldPrice = oldPrice
        self.newPrice = newPrice
        self.quantity = max(0, quantity)
        self.photoUrl = (data["photoUrl"] as? String) ?? ""
        self.isAvailable = resolvedAvailability
        self.description = (data["description"] as? String) ?? ""
        self.reason = (data["reason"] as? String) ?? "Излишки"
        self.producedAt = producedAt
        self.expiresAt = expiresAt
        self.pickupUntil = pickupUntil
        self.createdAt = createdAt
    }

    init(from input: CreateOfferInput, id: String) {
        self.id = id
        self.sellerUid = input.sellerUid
        self.venueId = input.venueId
        self.venueName = input.venueName
        self.title = input.title
        self.category = input.category
        self.oldPrice = input.oldPrice
        self.newPrice = input.newPrice
        self.quantity = max(0, input.quantity)
        self.photoUrl = input.photoUrl
        self.isAvailable = input.quantity > 0
        self.description = input.description
        self.reason = input.reason
        self.producedAt = Timestamp(date: input.producedAt)
        self.expiresAt = Timestamp(date: input.expiresAt)
        self.pickupUntil = Timestamp(date: input.pickupUntil)
        self.createdAt = Timestamp(date: Date())
    }

    init(from domain: FoodOffer) {
        self.id = domain.id
        self.sellerUid = domain.sellerUid
        self.venueId = domain.venueId
        self.venueName = domain.venueName
        self.title = domain.title
        self.category = domain.category
        self.oldPrice = domain.oldPrice
        self.newPrice = domain.newPrice
        self.quantity = max(0, domain.quantity)
        self.photoUrl = domain.photoUrl
        self.isAvailable = domain.quantity > 0 ? domain.isAvailable : false
        self.description = domain.description
        self.reason = domain.reason
        self.producedAt = Timestamp(date: domain.producedAt)
        self.expiresAt = Timestamp(date: domain.expiresAt)
        self.pickupUntil = Timestamp(date: domain.pickupUntil)
        self.createdAt = Timestamp(date: domain.createdAt)
    }

    func toFirestoreCreateData() -> [String: Any] {
        [
            "sellerUid": sellerUid,
            "venueId": venueId,
            "venueName": venueName,
            "title": title,
            "category": category,
            "oldPrice": oldPrice,
            "newPrice": newPrice,
            "quantity": quantity,
            "photoUrl": photoUrl,
            "isAvailable": quantity > 0 ? isAvailable : false,
            "description": description,
            "reason": reason,
            "producedAt": producedAt,
            "expiresAt": expiresAt,
            "pickupUntil": pickupUntil,
            "createdAt": FieldValue.serverTimestamp()
        ]
    }

    func toFirestoreUpdateData() -> [String: Any] {
        [
            "venueId": venueId,
            "venueName": venueName,
            "title": title,
            "category": category,
            "oldPrice": oldPrice,
            "newPrice": newPrice,
            "quantity": quantity,
            "photoUrl": photoUrl,
            "isAvailable": quantity > 0 ? isAvailable : false,
            "description": description,
            "reason": reason,
            "producedAt": producedAt,
            "expiresAt": expiresAt,
            "pickupUntil": pickupUntil
        ]
    }

    func toDomain() -> FoodOffer {
        FoodOffer(
            id: id,
            sellerUid: sellerUid,
            venueId: venueId,
            venueName: venueName,
            title: title,
            category: category,
            oldPrice: oldPrice,
            newPrice: newPrice,
            quantity: quantity,
            photoUrl: photoUrl,
            isAvailable: quantity > 0 ? isAvailable : false,
            description: description,
            reason: reason,
            producedAt: producedAt.dateValue(),
            expiresAt: expiresAt.dateValue(),
            pickupUntil: pickupUntil.dateValue(),
            createdAt: createdAt.dateValue()
        )
    }

    private static func parseDouble(_ raw: Any?) -> Double {
        if let value = raw as? Double { return value }
        if let value = raw as? Int { return Double(value) }
        if let value = raw as? NSNumber { return value.doubleValue }
        return 0
    }

    private static func parseInt(_ raw: Any?) -> Int {
        if let value = raw as? Int { return value }
        if let value = raw as? Int64 { return Int(value) }
        if let value = raw as? Double { return Int(value) }
        if let value = raw as? NSNumber { return value.intValue }
        return 0
    }
}
