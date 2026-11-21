
import SwiftUI
import UIKit

enum BusinessTab: Hashable {
    case myOffers
    case quickAddCamera
    case profile
}

struct BusinessDashboardView: View {

    let seller: User
    var onSignOut: () -> Void

    @State private var selectedTab: BusinessTab = .myOffers
    @State private var lastContentTab: BusinessTab = .myOffers

    @State private var offersViewModel: OfferManagementViewModel
    @State private var profileViewModel: BusinessProfileViewModel

    private let primaryGreen = Color(red: 0.08, green: 0.30, blue: 0.15)
    private let creamBackground = Color(red: 0.965, green: 0.969, blue: 0.937)

    init(
        seller: User,
        dependencies: AppDependencies,
        onSignOut: @escaping () -> Void
    ) {
        self.seller = seller
        self.onSignOut = onSignOut
        _offersViewModel = State(
            initialValue: OfferManagementViewModel(
                seller: seller,
                offerRepository: dependencies.offerRepository,
                profileRepository: dependencies.profileRepository,
                imageUploadService: dependencies.imageUploadService
            )
        )
        _profileViewModel = State(
            initialValue: BusinessProfileViewModel(
                seller: seller,
                profileRepository: dependencies.profileRepository,
                imageUploadService: dependencies.imageUploadService
            )
        )
        Self.configureNativeTabBarBlur()
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // 1. МОИ ТОВАРЫ (только товары этого продавца по разделам)
            MyOffersView(viewModel: offersViewModel)
                .tabItem {
                    Label("Мои товары", systemImage: "bag.fill")
                }
                .tag(BusinessTab.myOffers)

            // 2. КНОПКА "+" В TABBAR (ТОЛЬКО ДЛЯ ПРОДАВЦА -> СРАЗУ КАМЕРА)
            Color.clear
                .tabItem {
                    Label("Добавить", systemImage: "plus.circle.fill")
                }
                .tag(BusinessTab.quickAddCamera)

            // 3. ПРОФИЛЬ ЗАВЕДЕНИЯ + ВЫХОД
            BusinessProfileView(
                viewModel: profileViewModel,
                onSignOut: onSignOut
            )
            .tabItem {
                Label("Заведение", systemImage: "storefront.fill")
            }
            .tag(BusinessTab.profile)
        }
        .tint(primaryGreen)
        // Перехватываем нажатие на "+" в TabBar и мгновенно открываем камеру
        .onChange(of: selectedTab) { oldTab, newTab in
            if newTab == .quickAddCamera {
                selectedTab = lastContentTab
                offersViewModel.startQuickCameraFlow()
            } else {
                lastContentTab = newTab
            }
        }
        // Шаг 1: Камера внутри приложения
        .fullScreenCover(
            isPresented: $offersViewModel.isCameraPresented,
            onDismiss: {
                // Шаг 2: Сразу после закрытия камеры открываем Sheet с характеристиками
                offersViewModel.handleCameraDismissed()
            }
        ) {
            InAppCameraView(
                onPhotoCaptured: { capturedImage in
                    offersViewModel.handlePhotoCaptured(capturedImage)
                },
                onCancel: {
                    offersViewModel.pendingCapturedImage = nil
                    offersViewModel.isCameraPresented = false
                }
            )
        }
        // Шаг 2: Sheet заполнения характеристик и сохранения в Firebase
        .sheet(isPresented: $offersViewModel.isCreateSheetPresented) {
            if let captured = offersViewModel.activeCapturedImage {
                QuickCreateOfferSheetView(
                    viewModel: offersViewModel,
                    initialImage: captured,
                    onRetakePhoto: {
                        offersViewModel.startQuickCameraFlow()
                    }
                )
                .presentationDetents([.large])
                .presentationCornerRadius(32)
                .presentationBackground(creamBackground)
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
