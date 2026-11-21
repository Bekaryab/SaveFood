import SwiftUI
import UIKit
import Observation

@Observable
@MainActor
final class ExploreViewModel {

    var selectedTab: HomeNativeTab = .explore
    var searchText: String = ""
    var selectedCategory: String? = nil
    var showProfileMenu: Bool = false

    // Деректерді жүктеу күйі
    var offersState: ViewState = .idle

    // Таңдалған тауардың толық бетін (Sheet) ашу үшін
    var selectedOfferForDetails: HomeProductOffer? = nil

    // Себеттегі тауарлар тізімі
    var cartItems: [CartOrderItem] = []

    // Карта Фильтрі Sheet күйлері
    var isMapFilterSheetPresented: Bool = false
    var mapDisplayMode: MapDisplayMode = .map
    var selectedDistanceKm: Int = 1
    var mapSelectedCategory: String = "Все"
    var minDiscountPercent: Double = 0
    var onlyAvailableOffers: Bool = true
    var isShowingFullMapResults: Bool = false

    // Кастомды қала таңдау терезесінің күйі
    var selectedCity: String = "Алматы"
    var isCityPickerPresented: Bool = false
    let availableCities: [(name: String, subtitle: String)] = [
        ("Алматы", "120+ заведений рядом"),
        ("Астана", "85+ заведений рядом"),
        ("Шымкент", "45+ заведений рядом"),
        ("Қарағанды", "30+ заведений рядом"),
        ("Ақтөбе", "25+ заведений рядом"),
        ("Атырау", "20+ заведений рядом")
    ]

    var isBannerAutoScrollStopped: Bool = false
    var selectedBannerID: UUID? = nil

    let allCategories: [String] = FoodOffer.standardCategories

    var visibleCategories: [String] {
        if let selectedCategory {
            return [selectedCategory]
        }
        return allCategories
    }

    let promoBanners: [ExplorePromoBanner] = [
        ExplorePromoBanner(
            badge: "РЯДОМ С ВАМИ",
            title: "Выгодные\nпродукты рядом",
            subtitle: "Скидки до 50% в пекарнях",
            buttonTitle: "Смотреть",
            backgroundImageName: "promo_banner_1",
            filterCategory: nil,
            fallbackGradient: [
                Color(red: 0.18, green: 0.42, blue: 0.20),
                Color(red: 0.36, green: 0.58, blue: 0.28),
                Color(red: 0.52, green: 0.72, blue: 0.38)
            ],
            cartBadgeIcon: "cart.fill"
        ),
        ExplorePromoBanner(
            badge: "СВЕЖАЯ ВЫПЕЧКА",
            title: "Круассаны и хлеб\nсо скидкой -45%",
            subtitle: "Вечерняя распродажа выпечки",
            buttonTitle: "Выбрать",
            backgroundImageName: "promo_banner_2",
            filterCategory: "Выпечка",
            fallbackGradient: [
                Color(red: 0.54, green: 0.32, blue: 0.14),
                Color(red: 0.74, green: 0.46, blue: 0.20),
                Color(red: 0.86, green: 0.62, blue: 0.34)
            ],
            cartBadgeIcon: "cart.badge.plus"
        ),
        ExplorePromoBanner(
            badge: "ФЕРМЕРСКИЕ",
            title: "Спелые фрукты\nи свежие овощи",
            subtitle: "Натуральные продукты каждый день",
            buttonTitle: "К фруктам",
            backgroundImageName: "promo_banner_3",
            filterCategory: "Фрукты",
            fallbackGradient: [
                Color(red: 0.13, green: 0.38, blue: 0.30),
                Color(red: 0.22, green: 0.54, blue: 0.42),
                Color(red: 0.36, green: 0.68, blue: 0.52)
            ],
            cartBadgeIcon: "basket.fill"
        ),
        ExplorePromoBanner(
            badge: "БОКСЫ-СЮРПРИЗЫ",
            title: "Секретный бокс\nвсего за 990 ₸",
            subtitle: "Набор готовых блюд на ужин",
            buttonTitle: "Открыть",
            backgroundImageName: "promo_banner_4",
            filterCategory: "Готовая еда",
            fallbackGradient: [
                Color(red: 0.15, green: 0.28, blue: 0.21),
                Color(red: 0.25, green: 0.44, blue: 0.30),
                Color(red: 0.38, green: 0.58, blue: 0.38)
            ],
            cartBadgeIcon: "cart.fill"
        )
    ]

    // Нақты уақытта сатушылардан келетін тауарлар
    var products: [HomeProductOffer] = []

    @ObservationIgnored private let offerRepository: OfferRepository
    @ObservationIgnored private let favoritesStorageKey = "savefood.customer.favoriteOfferIDs"
    private var favoriteOfferIDs: Set<String>

    init(offerRepository: OfferRepository = RemoteOfferRepository()) {
        self.offerRepository = offerRepository
        let saved = UserDefaults.standard.stringArray(forKey: "savefood.customer.favoriteOfferIDs") ?? []
        self.favoriteOfferIDs = Set(saved)
    }

