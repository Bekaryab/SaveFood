import SwiftUI
struct OfferDetailsView: View {
    @State private var viewModel: OfferDetailsViewModel
    var onToggleFavorite: () -> Void
    var onAddToCart: (HomeProductOffer, Int) -> Void
    var onClose: () -> Void
    private let primaryGreen = Color(red: 0.08, green: 0.31, blue: 0.15)
    private let creamBackground = Color(red: 0.965, green: 0.969, blue: 0.937)
    private let cardSageBg = Color(red: 0.922, green: 0.937, blue: 0.898)
    private let badgeGreen = Color(red: 0.22, green: 0.49, blue: 0.18)
    init(
        offer: HomeProductOffer,
        onToggleFavorite: @escaping () -> Void,
        onAddToCart: @escaping (HomeProductOffer, Int) -> Void,
        onClose: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: OfferDetailsViewModel(offer: offer))
        self.onToggleFavorite = onToggleFavorite
        self.onAddToCart = onAddToCart
        self.onClose = onClose
    }
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                creamBackground
                    .ignoresSafeArea()
                VStack(spacing: 0) {
                    ZStack(alignment: .top) {
                        SmartCachedProductImage(
                            localImageName: viewModel.offer.localImageName,
                            imageURL: viewModel.offer.imageURL,
                            fallbackSymbol: viewModel.offer.fallbackSymbol,
                            accentColor: viewModel.offer.accentColor
                        )
                        .frame(width: geo.size.width, height: 265)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.28),
                                    Color.clear,
                                    Color.black.opacity(0.12)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        Capsule()
                            .fill(Color.white.opacity(0.92))
                            .frame(width: 46, height: 5)
                            .padding(.top, 10)
                        HStack {
                            Button(action: onClose) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(primaryGreen)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                                            .fill(creamBackground.opacity(0.92))
                                    )
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            HStack(spacing: 10) {
                                Button {
                                    viewModel.offer.isFavorite.toggle()
                                    onToggleFavorite()
                                } label: {
                                    Image(systemName: viewModel.offer.isFavorite ? "heart.fill" : "heart")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(viewModel.offer.isFavorite ? Color.red : primaryGreen)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(creamBackground.opacity(0.92))
                                        )
                                }
                                .buttonStyle(.plain)
                                ShareLink(
                                    item: "\(viewModel.offer.title) со скидкой -\(viewModel.offer.discountPercent)% за \(viewModel.offer.currentPrice) в SaveFood!"
                                ) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(primaryGreen)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(creamBackground.opacity(0.92))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    }
                    .frame(width: geo.size.width, height: 265)
                    VStack(alignment: .leading, spacing: 0) {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 18) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(viewModel.offer.venueName)
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundStyle(Color(red: 0.38, green: 0.46, blue: 0.39))
                                    HStack(alignment: .center, spacing: 12) {
                                        Text(viewModel.offer.title)
                                            .font(.system(size: 29, weight: .heavy, design: .rounded))
                                            .foregroundStyle(primaryGreen)
                                            .lineLimit(2)
                                            .minimumScaleFactor(0.8)
                                        Text("-\(viewModel.offer.discountPercent)%")
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                            .background(
                                                Capsule()
                                                    .fill(badgeGreen)
                                            )
                                    }
                                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                                        Text(viewModel.offer.currentPrice)
                                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                                            .foregroundStyle(primaryGreen)
                                        Text(viewModel.offer.oldPrice)
                                            .font(.system(size: 20, weight: .medium, design: .rounded))
                                            .foregroundStyle(Color(red: 0.50, green: 0.54, blue: 0.49))
                                            .strikethrough(true, color: Color(red: 0.50, green: 0.54, blue: 0.49))
                                    }
                                    .padding(.top, 2)
                                }
                                HStack(spacing: 0) {
                                    infoColumn(
                                        icon: "calendar",
                                        label: "Изготовлено",
                                        value: viewModel.offer.producedDate
                                    )
                                    Rectangle()
                                        .fill(primaryGreen.opacity(0.12))
                                        .frame(width: 1, height: 52)
                                    infoColumn(
                                        icon: "hourglass",
                                        label: "Годно до",
                                        value: viewModel.offer.expiryDate
                                    )
                                    Rectangle()
                                        .fill(primaryGreen.opacity(0.12))
                                        .frame(width: 1, height: 52)
                                    infoColumn(
                                        icon: "bag.fill",
                                        label: "Причина",
                                        value: viewModel.offer.reason
                                    )
                                }
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(cardSageBg)
                                )
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Описание")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundStyle(primaryGreen)
                                    Text(viewModel.offer.descriptionText)
                                        .font(.system(size: 16, weight: .regular, design: .rounded))
                                        .foregroundStyle(Color(red: 0.32, green: 0.38, blue: 0.33))
                                        .lineSpacing(3)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.top, 2)
                                HStack {
                                    Spacer()
                                    HStack(spacing: 28) {
                                        Button {
                                            viewModel.decrementQuantity()
                                        } label: {
                                            Image(systemName: "minus")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundStyle(primaryGreen)
                                                .frame(width: 40, height: 40)
                                                .background(
                                                    Circle()
                                                        .fill(Color(red: 0.885, green: 0.906, blue: 0.859))
                                                )
                                        }
                                        .buttonStyle(.plain)
                                        Text("\(viewModel.quantity)")
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .foregroundStyle(primaryGreen)
                                            .frame(minWidth: 26)
                                            .contentTransition(.numericText())
                                        Button {
                                            viewModel.incrementQuantity()
                                        } label: {
                                            Image(systemName: "plus")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundStyle(primaryGreen)
                                                .frame(width: 40, height: 40)
                                                .background(
                                                    Circle()
                                                        .fill(Color(red: 0.885, green: 0.906, blue: 0.859))
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 12)
                                    .frame(height: 56)
                                    .background(
                                        Capsule()
                                            .fill(cardSageBg)
                                    )
                                    Spacer()
                                }
                                .padding(.top, 4)
                                Button {
                                    onAddToCart(viewModel.offer, viewModel.quantity)
                                } label: {
                                    HStack {
                                        HStack(spacing: 12) {
                                            Image(systemName: "cart")
                                                .font(.system(size: 20, weight: .semibold))
                                            Text("В корзину")
                                                .font(.system(size: 19, weight: .bold, design: .rounded))
                                        }
                                        Spacer()
                                        Text(viewModel.formattedTotalPrice)
                                            .font(.system(size: 19, weight: .bold, design: .rounded))
                                            .contentTransition(.numericText())
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 26)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
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
                                    .shadow(color: primaryGreen.opacity(0.24), radius: 10, x: 0, y: 5)
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 4)
                                .padding(.bottom, 24)
                            }
                            .padding(.horizontal, 22)
                            .padding(.top, 24)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 30,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 30,
                            style: .continuous
                        )
                        .fill(creamBackground)
                        .shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: -4)
                    )
                    .offset(y: -26)
                    .padding(.bottom, -26)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
    }
    private func infoColumn(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(primaryGreen)
                .frame(height: 24)
            Text(label)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Color(red: 0.36, green: 0.44, blue: 0.37))
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(primaryGreen)
        }
        .frame(maxWidth: .infinity)
    }
}
