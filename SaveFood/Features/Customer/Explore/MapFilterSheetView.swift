//
//  MapDisplayMode.swift
//  SaveFood
//
//  Created by bekarys abiev on 15.11.2026.
//
import SwiftUI
import MapKit
enum MapDisplayMode: String, CaseIterable {
    case map = "Карта"
    case list = "Список"

    var icon: String {
        switch self {
        case .map: return "map"
        case .list: return "list.bullet"
        }
    }
}
struct MapFilterCategoryItem: Identifiable {
    let id: String
    let title: String
    let emoji: String?
    let systemIcon: String?
}
struct MapFilterSheetView: View {
    @Bindable var viewModel: ExploreViewModel
    var onClose: () -> Void
    var onShowOnMap: () -> Void
    private let primaryGreen = Color(red: 0.08, green: 0.31, blue: 0.15)
    private let sheetBackground = Color(red: 0.973, green: 0.976, blue: 0.953)
    private let softSageBg = Color(red: 0.914, green: 0.937, blue: 0.886)
    private let selectedCardBg = Color(red: 0.855, green: 0.914, blue: 0.824)
    private let unselectedCardBg = Color(red: 0.929, green: 0.945, blue: 0.910)
    private let distanceOptions: [Int] = [1, 3, 5, 10]
    private let mapCategories: [MapFilterCategoryItem] = [
        MapFilterCategoryItem(id: "Овощи", title: "Овощи", emoji: "🥦", systemIcon: nil),
        MapFilterCategoryItem(id: "Фрукты", title: "Фрукты", emoji: "🍎", systemIcon: nil),
        MapFilterCategoryItem(id: "Выпечка", title: "Выпечка", emoji: "🥐", systemIcon: nil),
        MapFilterCategoryItem(id: "Молочные", title: "Молочные", emoji: "🥛", systemIcon: nil),
        MapFilterCategoryItem(id: "Все", title: "Все", emoji: nil, systemIcon: "square.grid.2x2")
    ]
    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(red: 0.72, green: 0.75, blue: 0.71))
                .frame(width: 44, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 14)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // MARK: - 1.
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(softSageBg)
                                .frame(width: 42, height: 42)

                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(primaryGreen)
                        }

                        Text("Карта")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(primaryGreen)

                        Spacer()

                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(primaryGreen)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(softSageBg)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)

                    // MARK: - 2.
                    HStack(spacing: 0) {
                        ForEach(MapDisplayMode.allCases, id: \.self) { mode in
                            let isSelected = (viewModel.mapDisplayMode == mode)

                            Button {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                    viewModel.mapDisplayMode = mode
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 15, weight: .semibold))

                                    Text(mode.rawValue)
                                        .font(.system(size: 15.5, weight: .semibold, design: .rounded))
                                }
                                .foregroundStyle(isSelected ? .white : primaryGreen)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? primaryGreen : Color.clear)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(4)
                    .background(
                        Capsule()
                            .fill(softSageBg)
                    )
                    .padding(.horizontal, 20)
                    // MARK: - 3. "Рядом с вами" (1 км, 3 км, 5 км, 10 км)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Рядом с вами")
                                .font(.system(size: 19, weight: .bold, design: .rounded))
                                .foregroundStyle(primaryGreen)
                            Spacer()
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    viewModel.selectedDistanceKm = 1
                                }
                            } label: {
                                Image(systemName: "location")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(primaryGreen)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(softSageBg)
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        HStack(spacing: 10) {
                            ForEach(distanceOptions, id: \.self) { km in
                                let isSelected = (viewModel.selectedDistanceKm == km)
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        viewModel.selectedDistanceKm = km
                                    }
                                } label: {
                                    Text("\(km) км")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(isSelected ? .white : primaryGreen)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 42)
                                        .background(
                                            Capsule()
                                                .fill(isSelected ? primaryGreen : softSageBg)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // MARK: - 4. "Категории" (Овощи, Фрукты, Выпечка, Молочные, Все)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Категории")
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundStyle(primaryGreen)
                            .padding(.horizontal, 20)
                        HStack(spacing: 8) {
                            ForEach(mapCategories) { item in
                                let isSelected = (viewModel.mapSelectedCategory == item.id)
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        viewModel.mapSelectedCategory = item.id
                                    }
                                } label: {
                                    VStack(spacing: 6) {
                                        if let emoji = item.emoji {
                                            Text(emoji)
                                                .font(.system(size: 30))
                                        } else if let sysIcon = item.systemIcon {
                                            Image(systemName: sysIcon)
                                                .font(.system(size: 24, weight: .medium))
                                                .foregroundStyle(primaryGreen)
                                                .frame(height: 34)
                                        }
                                        Text(item.title)
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundStyle(primaryGreen)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 78)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(isSelected ? selectedCardBg : unselectedCardBg)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(isSelected ? primaryGreen : Color.clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Скидка")
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundStyle(primaryGreen)
                        HStack(spacing: 14) {
                            DiscountCustomSlider(
                                value: $viewModel.minDiscountPercent,
                                range: 5...70,
                                step: 5,
                                primaryGreen: primaryGreen,
                                trackBg: softSageBg
                            )
                            .frame(height: 34)
                            Text("от \(Int(viewModel.minDiscountPercent))%")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(primaryGreen)
                                .padding(.horizontal, 14)
                                .frame(height: 38)
                                .background(
                                    Capsule()
                                        .fill(softSageBg)
                                )
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                    .padding(.horizontal, 20)
                    // MARK: - 6. "Только доступные"
                    HStack(spacing: 12) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(primaryGreen)
                            .frame(width: 28)
                        Text("Только доступные")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(primaryGreen)
                        Spacer()
                        Toggle("", isOn: $viewModel.onlyAvailableOffers)
                            .labelsHidden()
                            .tint(primaryGreen)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(unselectedCardBg)
                    )
                    .padding(.horizontal, 20)
                    // MARK: - 7. "Показать на карте ->"
                    Button(action: onShowOnMap) {
                        HStack(spacing: 10) {
                            Text(viewModel.mapDisplayMode == .map ? "Показать на карте" : "Показать список")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))

                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            Capsule()
                                .fill(primaryGreen)
                        )
                        .shadow(color: primaryGreen.opacity(0.24), radius: 10, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(sheetBackground.ignoresSafeArea())
    }
}
// MARK: - Скидка
private struct DiscountCustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let primaryGreen: Color
    let trackBg: Color
    var body: some View {
        GeometryReader { geo in
            let width = max(1, geo.size.width)
            let thumbDiameter: CGFloat = 26
            let usableWidth = max(1, width - thumbDiameter)
            let progress = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
            let clampedProgress = min(1, max(0, progress))
            let thumbOffsetX = clampedProgress * usableWidth
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackBg)
                    .frame(height: 6)
                Capsule()
                    .fill(primaryGreen)
                    .frame(width: thumbOffsetX + (thumbDiameter * 0.5), height: 6)
                Circle()
                    .fill(Color(red: 0.97, green: 0.98, blue: 0.95))
                    .frame(width: thumbDiameter, height: thumbDiameter)
                    .overlay(
                        Circle()
                            .stroke(primaryGreen, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.10), radius: 3, x: 0, y: 2)
                    .offset(x: thumbOffsetX)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                let locationX = min(usableWidth, max(0, drag.location.x - (thumbDiameter * 0.5)))
                                let ratio = Double(locationX / usableWidth)
                                let rawValue = range.lowerBound + ratio * (range.upperBound - range.lowerBound)
                                let stepped = (rawValue / step).rounded() * step
                                value = min(range.upperBound, max(range.lowerBound, stepped))
                            }
                    )
            }
            .frame(maxHeight: .infinity)
        }
    }
}