    // MARK: - Нақты уақыттағы тыңдау (Сатушы тауар қосқанда сатып алушыда бірден шығады)
    func startObservingOffers() async {
        if products.isEmpty {
            offersState = .loading
        }

        do {
            for try await remoteOffers in offerRepository.observeActiveOffers() {
                applyRemoteOffers(remoteOffers)
            }
        } catch {
            if products.isEmpty {
                offersState = .error("Не удалось загрузить предложения: \(error.localizedDescription)")
            }
        }
    }

    func refreshOffers() async {
        do {
            let remoteOffers = try await offerRepository.fetchActiveOffers()
            applyRemoteOffers(remoteOffers)
        } catch {
            if products.isEmpty {
                offersState = .error("Не удалось обновить предложения: \(error.localizedDescription)")
            }
        }
    }

    private func applyRemoteOffers(_ remoteOffers: [FoodOffer]) {
        let mapped = remoteOffers.map { offer in
            HomeProductOffer(
                from: offer,
                isFavorite: favoriteOfferIDs.contains(offer.id)
            )
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            products = mapped
            offersState = mapped.isEmpty ? .empty : .loaded

            if let currentSelected = selectedOfferForDetails,
               let refreshed = mapped.first(where: { $0.id == currentSelected.id }) {
                selectedOfferForDetails = refreshed
            }
        }
    }

    var filteredProducts: [HomeProductOffer] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return products.filter { item in
            let matchesSearch = query.isEmpty
                || item.title.localizedCaseInsensitiveContains(query)
                || item.venueName.localizedCaseInsensitiveContains(query)
                || item.category.localizedCaseInsensitiveContains(query)
            let matchesCategory = (selectedCategory == nil) || (item.category == selectedCategory)
            let matchesDiscount = Double(item.discountPercent) >= minDiscountPercent
            return matchesSearch && matchesCategory && matchesDiscount
        }
    }

    var favoriteProducts: [HomeProductOffer] {
        products.filter { $0.isFavorite }
    }

    // MARK: - Себет (Корзина)
    var totalCartCount: Int {
        cartItems.reduce(0) { $0 + $1.quantity }
    }

    var totalCartPrice: Int {
        cartItems.reduce(0) { $0 + ($1.offer.priceValue * $1.quantity) }
    }

    var formattedTotalCartPrice: String {
        formatPrice(totalCartPrice)
    }

    func formatPrice(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        let str = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(str) ₸"
    }

    func addToCart(offer: HomeProductOffer, quantity: Int) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            if let idx = cartItems.firstIndex(where: { $0.offer.id == offer.id }) {
                cartItems[idx].quantity += quantity
            } else {
                cartItems.append(CartOrderItem(offer: offer, quantity: quantity))
            }
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        selectedOfferForDetails = nil
    }

    func removeFromCart(id: UUID) {
        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
            cartItems.removeAll { $0.id == id }
        }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    func incrementCartItem(id: UUID) {
        guard let idx = cartItems.firstIndex(where: { $0.id == id }) else { return }
        guard cartItems[idx].quantity < 20 else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            cartItems[idx].quantity += 1
        }
    }

    func decrementCartItem(id: UUID) {
        guard let idx = cartItems.firstIndex(where: { $0.id == id }) else { return }
        if cartItems[idx].quantity > 1 {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                cartItems[idx].quantity -= 1
            }
        } else {
            removeFromCart(id: id)
        }
    }

    func clearCart() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            cartItems.removeAll()
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - Фильтрлер мен Баннерлер
    func selectBanner(_ banner: ExplorePromoBanner) {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
            isBannerAutoScrollStopped = true
            selectedBannerID = banner.id
            selectedCategory = banner.filterCategory
        }
    }

    func selectCategory(_ category: String?) {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
            if category == nil {
                selectedCategory = nil
                selectedBannerID = nil
                isBannerAutoScrollStopped = false
                minDiscountPercent = 0
            } else if selectedCategory == category {
                selectedCategory = nil
                selectedBannerID = nil
                isBannerAutoScrollStopped = false
            } else {
                selectedCategory = category
                mapSelectedCategory = category ?? "Все"
            }
        }
    }

    func applyMapFilterSheet() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
            if mapSelectedCategory == "Все" {
                selectedCategory = nil
            } else {
                selectedCategory = mapSelectedCategory
            }
            isMapFilterSheetPresented = false
        }
    }

    func clearFilters() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
            selectedCategory = nil
            selectedBannerID = nil
            isBannerAutoScrollStopped = false
            minDiscountPercent = 0
            searchText = ""
        }
    }

    func chooseCity(_ city: String) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            selectedCity = city
            isCityPickerPresented = false
        }
    }

    func toggleFavorite(for offerID: String) {
        if favoriteOfferIDs.contains(offerID) {
            favoriteOfferIDs.remove(offerID)
        } else {
            favoriteOfferIDs.insert(offerID)
        }
        UserDefaults.standard.set(Array(favoriteOfferIDs), forKey: favoritesStorageKey)

        guard let index = products.firstIndex(where: { $0.id == offerID }) else { return }
        withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
            products[index].isFavorite = favoriteOfferIDs.contains(offerID)
            if selectedOfferForDetails?.id == offerID {
                selectedOfferForDetails = products[index]
            }
        }
    }
}
