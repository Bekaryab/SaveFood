import SwiftUI
import UIKit

// MARK: - Промо-баннер моделі
struct ExplorePromoBanner: Identifiable {
    let id = UUID()
    let badge: String
    let title: String
    let subtitle: String
    let buttonTitle: String
    let backgroundImageName: String
    let filterCategory: String?
    let fallbackGradient: [Color]
    let cartBadgeIcon: String
}

// MARK: - Сатып алушы экранындағы тауар моделі (Firestore-дағы FoodOffer-мен байланған)
struct HomeProductOffer: Identifiable, Equatable {
    let id: String
    let title: String
    let venueName: String
    let category: String
    let discountPercent: Int
    let priceValue: Int
    let currentPrice: String
    let oldPrice: String
    let producedDate: String
    let expiryDate: String
    let reason: String
    let descriptionText: String
    let localImageName: String
    let imageURL: String
    let fallbackSymbol: String
    let accentColor: Color
    var isFavorite: Bool = false

    init(
        id: String = UUID().uuidString,
        title: String,
        venueName: String,
        category: String,
        discountPercent: Int,
        priceValue: Int,
        currentPrice: String,
        oldPrice: String,
        producedDate: String = "Сегодня",
        expiryDate: String = "Завтра",
        reason: String = "Излишки",
        descriptionText: String,
        localImageName: String = "",
        imageURL: String,
        fallbackSymbol: String = "cart.fill",
        accentColor: Color = Color(red: 0.08, green: 0.30, blue: 0.15),
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.venueName = venueName
        self.category = category
        self.discountPercent = discountPercent
        self.priceValue = priceValue
        self.currentPrice = currentPrice
        self.oldPrice = oldPrice
        self.producedDate = producedDate
        self.expiryDate = expiryDate
        self.reason = reason
        self.descriptionText = descriptionText
        self.localImageName = localImageName
        self.imageURL = imageURL
        self.fallbackSymbol = fallbackSymbol
        self.accentColor = accentColor
        self.isFavorite = isFavorite
    }

    init(from offer: FoodOffer, isFavorite: Bool) {
        let formatter = Self.shortDateFormatter
        let resolvedDescription = offer.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Свежий продукт со скидкой от \(offer.venueName). Доступно: \(offer.quantity) шт."
            : offer.description

        self.init(
            id: offer.id,
            title: offer.title,
            venueName: offer.venueName,
            category: offer.category,
            discountPercent: offer.discountPercent,
            priceValue: Int(offer.newPrice.rounded()),
            currentPrice: offer.formattedNewPrice,
            oldPrice: offer.formattedOldPrice,
            producedDate: formatter.string(from: offer.producedAt),
            expiryDate: formatter.string(from: offer.expiresAt),
            reason: offer.reason.isEmpty ? "Излишки" : offer.reason,
            descriptionText: resolvedDescription,
            localImageName: "",
            imageURL: offer.photoUrl,
            fallbackSymbol: "cart.fill",
            accentColor: Self.accentColor(for: offer.category),
            isFavorite: isFavorite
        )
    }

    private static let shortDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateFormat = "d MMM"
        return df
    }()

    private static func accentColor(for category: String) -> Color {
        switch category {
        case "Фрукты": return Color(red: 0.88, green: 0.18, blue: 0.24)
        case "Овощи": return Color(red: 0.26, green: 0.58, blue: 0.24)
        case "Выпечка": return Color(red: 0.85, green: 0.58, blue: 0.24)
        case "Молочные": return Color(red: 0.35, green: 0.62, blue: 0.82)
        case "Готовая еда": return Color(red: 0.90, green: 0.45, blue: 0.28)
        case "Десерты": return Color(red: 0.82, green: 0.48, blue: 0.30)
        default: return Color(red: 0.08, green: 0.30, blue: 0.15)
        }
    }
}

// MARK: - Себетке салынған тауар моделі
struct CartOrderItem: Identifiable {
    let id = UUID()
    let offer: HomeProductOffer
    var quantity: Int
}

// MARK: - iOS Native Tab Bar бөлімдері
enum HomeNativeTab: Hashable {
    case explore
    case map
    case favorites
    case cart
}

// MARK: - Суреттерді RAM-да сақтайтын кэш
final class ProductImageMemoryCache {
    static let shared = ProductImageMemoryCache()
    private let cache = NSCache<NSString, UIImage>()
    private init() {
        cache.countLimit = 150
    }

    func image(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString) ?? RemoteImageMemoryCache.shared.image(for: key)
    }

    func insert(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
        RemoteImageMemoryCache.shared.store(image, for: key)
    }
}

// MARK: - Басты бетте де, Тауардың ішкі бетінде де бірдей фото шығаратын компонент
struct SmartCachedProductImage: View {

    let localImageName: String
    let imageURL: String
    let fallbackSymbol: String
    let accentColor: Color

    @State private var loadedImage: UIImage? = nil

    var body: some View {
        ZStack {
            if let localUIImage = SmartLocalImage.loadUIImage(named: localImageName) {
                Image(uiImage: localUIImage)
                    .resizable()
                    .scaledToFill()
            } else if let cached = loadedImage ?? ProductImageMemoryCache.shared.image(for: imageURL) {
                Image(uiImage: cached)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    accentColor.opacity(0.16)

                    ProgressView()
                        .tint(accentColor)
                }
                .task(id: imageURL) {
                    await downloadAndCacheImage()
                }
            }
        }
    }

    @MainActor
    private func downloadAndCacheImage() async {
        if let existing = ProductImageMemoryCache.shared.image(for: imageURL) {
            loadedImage = existing
            return
        }
        guard let url = URL(string: imageURL) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                ProductImageMemoryCache.shared.insert(uiImage, for: imageURL)
                loadedImage = uiImage
            }
        } catch {
            // Сұраныс экран жабылғанда тоқтатылуы мүмкін
        }
    }
}

// MARK: - Жергілікті суретті (Assets немесе Resources ішінен) жүктегіш
struct SmartLocalImage: View {
    let imageName: String

    var body: some View {
        if let uiImage = Self.loadUIImage(named: imageName) {
            Image(uiImage: uiImage)
                .resizable()
        } else {
            EmptyView()
        }
    }

    static func hasImage(named name: String) -> Bool {
        loadUIImage(named: name) != nil
    }

    static func loadUIImage(named name: String) -> UIImage? {
        guard !name.isEmpty else { return nil }

        if let image = UIImage(named: name) {
            return image
        }

        let extensions = ["png", "jpg", "jpeg", "webp", "heic"]
        let subdirectories: [String?] = [nil, "Resources", "BannerImages", "Resources/BannerImages"]

        for dir in subdirectories {
            for ext in extensions {
                if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: dir),
                   let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    return image
                }
            }
        }
        return nil
    }
}
