import Foundation

protocol OfferRepository: Sendable {
    func fetchActiveOffers() async throws -> [FoodOffer]

    func observeActiveOffers() -> AsyncThrowingStream<[FoodOffer], Error>

    func fetchOffers(forSellerUid sellerUid: String) async throws -> [FoodOffer]

    func fetchOffer(byId offerId: String) async throws -> FoodOffer

    func createOffer(_ input: CreateOfferInput) async throws -> FoodOffer

    func updateOffer(_ offer: FoodOffer) async throws -> FoodOffer

    func updateOfferQuantity(offerId: String, quantity: Int) async throws -> FoodOffer

    func updateOfferAvailability(offerId: String, isAvailable: Bool) async throws -> FoodOffer

    func deleteOffer(offerId: String) async throws
}

extension OfferRepository {
    func observeActiveOffers() -> AsyncThrowingStream<[FoodOffer], Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let offers = try await self.fetchActiveOffers()
                    continuation.yield(offers)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
