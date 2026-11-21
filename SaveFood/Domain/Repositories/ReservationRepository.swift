
import Foundation

protocol ReservationRepository: Sendable {
    func createReservation(
        customerUid: String,
        offer: FoodOffer,
        quantity: Int
    ) async throws -> Reservation

    func fetchCustomerReservations(customerUid: String) async throws -> [Reservation]

    func fetchSellerReservations(sellerUid: String) async throws -> [Reservation]

    func confirmPickup(
        reservationId: String,
        pickupCode: String,
        sellerUid: String
    ) async throws -> Reservation

    func cancelReservation(
        reservationId: String,
        actorUid: String
    ) async throws -> Reservation
}
