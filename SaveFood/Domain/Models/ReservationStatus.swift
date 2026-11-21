
import Foundation

enum ReservationStatus: String, Codable, CaseIterable, Equatable, Sendable {
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"

    var displayTitle: String {
        switch self {
        case .active: return "Ожидает получения"
        case .completed: return "Выдан"
        case .cancelled: return "Отменён"
        }
    }
}
