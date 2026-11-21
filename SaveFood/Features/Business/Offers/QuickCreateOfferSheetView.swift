import SwiftUI
import PhotosUI
import UIKit

struct QuickCreateOfferSheetView: View {

    @Bindable var viewModel: OfferManagementViewModel
    let initialImage: UIImage
    var onRetakePhoto: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var productImage: UIImage
    @State private var selectedPhotoItem: PhotosPickerItem?

    @State private var title: String = ""
    @State private var category: String = FoodOffer.standardCategories.first ?? "Фрукты"
    @State private var oldPriceText: String = ""
    @State private var newPriceText: String = ""
    @State private var quantity: Int = 5
    @State private var producedAt: Date = Date()
    @State private var expiresAt: Date = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date().addingTimeInterval(172800)
    @State private var pickupUntil: Date = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date().addingTimeInterval(21600)
    @State private var reason: String = FoodOffer.standardReasons.first ?? "Излишки"
    @State private var descriptionText: String = ""
    @State private var selectedVenueId: String?

    private let primaryGreen = Color(red: 0.08, green: 0.30, blue: 0.15)
    private let creamBackground = Color(red: 0.965, green: 0.969, blue: 0.937)
    private let softSageCard = Color(red: 0.915, green: 0.938, blue: 0.892)
    private let badgeGreen = Color(red: 0.22, green: 0.49, blue: 0.18)

    init(
        viewModel: OfferManagementViewModel,
        initialImage: UIImage,
        onRetakePhoto: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.initialImage = initialImage
        self.onRetakePhoto = onRetakePhoto
        _productImage = State(initialValue: initialImage)
        _selectedVenueId = State(initialValue: viewModel.primaryVenue?.id)
    }

    private var parsedOldPrice: Double {
        Double(oldPriceText.replacingOccurrences(of: ",", with: ".").replacingOccurrences(of: " ", with: "")) ?? 0
    }

    private var parsedNewPrice: Double {
        Double(newPriceText.replacingOccurrences(of: ",", with: ".").replacingOccurrences(of: " ", with: "")) ?? 0
    }

    private var calculatedDiscount: Int {
        PriceCalculator.discountPercent(oldPrice: parsedOldPrice, newPrice: parsedNewPrice)
    }

