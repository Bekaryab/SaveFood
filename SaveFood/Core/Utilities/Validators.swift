
import Foundation

enum ValidationError: LocalizedError, Equatable {
    case emptyFullName(UserRole)
    case invalidEmail
    case weakPassword
    case emptyVenueName
    case emptyVenueAddress
    case invalidPhotoURL
    case emptyOfferTitle
    case emptyOfferCategory
    case invalidOldPrice
    case invalidNewPrice
    case newPriceNotLowerThanOld
    case invalidQuantity
    case invalidExpirationDate
    case invalidPickupDate
    case invalidPickupCode

    var errorDescription: String? {
        switch self {
        case .emptyFullName(let role):
            return role == .customer
                ? "Введите ваше полное имя."
                : "Введите название заведения или имя владельца."
        case .invalidEmail:
            return "Введите корректный адрес электронной почты."
        case .weakPassword:
            return "Пароль должен содержать минимум 6 символов."
        case .emptyVenueName:
            return "Укажите название заведения."
        case .emptyVenueAddress:
            return "Укажите адрес заведения."
        case .invalidPhotoURL:
            return "Некорректная ссылка на фотографию."
        case .emptyOfferTitle:
            return "Введите название продукта."
        case .emptyOfferCategory:
            return "Выберите категорию продукта."
        case .invalidOldPrice:
            return "Старая цена должна быть больше 0."
        case .invalidNewPrice:
            return "Новая цена должна быть больше 0."
        case .newPriceNotLowerThanOld:
            return "Новая цена должна быть строго ниже старой цены."
        case .invalidQuantity:
            return "Количество товара должно быть больше 0."
        case .invalidExpirationDate:
            return "Срок годности должен быть позже даты производства или сбора."
        case .invalidPickupDate:
            return "Время окончания самовывоза должно быть позже текущего времени."
        case .invalidPickupCode:
            return "Введите корректный код получения заказа."
        }
    }
}

enum Validators {

    static func validateEmail(_ email: String) throws -> String {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        guard !trimmed.isEmpty, trimmed.range(of: pattern, options: .regularExpression) != nil else {
            throw ValidationError.invalidEmail
        }
        return trimmed
    }

    static func validatePassword(_ password: String) throws -> String {
        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 6 else {
            throw ValidationError.weakPassword
        }
        return trimmed
    }

    static func validateFullName(_ name: String, role: UserRole) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            throw ValidationError.emptyFullName(role)
        }
        return trimmed
    }

    static func isValidHTTPURL(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              (scheme == "https" || scheme == "http"),
              let host = url.host,
              !host.isEmpty else {
            return false
        }
        return true
    }

    static func validateVenue(name: String, address: String, photoUrl: String) throws {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationError.emptyVenueName
        }
        if address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationError.emptyVenueAddress
        }
        if !isValidHTTPURL(photoUrl) {
            throw ValidationError.invalidPhotoURL
        }
    }

    static func validateOffer(
        title: String,
        category: String,
        oldPrice: Double,
        newPrice: Double,
        quantity: Int,
        photoUrl: String,
        producedAt: Date?,
        expiresAt: Date?,
        pickupUntil: Date? = nil,
        requirePositiveQuantity: Bool = true
    ) throws {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationError.emptyOfferTitle
        }
        if category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationError.emptyOfferCategory
        }
        guard oldPrice > 0 else {
            throw ValidationError.invalidOldPrice
        }
        guard newPrice > 0 else {
            throw ValidationError.invalidNewPrice
        }
        guard newPrice < oldPrice else {
            throw ValidationError.newPriceNotLowerThanOld
        }
        if requirePositiveQuantity {
            guard quantity > 0 else {
                throw ValidationError.invalidQuantity
            }
        } else {
            guard quantity >= 0 else {
                throw ValidationError.invalidQuantity
            }
        }
        guard isValidHTTPURL(photoUrl) else {
            throw ValidationError.invalidPhotoURL
        }
        if let producedAt, let expiresAt, expiresAt <= producedAt {
            throw ValidationError.invalidExpirationDate
        }
        if let pickupUntil, pickupUntil <= Date() {
            throw ValidationError.invalidPickupDate
        }
    }

    static func validatePickupCode(_ code: String) throws -> String {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard normalized.count >= 4 else {
            throw ValidationError.invalidPickupCode
        }
        return normalized
    }
}
