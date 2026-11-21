
import Foundation
import FirebaseFirestore

struct ReservationDTO {
    let id: String
    let customerUid: String
    let sellerUid: String
    let venueId: String
    let venueName: String
    let offerId: String
    let offerTitle: String
    let offerPhotoUrl: String
    let quantity: Int
    let unitPrice: Double
    let totalPrice: Double
    let pickupCode: String
    let status: String
    let pickupUntil: Timestamp
    let createdAt: Timestamp

    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let customerUid = data["customerUid"] as? String,
              let sellerUid = data["sellerUid"] as? String,
              let offerId = data["offerId"] as? String,
              let pickupCode = data["pickupCode"] as? String else {
            return nil
        }

        self.id = document.documentID
        self.customerUid = customerUid
        self.sellerUid = sellerUid
        self.venueId = (data["venueId"] as? String) ?? ""
        self.venueName = (data["venueName"] as? String) ?? "Заведение SaveFood"
        self.offerId = offerId
        self.offerTitle = (data["offerTitle"] as? String) ?? "Заказ SaveFood"
        self.offerPhotoUrl = (data["offerPhotoUrl"] as? String) ?? ""
        self.quantity = (data["quantity"] as? Int) ?? (data["quantity"] as? NSNumber)?.intValue ?? 1
        self.unitPrice = (data["unitPrice"] as? Double) ?? (data["unitPrice"] as? NSNumber)?.doubleValue ?? 0
        self.totalPrice = (data["totalPrice"] as? Double) ?? (data["totalPrice"] as? NSNumber)?.doubleValue ?? 0
        self.pickupCode = pickupCode
        self.status = (data["status"] as? String) ?? ReservationStatus.active.rawValue
        self.pickupUntil = (data["pickupUntil"] as? Timestamp) ?? Timestamp(date: Date())
        self.createdAt = (data["createdAt"] as? Timestamp) ?? Timestamp(date: Date())
    }

    init(from domain: Reservation) {
        self.id = domain.id
        self.customerUid = domain.customerUid
        self.sellerUid = domain.sellerUid
        self.venueId = domain.venueId
        self.venueName = domain.venueName
        self.offerId = domain.offerId
        self.offerTitle = domain.offerTitle
        self.offerPhotoUrl = domain.offerPhotoUrl
        self.quantity = domain.quantity
        self.unitPrice = domain.unitPrice
        self.totalPrice = domain.totalPrice
        self.pickupCode = domain.pickupCode
        self.status = domain.status.rawValue
        self.pickupUntil = Timestamp(date: domain.pickupUntil)
        self.createdAt = Timestamp(date: domain.createdAt)
    }

    func toFirestoreCreateData() -> [String: Any] {
        [
            "customerUid": customerUid,
            "sellerUid": sellerUid,
            "venueId": venueId,
            "venueName": venueName,
            "offerId": offerId,
            "offerTitle": offerTitle,
            "offerPhotoUrl": offerPhotoUrl,
            "quantity": quantity,
            "unitPrice": unitPrice,
            "totalPrice": totalPrice,
            "pickupCode": pickupCode,
            "status": status,
            "pickupUntil": pickupUntil,
            "createdAt": FieldValue.serverTimestamp()
        ]
    }

    func toDomain() -> Reservation {
        Reservation(
            id: id,
            customerUid: customerUid,
            sellerUid: sellerUid,
            venueId: venueId,
            venueName: venueName,
            offerId: offerId,
            offerTitle: offerTitle,
            offerPhotoUrl: offerPhotoUrl,
            quantity: quantity,
            unitPrice: unitPrice,
            totalPrice: totalPrice,
            pickupCode: pickupCode,
            status: ReservationStatus(rawValue: status) ?? .active,
            pickupUntil: pickupUntil.dateValue(),
            createdAt: createdAt.dateValue()
        )
    }
}
