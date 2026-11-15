import Foundation

enum AuthAccountRole: String, CaseIterable, Identifiable {
    case customer = "Покупатель"
    case seller = "Продавец"
    var id: String { rawValue }
    var iconName: String {
        switch self {
        case .customer: return "bag"
        case .seller: return "storefront"
        }
    }
}
