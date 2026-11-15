import SwiftUI
import UIKit
// MARK: - баннер
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

// MARK: - Тавар карточкасы
struct HomeProductOffer: Identifiable, Equatable {
    let id: UUID
    let title: String
    let venueName: String
    let category: String
    let discountPercent: Int
    let priceValue: Int             // нақты баға 640)
    let currentPrice: String        // "640 ₸"
    let oldPrice: String            // "990 ₸"
    let producedDate: String        // "28 янв"
    let expiryDate: String          // "31 янв"
    let reason: String              // "излишки"
    let descriptionText: String     // Тауар сипаттамасы
    let localImageName: String      // сурет аты
    let imageURL: String
    let fallbackSymbol: String
    let accentColor: Color
    var isFavorite: Bool = false
    init(
        id: UUID = UUID(),
        title: String,
        venueName: String,
        category: String,
        discountPercent: Int,
        priceValue: Int,
        currentPrice: String,
        oldPrice: String,
        producedDate: String = "28 янв",
        expiryDate: String = "31 янв",
        reason: String = "излишки",
        descriptionText: String,
        localImageName: String,
        imageURL: String,
        fallbackSymbol: String = "cart.fill",
        accentColor: Color,
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
}
struct CartOrderItem: Identifiable {
    let id = UUID()
    let offer: HomeProductOffer
    var quantity: Int
}
enum HomeNativeTab: Hashable {
    case explore
    case map
    case favorites
    case cart
}
final class ProductImageMemoryCache {
    static let shared = ProductImageMemoryCache()
    private let cache = NSCache<NSString, UIImage>()
    private init() {}
    func image(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }
    func insert(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}
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
        }
    }
}
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
