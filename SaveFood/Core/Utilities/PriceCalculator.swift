
import Foundation

enum PriceCalculator {

    /// Автоматический расчёт процента скидки: ((oldPrice - newPrice) / oldPrice) * 100
    static func discountPercent(oldPrice: Double, newPrice: Double) -> Int {
        guard oldPrice > 0, newPrice > 0, newPrice < oldPrice else {
            return 0
        }
        let rawPercent = ((oldPrice - newPrice) / oldPrice) * 100.0
        return max(1, min(99, Int(rawPercent.rounded())))
    }

    static func savingsAmount(oldPrice: Double, newPrice: Double) -> Double {
        guard oldPrice > newPrice else { return 0 }
        return oldPrice - newPrice
    }

    static func totalPrice(unitPrice: Double, quantity: Int) -> Double {
        guard unitPrice > 0, quantity > 0 else { return 0 }
        return unitPrice * Double(quantity)
    }

    static func formatTenge(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = amount.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount.rounded()))"
        return "\(formatted) ₸"
    }
}
