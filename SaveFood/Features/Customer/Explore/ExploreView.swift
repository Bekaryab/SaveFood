import SwiftUI
import UIKit

struct ExploreView: View {

    var userName: String = "Пользователь"
    var userRole: AuthAccountRole = .customer
    var onSignOut: (() -> Void)? = nil

    @State private var viewModel: ExploreViewModel
    @State private var isSearchExpanded: Bool = false
    @FocusState private var isSearchFieldFocused: Bool
    @Namespace private var topHeaderNamespace

    private let primaryGreen = Color(red: 0.08, green: 0.30, blue: 0.15)
    private let creamBackground = Color(red: 0.965, green: 0.969, blue: 0.937)
    private let softSageCard = Color(red: 0.905, green: 0.932, blue: 0.880)

    init(
        userName: String = "Пользователь",
        userRole: AuthAccountRole = .customer,
        offerRepository: OfferRepository = RemoteOfferRepository(),
        onSignOut: (() -> Void)? = nil
    ) {
        self.userName = userName
        self.userRole = userRole
        self.onSignOut = onSignOut
        _viewModel = State(initialValue: ExploreViewModel(offerRepository: offerRepository))
        Self.configureNativeTabBarBlur()
    }

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            exploreMainTab
                .tabItem {
                    Label("Главная", systemImage: "house.fill")
                }
                .tag(HomeNativeTab.explore)

            exploreMainTab
                .tabItem {
                    Label("Карта", systemImage: "mappin.and.ellipse")
                }
                .tag(HomeNativeTab.map)

            favoritesNavigationTab
                .tabItem {
                    Label("Избранное", systemImage: "heart.fill")
                }
                .tag(HomeNativeTab.favorites)

