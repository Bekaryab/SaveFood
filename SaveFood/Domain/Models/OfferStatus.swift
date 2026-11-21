
import Foundation

enum OfferStatus: String, Codable, Equatable, Sendable {
    case active = "active"
    case soldOut = "sold_out"
    case expired = "expired"
    case hidden = "hidden"

    var displayTitle: String {
        switch self {
        case .active: return "Активно"
        case .soldOut: return "Распродано"
        case .expired: return "Истекло"
        case .hidden: return "Скрыто"
        }
    }
}
