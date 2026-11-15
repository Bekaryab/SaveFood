import SwiftUI
import Observation
@Observable
@MainActor
final class OfferDetailsViewModel {
    var offer: HomeProductOffer
    var quantity: Int = 1
    init(offer: HomeProductOffer) {
        self.offer = offer
    }
    var totalPriceValue: Int {
        offer.priceValue * quantity
    }
    var formattedTotalPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        let numberString = formatter.string(from: NSNumber(value: totalPriceValue)) ?? "\(totalPriceValue)"
        return "\(numberString) ₸"
    }
    func incrementQuantity() {
        guard quantity < 20 else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
            quantity += 1
        }
    }
    func decrementQuantity() {
        guard quantity > 1 else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
            quantity -= 1
        }
    }
}
