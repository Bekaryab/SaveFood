
import Foundation

enum UserRole: String, Codable, CaseIterable, Identifiable, Sendable {
    case customer = "customer"
    case seller = "seller"

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .customer: return "Покупатель"
        case .seller: return "Продавец"
        }
    }

    var iconName: String {
        switch self {
        case .customer: return "bag"
        case .seller: return "storefront"
        }
    }
}
