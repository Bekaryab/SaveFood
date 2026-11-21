import Foundation

struct Reservation: Identifiable, Codable, Equatable, Sendable {
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
    let status: ReservationStatus
    let pickupUntil: Date
    let createdAt: Date

    var formattedTotalPrice: String {
        PriceCalculator.formatTenge(totalPrice)
    }

    var formattedUnitPrice: String {
        PriceCalculator.formatTenge(unitPrice)
    }
}
