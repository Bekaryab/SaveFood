
import Foundation

struct FoodOffer: Identifiable, Codable, Equatable, Sendable {
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
    let producedAt: Date
    let expiresAt: Date
    let pickupUntil: Date
    let createdAt: Date

    var discountPercent: Int {
        PriceCalculator.discountPercent(oldPrice: oldPrice, newPrice: newPrice)
    }

    var formattedNewPrice: String {
        PriceCalculator.formatTenge(newPrice)
    }

    var formattedOldPrice: String {
        PriceCalculator.formatTenge(oldPrice)
    }

    var isExpired: Bool {
        expiresAt <= Date()
    }

    var status: OfferStatus {
        if isExpired { return .expired }
        if quantity <= 0 { return .soldOut }
        if !isAvailable { return .hidden }
        return .active
    }

    var isProduceCategory: Bool {
        let normalized = category.lowercased()
        return normalized.contains("фрукт") || normalized.contains("овощ")
    }

    var producedDateLabel: String {
        isProduceCategory ? "Собрано / упаковано" : "Изготовлено"
    }

    static let standardCategories: [String] = [
        "Фрукты",
        "Овощи",
        "Выпечка",
        "Молочные",
        "Готовая еда",
        "Десерты"
    ]

    static let standardReasons: [String] = [
        "Излишки",
        "Скоро истекает срок",
        "Вечерняя распродажа",
        "Спелые продукты",
        "Нетоварный вид упаковки"
    ]
}

struct CreateOfferInput: Sendable {
    let sellerUid: String
    let venueId: String
    let venueName: String
    let title: String
    let category: String
    let oldPrice: Double
    let newPrice: Double
    let quantity: Int
    let photoUrl: String
    let description: String
    let reason: String
    let producedAt: Date
    let expiresAt: Date
    let pickupUntil: Date
}