            cartNavigationTab
                .tabItem {
                    Label("Корзина", systemImage: "cart.fill")
                }
                .badge(viewModel.totalCartCount)
                .tag(HomeNativeTab.cart)
        }
        .tint(primaryGreen)
        // Нақты уақыттағы тауарлар тыңдаушысын іске қосамыз
        .task {
            await viewModel.startObservingOffers()
        }
        .sheet(item: $viewModel.selectedOfferForDetails) { selectedOffer in
            OfferDetailsView(
                offer: selectedOffer,
                onToggleFavorite: {
                    viewModel.toggleFavorite(for: selectedOffer.id)
                },
                onAddToCart: { offer, qty in
                    viewModel.addToCart(offer: offer, quantity: qty)
                },
                onClose: {
                    viewModel.selectedOfferForDetails = nil
                }
            )
            .presentationDetents([.fraction(0.84), .large])
            .presentationCornerRadius(36)
            .presentationDragIndicator(.hidden)
            .presentationBackground(creamBackground)
        }
        .onChange(of: viewModel.selectedTab) { _, newTab in
            if newTab == .map {
                if let currentCat = viewModel.selectedCategory {
                    viewModel.mapSelectedCategory = currentCat
                }
                viewModel.isMapFilterSheetPresented = true
            }
        }
        .sheet(
            isPresented: $viewModel.isMapFilterSheetPresented,
            onDismiss: {
                if viewModel.selectedTab == .map {
                    viewModel.selectedTab = .explore
                }
            }
        ) {
            MapFilterSheetView(
                viewModel: viewModel,
                onClose: {
                    viewModel.isMapFilterSheetPresented = false
                    viewModel.selectedTab = .explore
                },
                onShowOnMap: {
                    viewModel.applyMapFilterSheet()
                    viewModel.selectedTab = .explore
                }
            )
            .presentationDetents([.height(620), .large])
            .presentationCornerRadius(34)
            .presentationDragIndicator(.hidden)
            .presentationBackground(Color(red: 0.973, green: 0.976, blue: 0.953))
        }
        .confirmationDialog(
            "\(userName) (\(userRole.rawValue))",
            isPresented: $viewModel.showProfileMenu,
            titleVisibility: .visible
        ) {
            Button("Выйти из аккаунта", role: .destructive) {
                onSignOut?()
            }
            Button("Отмена", role: .cancel) {}
        }
    }

    // MARK: - Главная вкладка
    private var exploreMainTab: some View {
        ZStack(alignment: .top) {
            creamBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {

                    PromoBannerCarouselView(
                        banners: viewModel.promoBanners,
                        isAutoScrollStopped: $viewModel.isBannerAutoScrollStopped,
                        selectedBannerID: viewModel.selectedBannerID,
                        onSelectBanner: { banner in
                            viewModel.selectBanner(banner)
                        }
                    )
                    .padding(.top, 8)

                    HStack(alignment: .firstTextBaseline) {
                        Text(viewModel.selectedCategory ?? "Выгодные предложения")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(primaryGreen)

                        Spacer()

                        Text("\(viewModel.filteredProducts.count) товаров")
                            .font(.system(size: 13.5, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(red: 0.42, green: 0.49, blue: 0.43))
                    }
                    .padding(.horizontal, 20)

                    offersGridSection

                    Spacer(minLength: 28)
                }
            }
            .refreshable {
                await viewModel.refreshOffers()
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .top, spacing: 0) {
                customBlurHeader
            }

            if viewModel.isCityPickerPresented {
                customCityPickerOverlay
                    .zIndex(50)
            }
        }
    }

    @ViewBuilder
    private var offersGridSection: some View {
        switch viewModel.offersState {
        case .idle, .loading where viewModel.products.isEmpty:
            VStack(spacing: 12) {
                ProgressView()
                    .tint(primaryGreen)
                Text("Загружаем свежие предложения...")
                    .font(.system(size: 14.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 48)

        case .error(let message) where viewModel.products.isEmpty:
            VStack(spacing: 12) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 38))
                    .foregroundStyle(.red.opacity(0.7))

                Text(message)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(primaryGreen)
                    .padding(.horizontal, 24)

                Button {
                    Task { await viewModel.refreshOffers() }
                } label: {
                    Text("Обновить")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(primaryGreen))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)

        default:
            if viewModel.filteredProducts.isEmpty {
                emptySearchState
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 14),
                        GridItem(.flexible(), spacing: 14)
                    ],
                    spacing: 16
                ) {
                    ForEach(viewModel.filteredProducts) { offer in
                        OfferCardView(
                            offer: offer,
                            onSelectOffer: {
                                viewModel.selectedOfferForDetails = offer
                            },
                            onToggleFavorite: {
                                viewModel.toggleFavorite(for: offer.id)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .animation(.spring(response: 0.36, dampingFraction: 0.84), value: viewModel.selectedCategory)
            }
        }
    }

    // MARK: - Жоғарғы Blur Header
    private var customBlurHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                if isSearchExpanded {
                    HStack(spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(primaryGreen)

                            TextField("Найти продукты в г. \(viewModel.selectedCity)...", text: $viewModel.searchText)
                                .font(.system(size: 15.5, weight: .regular, design: .rounded))
                                .foregroundStyle(primaryGreen)
                                .focused($isSearchFieldFocused)
                                .submitLabel(.search)
                                .autocorrectionDisabled()

                            if !viewModel.searchText.isEmpty {
                                Button {
                                    viewModel.searchText = ""
                                } label: {
                                    Image(systemName: "multiply.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 36)
                        .background(
                            Capsule()
                                .fill(softSageCard)
                                .matchedGeometryEffect(id: "SearchMorphPill", in: topHeaderNamespace)
                        )

                        Button {
                            isSearchFieldFocused = false
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                                viewModel.searchText = ""
                                isSearchExpanded = false
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(primaryGreen)
                                .padding(.horizontal, 6)
                                .frame(height: 36)
                        }
                        .buttonStyle(.plain)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                } else {
                    ZStack {
                        Text("SaveFood")
                            .font(.system(size: 17.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(primaryGreen)
                            .fixedSize()
                            .transition(.scale(scale: 0.85).combined(with: .opacity))

                        HStack(spacing: 0) {
                            Button {
                                withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                                    viewModel.isCityPickerPresented.toggle()
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "building.2.fill")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(primaryGreen)

                                    Text(viewModel.selectedCity)
                                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                                        .foregroundStyle(primaryGreen)
                                        .lineLimit(1)

                                    Image(systemName: viewModel.isCityPickerPresented ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 8.5, weight: .bold))
                                        .foregroundStyle(primaryGreen.opacity(0.75))
                                }
                                .padding(.horizontal, 10)
                                .frame(height: 34)
                                .background(
                                    Capsule()
                                        .fill(softSageCard)
                                )
                            }
                            .buttonStyle(.plain)
                            .transition(.move(edge: .leading).combined(with: .opacity))

                            Spacer()

                            HStack(spacing: 6) {
                                Button {
                                    viewModel.isCityPickerPresented = false
                                    withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                                        isSearchExpanded = true
                                    }
                                    Task { @MainActor in
                                        try? await Task.sleep(for: .milliseconds(100))
                                        isSearchFieldFocused = true
                                    }
                                } label: {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(viewModel.searchText.isEmpty ? primaryGreen : .white)
                                        .frame(width: 34, height: 34)
                                        .background(
                                            Capsule()
                                                .fill(viewModel.searchText.isEmpty ? softSageCard : primaryGreen)
                                                .matchedGeometryEffect(id: "SearchMorphPill", in: topHeaderNamespace)
                                        )
                                }
                                .buttonStyle(.plain)

                                Button {
                                    // Notifications
                                } label: {
                                    Image(systemName: "bell")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(primaryGreen)
                                        .frame(width: 34, height: 34)
                                        .background(
                                            Circle()
                                                .fill(softSageCard)
                                        )
                                }
                                .buttonStyle(.plain)
                                .transition(.move(edge: .trailing).combined(with: .opacity))

                                Button {
                                    viewModel.showProfileMenu = true
                                } label: {
                                    Image(systemName: "person")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(primaryGreen)
                                        .frame(width: 34, height: 34)
                                        .background(
                                            Circle()
                                                .fill(softSageCard)
                                        )
                                }
                                .buttonStyle(.plain)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                    }
                }
            }
            .frame(height: 36)
            .padding(.horizontal, 16)
            .padding(.top, 4)

            SlidingFilterBarView(
                visibleCategories: viewModel.visibleCategories,
                selectedCategory: viewModel.selectedCategory,
                onSelectCategory: { category in
                    viewModel.selectCategory(category)
                },
                onClearCategory: {
                    viewModel.selectCategory(nil)
                }
            )
            .padding(.bottom, 10)
        }
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(creamBackground.opacity(0.58))
                .overlay(alignment: .bottom) {
                    Divider().opacity(0.3)
                }
                .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: - Кастомды Қала таңдау терезесі
    private var customCityPickerOverlay: some View {
        ZStack(alignment: .topLeading) {
            Color.black.opacity(0.22)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                        viewModel.isCityPickerPresented = false
                    }
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "building.2.crop.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(primaryGreen)

                    Text("Выберите город")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(primaryGreen)

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                            viewModel.isCityPickerPresented = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(primaryGreen)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(softSageCard))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 4)

                ForEach(viewModel.availableCities, id: \.name) { cityItem in
                    let isSelected = (viewModel.selectedCity == cityItem.name)

                    Button {
                        viewModel.chooseCity(cityItem.name)
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? Color.white.opacity(0.22) : softSageCard)
                                    .frame(width: 34, height: 34)

                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(isSelected ? .white : primaryGreen)
                            }

                            VStack(alignment: .leading, spacing: 1) {
                                Text(cityItem.name)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(isSelected ? .white : primaryGreen)

                                Text(cityItem.subtitle)
                                    .font(.system(size: 11.5, weight: .regular, design: .rounded))
                                    .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
                            }

                            Spacer()

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 17))
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(isSelected ? primaryGreen : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .frame(width: 265)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.976, green: 0.980, blue: 0.957))
                    .shadow(color: Color.black.opacity(0.16), radius: 20, x: 0, y: 10)
            )
            .padding(.leading, 16)
            .padding(.top, 48)
            .transition(.scale(scale: 0.9, anchor: .topLeading).combined(with: .opacity))
        }
    }

    private var emptySearchState: some View {
        VStack(spacing: 12) {
            Image(systemName: "cart.badge.questionmark")
                .font(.system(size: 40))
                .foregroundStyle(primaryGreen.opacity(0.55))

            Text(
                viewModel.products.isEmpty
                    ? "Пока нет активных предложений"
                    : "По вашему запросу ничего не найдено"
            )
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(primaryGreen)

            if !viewModel.products.isEmpty {
                Button {
                    viewModel.clearFilters()
                } label: {
                    Text("Сбросить фильтры")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(primaryGreen))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var favoritesNavigationTab: some View {
        NavigationStack {
            ZStack {
                creamBackground.ignoresSafeArea()

                if viewModel.favoriteProducts.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 46))
                            .foregroundStyle(primaryGreen.opacity(0.45))

                        Text("В избранном пока пусто")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(primaryGreen)

                        Text("Нажмите на сердечко на карточке продукта, чтобы сохранить его здесь")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 14),
                                GridItem(.flexible(), spacing: 14)
                            ],
                            spacing: 16
                        ) {
                            ForEach(viewModel.favoriteProducts) { offer in
                                OfferCardView(
                                    offer: offer,
                                    onSelectOffer: {
                                        viewModel.selectedOfferForDetails = offer
                                    },
                                    onToggleFavorite: {
                                        viewModel.toggleFavorite(for: offer.id)
                                    }
                                )
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Избранное")
        }
    }

    // MARK: - КОРЗИНА
    private var cartNavigationTab: some View {
        NavigationStack {
            ZStack {
                creamBackground.ignoresSafeArea()

                if viewModel.cartItems.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(primaryGreen.opacity(0.45))

                        Text("Корзина заказов пуста")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(primaryGreen)

                        Text("Выберите понравившийся продукт на главном экране и нажмите «В корзину»")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 36)

                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                viewModel.selectedTab = .explore
                            }
                        } label: {
                            Text("Перейти к покупкам")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 22)
                                .frame(height: 48)
                                .background(Capsule().fill(primaryGreen))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 6)
                    }
                } else {
                    VStack(spacing: 0) {
                        HStack(spacing: 6) {
                            Image(systemName: "hand.draw.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Проведите по карточке вправо или влево, чтобы удалить")
                                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                            Spacer()
                        }
                        .foregroundStyle(Color(red: 0.40, green: 0.47, blue: 0.41))
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                        .padding(.bottom, 4)

                        List {
                            ForEach(viewModel.cartItems) { item in
                                CartItemRowView(
                                    item: item,
                                    primaryGreen: primaryGreen,
                                    formattedSubtotal: viewModel.formatPrice(item.offer.priceValue * item.quantity),
                                    onIncrement: {
                                        viewModel.incrementCartItem(id: item.id)
                                    },
                                    onDecrement: {
                                        viewModel.decrementCartItem(id: item.id)
                                    },
                                    onTap: {
                                        viewModel.selectedOfferForDetails = item.offer
                                    }
                                )
                                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.removeFromCart(id: item.id)
                                    } label: {
                                        Label("Удалить", systemImage: "trash.fill")
                                    }
                                    .tint(.red)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.removeFromCart(id: item.id)
                                    } label: {
                                        Label("Удалить", systemImage: "trash.fill")
                                    }
                                    .tint(.red)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)

                        VStack(spacing: 14) {
                            HStack {
                                Text("Товаров в корзине (\(viewModel.totalCartCount) шт)")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color(red: 0.36, green: 0.43, blue: 0.37))

                                Spacer()

                                Text(viewModel.formattedTotalCartPrice)
                                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                                    .foregroundStyle(primaryGreen)
                                    .contentTransition(.numericText())
                            }

                            Button {
                                viewModel.clearCart()
                            } label: {
                                HStack {
                                    Text("Оформить заказ")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))

                                    Spacer()

                                    Text(viewModel.formattedTotalCartPrice)
                                        .font(.system(size: 18, weight: .bold, design: .rounded))

                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 15, weight: .bold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.11, green: 0.35, blue: 0.18),
                                                    Color(red: 0.07, green: 0.27, blue: 0.13)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                )
                                .shadow(color: primaryGreen.opacity(0.22), radius: 10, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        .padding(.bottom, 16)
                        .background(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 28,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 28,
                                style: .continuous
                            )
                            .fill(Color(red: 0.976, green: 0.980, blue: 0.957))
                            .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: -4)
                        )
                    }
                }
            }
            .navigationTitle("Корзина")
            .toolbar {
                if !viewModel.cartItems.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            viewModel.clearCart()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
    }

    private static func configureNativeTabBarBlur() {
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        tabAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        tabAppearance.backgroundColor = UIColor(red: 0.976, green: 0.980, blue: 0.957, alpha: 0.72)

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}

