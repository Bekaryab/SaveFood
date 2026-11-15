import SwiftUI
import Observation
@Observable
@MainActor
final class ExploreViewModel {
    var selectedTab: HomeNativeTab = .explore
    var searchText: String = ""
    var selectedCategory: String? = nil
    var showProfileMenu: Bool = false
    // Таңдалған тауардың толық бетін  ашу үшін    (Sheet)
    var selectedOfferForDetails: HomeProductOffer? = nil
    // тауарлар список
    var cartItems: [CartOrderItem] = []
    // Карта Фильтрі Sheet күйлері
    var isMapFilterSheetPresented: Bool = false
    var mapDisplayMode: MapDisplayMode = .map
    var selectedDistanceKm: Int = 1
    var mapSelectedCategory: String = "Овощи"
    var minDiscountPercent: Double = 20
    var onlyAvailableOffers: Bool = true
    var isShowingFullMapResults: Bool = false
    //  қала таңдау
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
    let allCategories: [String] = [
        "Фрукты",
        "Овощи",
        "Выпечка",
        "Молочные",
        "Готовая еда",
        "Десерты"
    ]
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
    var products: [HomeProductOffer] = [
        HomeProductOffer(
            title: "Томаты Черри",
            venueName: "Green Market",
            category: "Овощи",
            discountPercent: 35,
            priceValue: 640,
            currentPrice: "640 ₸",
            oldPrice: "990 ₸",
            producedDate: "28 янв",
            expiryDate: "31 янв",
            reason: "излишки",
            descriptionText: "Свежие, отборные томаты. Отлично подойдут для салатов и закусок.",
            localImageName: "offer_tomato",
            imageURL: "https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=900&q=85",
            accentColor: Color(red: 0.86, green: 0.24, blue: 0.18)
        ),
        HomeProductOffer(
            title: "Круассан",
            venueName: "Paul Bakery",
            category: "Выпечка",
            discountPercent: 40,
            priceValue: 490,
            currentPrice: "490 ₸",
            oldPrice: "820 ₸",
            producedDate: "29 янв",
            expiryDate: "30 янв",
            reason: "излишки",
            descriptionText: "Свежий французский круассан на сливочном масле с хрустящей золотистой корочкой.",
            localImageName: "offer_croissant",
            imageURL: "https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=900&q=85",
            accentColor: Color(red: 0.85, green: 0.58, blue: 0.24)
        ),
        HomeProductOffer(
            title: "Клубника",
            venueName: "Green Market",
            category: "Фрукты",
            discountPercent: 35,
            priceValue: 1290,
            currentPrice: "1 290 ₸",
            oldPrice: "1 990 ₸",
            producedDate: "28 янв",
            expiryDate: "31 янв",
            reason: "излишки",
            descriptionText: "Сладкая и ароматная тепличная клубника. Идеальна для десертов, смузи и завтраков.",
            localImageName: "offer_strawberry",
            imageURL: "https://images.unsplash.com/photo-1464965911861-746a04b4bca6?auto=format&fit=crop&w=900&q=85",
            accentColor: Color(red: 0.88, green: 0.18, blue: 0.24)
        ),
        HomeProductOffer(
            title: "Авокадо Хасс (2 шт)",
            venueName: "Eco Lavka",
            category: "Овощи",
            discountPercent: 40,
            priceValue: 890,
            currentPrice: "890 ₸",
            oldPrice: "1 490 ₸",
            producedDate: "27 янв",
            expiryDate: "31 янв",
            reason: "спелые",
            descriptionText: "Мягкие, полностью созревшие авокадо сорта Хасс. Готовы к употреблению прямо сейчас.",
            localImageName: "offer_avocado",
            imageURL: "https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?auto=format&fit=crop&w=900&q=85",
            accentColor: Color(red: 0.26, green: 0.58, blue: 0.24)
        ),
        HomeProductOffer(
            title: "Фермерское молоко",
            venueName: "Молочная Ферма",
            category: "Молочные",
            discountPercent: 30,
            priceValue: 520,
            currentPrice: "520 ₸",
            oldPrice: "750 ₸",
            producedDate: "28 янв",
            expiryDate: "31 янв",
            reason: "срок",
            descriptionText: "Натуральное пастеризованное фермерское молоко 3.2% жирности без добавок.",
            localImageName: "offer_milk",
            imageURL: "https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=900&q=85",
            accentColor: Color(red: 0.35, green: 0.62, blue: 0.82)
        ),
        HomeProductOffer(
            title: "Ремесленный хлеб",
            venueName: "Bread & Butter",
            category: "Выпечка",
            discountPercent: 45,
            priceValue: 390,
            currentPrice: "390 ₸",
            oldPrice: "710 ₸",
            producedDate: "29 янв",
            expiryDate: "31 янв",
            reason: "излишки",
            descriptionText: "Ароматный подовый хлеб на натуральной закваске с хрустящей корочкой.",
            localImageName: "offer_bread",
            imageURL: "https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=900&q=85",
            accentColor: Color(red: 0.76, green: 0.52, blue: 0.28)
        ),
        HomeProductOffer(
            title: "Боул с лососем",
            venueName: "Healthy Kitchen",
            category: "Готовая еда",
            discountPercent: 50,
            priceValue: 1450,
            currentPrice: "1 450 ₸",
            oldPrice: "2 900 ₸",
            producedDate: "29 янв",
            expiryDate: "30 янв",
            reason: "излишки",
            descriptionText: "Сбалансированный боул со слабосоленым лососем, рисом, авокадо, эдамаме и кунжутным соусом.",
            localImageName: "offer_bowl",
            imageURL: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=85",
            accentColor: Color(red: 0.90, green: 0.45, blue: 0.28)
        ),
        HomeProductOffer(
            title: "Чизкейк Сан-Себастьян",
            venueName: "Sweet Studio",
            category: "Десерты",
            discountPercent: 35,
            priceValue: 950,
            currentPrice: "950 ₸",
            oldPrice: "1 490 ₸",
            producedDate: "28 янв",
            expiryDate: "31 янв",
            reason: "излишки",
            descriptionText: "Нежный кремовый баскский чизкейк с карамелизированной корочкой.",
            localImageName: "offer_cheesecake",
            imageURL: "https://images.unsplash.com/photo-1533134242443-d4fd215305ad?auto=format&fit=crop&w=900&q=85",
            accentColor: Color(red: 0.82, green: 0.48, blue: 0.30)
        )
    ]
    init(offerRepository: Any? = nil) {}
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
    var totalCartCount: Int {
        cartItems.reduce(0) { $0 + $1.quantity }
    }
    func addToCart(offer: HomeProductOffer, quantity: Int) {
        if let idx = cartItems.firstIndex(where: { $0.offer.id == offer.id }) {
            cartItems[idx].quantity += quantity
        } else {
            cartItems.append(CartOrderItem(offer: offer, quantity: quantity))
        }
        selectedOfferForDetails = nil
    }
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
                minDiscountPercent = 5
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
            minDiscountPercent = 5
            searchText = ""
        }
    }

    func chooseCity(_ city: String) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            selectedCity = city
            isCityPickerPresented = false
        }
    }

    func toggleFavorite(for offerID: UUID) {
        guard let index = products.firstIndex(where: { $0.id == offerID }) else { return }
        withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
            products[index].isFavorite.toggle()
            if selectedOfferForDetails?.id == offerID {
                selectedOfferForDetails = products[index]
            }
        }
    }
}