    private var producedDateTitle: String {
        let lower = category.lowercased()
        return (lower.contains("фрукт") || lower.contains("овощ"))
            ? "Дата сбора / упаковки"
            : "Дата изготовления"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                creamBackground.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {

                        photoPreviewCard

                        if let error = viewModel.submitErrorMessage {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.system(size: 13.5, weight: .medium, design: .rounded))
                                    .foregroundStyle(.red)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.red.opacity(0.10))
                            )
                        }

                        if viewModel.venues.count > 1 {
                            VStack(alignment: .leading, spacing: 8) {
                                sectionLabel("Заведение")
                                Picker("Заведение", selection: $selectedVenueId) {
                                    ForEach(viewModel.venues) { venue in
                                        Text(venue.name).tag(Optional(venue.id))
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(primaryGreen)
                                .padding(.horizontal, 14)
                                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 16).fill(softSageCard))
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Название продукта")
                            TextField("Например: Томаты Черри или Круассан", text: $title)
                                .font(.system(size: 16, design: .rounded))
                                .padding(.horizontal, 14)
                                .frame(height: 50)
                                .background(RoundedRectangle(cornerRadius: 16).fill(softSageCard))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Раздел (категория)")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(FoodOffer.standardCategories, id: \.self) { item in
                                        let isSelected = (category == item)
                                        Button {
                                            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                                category = item
                                            }
                                        } label: {
                                            Text(item)
                                                .font(.system(size: 14.5, weight: isSelected ? .bold : .medium, design: .rounded))
                                                .foregroundStyle(isSelected ? .white : primaryGreen)
                                                .padding(.horizontal, 16)
                                                .frame(height: 38)
                                                .background(
                                                    Capsule()
                                                        .fill(isSelected ? primaryGreen : softSageCard)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                sectionLabel("Цены (₸)")
                                Spacer()
                                if calculatedDiscount > 0 {
                                    Text("Скидка -\(calculatedDiscount)%")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(badgeGreen))
                                }
                            }

                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Старая цена")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundStyle(.secondary)

                                    TextField("990", text: $oldPriceText)
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                                        .padding(.horizontal, 14)
                                        .frame(height: 48)
                                        .background(RoundedRectangle(cornerRadius: 16).fill(softSageCard))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Новая цена")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundStyle(.secondary)

                                    TextField("640", text: $newPriceText)
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundStyle(primaryGreen)
                                        .padding(.horizontal, 14)
                                        .frame(height: 48)
                                        .background(RoundedRectangle(cornerRadius: 16).fill(softSageCard))
                                }
                            }
                        }

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                sectionLabel("Количество (шт)")
                                Text("При достижении 0 товар скроется автоматически")
                                    .font(.system(size: 11.5, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            HStack(spacing: 16) {
                                Button {
                                    if quantity > 1 { quantity -= 1 }
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(primaryGreen)
                                        .frame(width: 34, height: 34)
                                        .background(Circle().fill(creamBackground))
                                }
                                .buttonStyle(.plain)

                                Text("\(quantity)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(primaryGreen)
                                    .frame(minWidth: 24)

                                Button {
                                    if quantity < 200 { quantity += 1 }
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(primaryGreen)
                                        .frame(width: 34, height: 34)
                                        .background(Circle().fill(creamBackground))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(softSageCard))
                        }

                        VStack(spacing: 10) {
                            DatePicker(producedDateTitle, selection: $producedAt, displayedComponents: [.date])
                            Divider()
                            DatePicker("Годно до", selection: $expiresAt, in: producedAt..., displayedComponents: [.date])
                            Divider()
                            DatePicker("Самовывоз до", selection: $pickupUntil, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        }
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .tint(primaryGreen)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 18).fill(softSageCard))

                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Причина скидки")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(FoodOffer.standardReasons, id: \.self) { item in
                                        let isSelected = (reason == item)
                                        Button {
                                            reason = item
                                        } label: {
                                            Text(item)
                                                .font(.system(size: 13.5, weight: isSelected ? .semibold : .medium, design: .rounded))
                                                .foregroundStyle(isSelected ? .white : primaryGreen)
                                                .padding(.horizontal, 14)
                                                .frame(height: 36)
                                                .background(
                                                    Capsule()
                                                        .fill(isSelected ? primaryGreen : softSageCard)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Описание и содержание")
                            TextEditor(text: $descriptionText)
                                .font(.system(size: 15, design: .rounded))
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 96)
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 16).fill(softSageCard))
                        }

                        Button {
                            Task {
                                _ = await viewModel.publishOffer(
                                    image: productImage,
                                    title: title,
                                    category: category,
                                    oldPriceText: oldPriceText,
                                    newPriceText: newPriceText,
                                    quantity: quantity,
                                    producedAt: producedAt,
                                    expiresAt: expiresAt,
                                    pickupUntil: pickupUntil,
                                    reason: reason,
                                    description: descriptionText,
                                    selectedVenueId: selectedVenueId
                                )
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if viewModel.isSubmitting {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Публикуем...")
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 19, weight: .semibold))
                                    Text("Сохранить и опубликовать")
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                Capsule()
                                    .fill(viewModel.isSubmitting ? primaryGreen.opacity(0.65) : primaryGreen)
                            )
                            .shadow(color: primaryGreen.opacity(0.22), radius: 10, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isSubmitting)
                        .padding(.top, 4)
                        .padding(.bottom, 24)
                    }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Новый товар")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundStyle(primaryGreen)
                    .disabled(viewModel.isSubmitting)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            productImage = image
                        }
                    }
                }
            }
        }
    }

    private var photoPreviewCard: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(uiImage: productImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 210)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            HStack(spacing: 8) {
                Button {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onRetakePhoto()
                    }
                } label: {
                    Label("Переснять", systemImage: "camera.fill")
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.black.opacity(0.62)))
                }
                .buttonStyle(.plain)

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Галерея", systemImage: "photo")
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.black.opacity(0.62)))
                }
            }
            .padding(12)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(primaryGreen)
    }
}