private struct CartItemRowView: View {

    let item: CartOrderItem
    let primaryGreen: Color
    let formattedSubtotal: String
    var onIncrement: () -> Void
    var onDecrement: () -> Void
    var onTap: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            SmartCachedProductImage(
                localImageName: item.offer.localImageName,
                imageURL: item.offer.imageURL,
                fallbackSymbol: item.offer.fallbackSymbol,
                accentColor: item.offer.accentColor
            )
            .frame(width: 78, height: 78)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .onTapGesture(perform: onTap)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.offer.venueName)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(item.offer.title)
                    .font(.system(size: 16.5, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryGreen)
                    .lineLimit(1)

                Text(formattedSubtotal)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(primaryGreen)
                    .contentTransition(.numericText())
                    .padding(.top, 2)
            }
            .onTapGesture(perform: onTap)

            Spacer(minLength: 4)

            HStack(spacing: 10) {
                Button(action: onDecrement) {
                    Image(systemName: item.quantity == 1 ? "trash" : "minus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(item.quantity == 1 ? Color.red : primaryGreen)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(Color(red: 0.885, green: 0.906, blue: 0.859))
                        )
                }
                .buttonStyle(.plain)

                Text("\(item.quantity)")
                    .font(.system(size: 15.5, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryGreen)
                    .frame(minWidth: 18)
                    .contentTransition(.numericText())

                Button(action: onIncrement) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(primaryGreen)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(Color(red: 0.885, green: 0.906, blue: 0.859))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color(red: 0.918, green: 0.937, blue: 0.890))
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.938, green: 0.953, blue: 0.910))
        )
    }
}

#Preview {
    ExploreView()
}
