import SwiftUI
struct PromoBannerCarouselView: View {
    let banners: [ExplorePromoBanner]
    @Binding var isAutoScrollStopped: Bool
    let selectedBannerID: UUID?
    var onSelectBanner: (ExplorePromoBanner) -> Void
    @State private var currentIndex: Int = 0
    @State private var scrolledBannerID: UUID?
    private let primaryGreen = Color(red: 0.08, green: 0.30, blue: 0.15)
    var body: some View {
        VStack(spacing: 10) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(banners.enumerated()), id: \.element.id) { index, banner in
                            let isSelectedAndStopped = isAutoScrollStopped && (selectedBannerID == banner.id)
                            PromoBannerCardView(
                                banner: banner,
                                isSelected: isSelectedAndStopped,
                                onAction: {
                                    stopAndSelect(banner: banner, index: index, proxy: proxy)
                                }
                            )
                            .id(banner.id)
                            .onTapGesture {
                                stopAndSelect(banner: banner, index: index, proxy: proxy)
                            }
                            .containerRelativeFrame(.horizontal) { containerWidth, _ in
                                max(260, containerWidth - 36)
                            }
                            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1.0 : 0.96)
                                    .opacity(phase.isIdentity ? 1.0 : 0.90)
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $scrolledBannerID)
                .contentMargins(.horizontal, 20, for: .scrollContent)
                .task(id: isAutoScrollStopped) {
                    guard !isAutoScrollStopped, !banners.isEmpty else { return }
                    while !Task.isCancelled && !isAutoScrollStopped {
                        try? await Task.sleep(for: .seconds(3))
                        guard !Task.isCancelled && !isAutoScrollStopped else { break }
                        let nextIndex = (currentIndex + 1) % banners.count
                        currentIndex = nextIndex
                        let nextID = banners[nextIndex].id
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                            scrolledBannerID = nextID
                            proxy.scrollTo(nextID, anchor: .leading)
                        }
                    }
                }
                .onChange(of: scrolledBannerID) { _, newID in
                    if let newID, let idx = banners.firstIndex(where: { $0.id == newID }) {
                        currentIndex = idx
                    }
                }
            }
            HStack(spacing: 6) {
                ForEach(Array(banners.enumerated()), id: \.element.id) { index, _ in
                    let isActive = (index == currentIndex)
                    Capsule()
                        .fill(isActive ? primaryGreen : primaryGreen.opacity(0.22))
                        .frame(width: isActive ? 20 : 6, height: 6)
                        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: currentIndex)
                }
                if isAutoScrollStopped {
                    Text("• Выбрано")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(primaryGreen.opacity(0.75))
                        .transition(.opacity)
                }
            }
        }
    }
    private func stopAndSelect(banner: ExplorePromoBanner, index: Int, proxy: ScrollViewProxy) {
        currentIndex = index
        scrolledBannerID = banner.id
        withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
            proxy.scrollTo(banner.id, anchor: .center)
        }
        onSelectBanner(banner)
    }
}
struct PromoBannerCardView: View {
    let banner: ExplorePromoBanner
    var isSelected: Bool = false
    var onAction: () -> Void
    private var hasCustomBg: Bool {
        SmartLocalImage.hasImage(named: banner.backgroundImageName)
    }
    var body: some View {
        ZStack(alignment: .leading) {
            if hasCustomBg {
                SmartLocalImage(imageName: banner.backgroundImageName)
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.58),
                                Color.black.opacity(0.28),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            } else {
                LinearGradient(
                    colors: banner.fallbackGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 165, height: 165)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .offset(x: 35, y: 30)
            }
            if !hasCustomBg {
                PromoCartIllustrationView(cartSymbol: banner.cartBadgeIcon)
                    .frame(width: 104, height: 132)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 8)
                    .padding(.bottom, 6)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "cart.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text(banner.badge)
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(0.5)
                        .lineLimit(1)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.24))
                )
                .fixedSize(horizontal: true, vertical: true)
                Text(banner.title)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineSpacing(1.5)
                    .lineLimit(2)
                    .minimumScaleFactor(0.80)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.trailing, hasCustomBg ? 16 : 92)
                Text(banner.subtitle)
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.trailing, hasCustomBg ? 16 : 102)
                Spacer(minLength: 4)
                Button(action: onAction) {
                    HStack(spacing: 6) {
                        Text(isSelected ? "Выбрано" : banner.buttonTitle)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                        Image(systemName: isSelected ? "checkmark" : "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(Color(red: 0.09, green: 0.29, blue: 0.14))
                    .padding(.horizontal, 16)
                    .frame(height: 36)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.96, green: 0.97, blue: 0.93))
                    )
                    .fixedSize(horizontal: true, vertical: true)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
        }
        .frame(height: 196)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(isSelected ? 0.85 : 0.0), lineWidth: 2.5)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}
private struct PromoCartIllustrationView: View {
    let cartSymbol: String
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.16))
                .frame(width: 86, height: 86)
                .offset(x: 4, y: 6)
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.98, green: 0.76, blue: 0.34), Color(red: 0.85, green: 0.52, blue: 0.16)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 22, height: 54)
                .rotationEffect(.degrees(-10))
                .offset(x: -12, y: -18)
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.86, blue: 0.28), Color(red: 0.94, green: 0.68, blue: 0.14)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 28, height: 28)
                .rotationEffect(.degrees(14))
                .offset(x: 14, y: -12)
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.96, blue: 0.88),
                            Color(red: 0.82, green: 0.88, blue: 0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 70, height: 60)
                .rotationEffect(.degrees(5))
                .offset(x: 0, y: 18)
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 4)

            Image(systemName: cartSymbol)
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(Color(red: 0.16, green: 0.44, blue: 0.20))
                .rotationEffect(.degrees(5))
                .offset(x: 0, y: 19)
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.36, green: 0.66, blue: 0.18), Color(red: 0.20, green: 0.46, blue: 0.12)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 32, height: 38)
                    .shadow(color: Color.black.opacity(0.18), radius: 4, x: 0, y: 2)

                Text("%")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            .rotationEffect(.degrees(-24))
            .offset(x: 26, y: 8)
        }
    }
}
