import SwiftUI

struct MyOffersView: View {

    @Bindable var viewModel: OfferManagementViewModel

    private let primaryGreen = Color(red: 0.08, green: 0.30, blue: 0.15)
    private let creamBackground = Color(red: 0.965, green: 0.969, blue: 0.937)
    private let softSageCard = Color(red: 0.915, green: 0.938, blue: 0.892)
    private let badgeGreen = Color(red: 0.22, green: 0.49, blue: 0.18)

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                creamBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.availableCategoryTabs, id: \.self) { category in
                                let isSelected = (viewModel.selectedCategoryFilter == category)
                                Button {
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                                        viewModel.selectedCategoryFilter = category
                                    }
                                } label: {
                                    Text(category)
                                        .font(.system(size: 14.5, weight: isSelected ? .bold : .medium, design: .rounded))
                                        .foregroundStyle(isSelected ? .white : primaryGreen)
                                        .padding(.horizontal, 16)
                                        .frame(height: 36)
                                        .background(
                                            Capsule()
                                                .fill(isSelected ? primaryGreen : softSageCard)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }

                    if let banner = viewModel.successBannerMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text(banner)
                                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                            Spacer()
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 14).fill(badgeGreen))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    contentView
                }
            }
            .navigationTitle("Мои товары")
            .searchable(text: $viewModel.searchText, prompt: "Поиск среди моих товаров")
            .sheet(item: $viewModel.offerToEdit) { offer in
                EditOfferView(viewModel: viewModel, offer: offer)
            }
            .task {
                if viewModel.state == .idle {
                    await viewModel.loadSellerData()
                }
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle, .loading:
            VStack(spacing: 12) {
                ProgressView()
                    .tint(primaryGreen)
                Text("Загружаем ваши товары...")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .error(let message):
            VStack(spacing: 14) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 42))
                    .foregroundStyle(.red.opacity(0.75))

                Text(message)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button("Повторить") {
                    Task { await viewModel.loadSellerData() }
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .frame(height: 44)
                .background(Capsule().fill(primaryGreen))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .empty:
            emptySellerView

        case .loaded:
            if viewModel.filteredOffers.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundStyle(primaryGreen.opacity(0.45))

                    Text("В разделе «\(viewModel.selectedCategoryFilter)» пока нет товаров")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(primaryGreen)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)

                    Button {
                        viewModel.startQuickCameraFlow()
                    } label: {
                        Label("Снять и добавить товар", systemImage: "camera.fill")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .frame(height: 46)
                            .background(Capsule().fill(primaryGreen))
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.filteredOffers) { offer in
                        SellerOfferRowCard(
                            offer: offer,
                            primaryGreen: primaryGreen,
                            badgeGreen: badgeGreen,
                            onIncrement: {
                                Task { await viewModel.updateQuantity(for: offer, delta: 1) }
                            },
                            onDecrement: {
                                Task { await viewModel.updateQuantity(for: offer, delta: -1) }
                            },
                            onToggleAvailability: {
                                Task { await viewModel.toggleAvailability(for: offer) }
                            },
                            onEdit: {
                                viewModel.offerToEdit = offer
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await viewModel.deleteOffer(offer) }
                            } label: {
                                Label("Удалить", systemImage: "trash.fill")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable {
                    await viewModel.loadSellerData()
                }
            }
        }
    }

    private var emptySellerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 54))
                .foregroundStyle(primaryGreen.opacity(0.55))

            Text("У вас пока нет товаров")
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .foregroundStyle(primaryGreen)

            Text("Нажмите «+» на нижней панели, чтобы сразу сфотографировать продукт и добавить его в SaveFood.")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Button {
                viewModel.startQuickCameraFlow()
            } label: {
                Label("Добавить первый товар", systemImage: "plus.circle.fill")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 50)
                    .background(Capsule().fill(primaryGreen))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct SellerOfferRowCard: View {

    let offer: FoodOffer
    let primaryGreen: Color
    let badgeGreen: Color
    var onIncrement: () -> Void
    var onDecrement: () -> Void
    var onToggleAvailability: () -> Void
    var onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                RemoteCachedImageView(urlString: offer.photoUrl)
                    .frame(width: 82, height: 82)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(offer.category)
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .foregroundStyle(primaryGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(primaryGreen.opacity(0.12)))

                        Text("-\(offer.discountPercent)%")
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(badgeGreen))

                        Spacer()

                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(primaryGreen)
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(Color.white.opacity(0.7)))
                        }
                        .buttonStyle(.plain)
                    }

                    Text(offer.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(primaryGreen)
                        .lineLimit(1)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(offer.formattedNewPrice)
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(primaryGreen)

                        Text(offer.formattedOldPrice)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.secondary)
                            .strikethrough()
                    }
                }
            }

            if !offer.description.isEmpty {
                Text(offer.description)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Divider().opacity(0.35)

            HStack {
                Button(action: onToggleAvailability) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(offer.isAvailable ? badgeGreen : Color.orange)
                            .frame(width: 8, height: 8)

                        Text(offer.status.displayTitle)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(offer.isAvailable ? primaryGreen : .orange)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.75)))
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 12) {
                    Button(action: onDecrement) {
                        Image(systemName: "minus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(primaryGreen)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.white.opacity(0.85)))
                    }
                    .buttonStyle(.plain)

                    Text("\(offer.quantity) шт")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(primaryGreen)
                        .frame(minWidth: 38)

                    Button(action: onIncrement) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(primaryGreen)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.white.opacity(0.85)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.935, green: 0.952, blue: 0.908))
        )
    }
}
