import SwiftUI
struct SlidingFilterBarView: View {
    let visibleCategories: [String]
    let selectedCategory: String?
    var onSelectCategory: (String) -> Void
    var onClearCategory: () -> Void
    private let primaryGreen = Color(red: 0.08, green: 0.30, blue: 0.15)
    private let softSageChip = Color(red: 0.905, green: 0.932, blue: 0.880)
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(visibleCategories, id: \.self) { category in
                        let isSelected = (selectedCategory == category)
                        Button {
                            onSelectCategory(category)
                        } label: {
                            HStack(spacing: 6) {
                                if isSelected {
                                    Image(systemName: "cart.fill")
                                        .font(.system(size: 12, weight: .semibold))
                                        .transition(.scale.combined(with: .opacity))
                                }
                                Text(category)
                                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium, design: .rounded))
                            }
                            .foregroundStyle(isSelected ? .white : primaryGreen)
                            .padding(.horizontal, 16)
                            .frame(height: 38)
                            .background(
                                Capsule()
                                    .fill(isSelected ? primaryGreen : softSageChip)
                            )
                        }
                        .buttonStyle(.plain)
                        .id(category)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            )
                        )
                    }
                    if selectedCategory != nil {
                        Button(action: onClearCategory) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(primaryGreen)
                                .padding(.horizontal, 6)
                                .frame(height: 38)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .animation(.spring(response: 0.38, dampingFraction: 0.85), value: selectedCategory)
            }
            .onChange(of: selectedCategory) { _, newValue in
                if let newValue {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.85)) {
                        proxy.scrollTo(newValue, anchor: .leading)
                    }
                }
            }
        }
    }
}
