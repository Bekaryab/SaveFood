
import SwiftUI
import PhotosUI
import UIKit

struct EditOfferView: View {

    @Bindable var viewModel: OfferManagementViewModel
    let offer: FoodOffer

    @Environment(\.dismiss) private var dismiss

    @State private var replacementImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?

    @State private var title: String
    @State private var category: String
    @State private var oldPriceText: String
    @State private var newPriceText: String
    @State private var quantity: Int
    @State private var isAvailable: Bool
    @State private var producedAt: Date
    @State private var expiresAt: Date
    @State private var pickupUntil: Date
    @State private var reason: String
    @State private var descriptionText: String

    private let primaryGreen = Color(red: 0.08, green: 0.30, blue: 0.15)
    private let creamBackground = Color(red: 0.965, green: 0.969, blue: 0.937)
    private let softSageCard = Color(red: 0.915, green: 0.938, blue: 0.892)

    init(viewModel: OfferManagementViewModel, offer: FoodOffer) {
        self.viewModel = viewModel
        self.offer = offer
        _title = State(initialValue: offer.title)
        _category = State(initialValue: offer.category)
        _oldPriceText = State(initialValue: String(format: "%.0f", offer.oldPrice))
        _newPriceText = State(initialValue: String(format: "%.0f", offer.newPrice))
        _quantity = State(initialValue: offer.quantity)
        _isAvailable = State(initialValue: offer.isAvailable)
        _producedAt = State(initialValue: offer.producedAt)
        _expiresAt = State(initialValue: offer.expiresAt)
        _pickupUntil = State(initialValue: offer.pickupUntil)
        _reason = State(initialValue: offer.reason)
        _descriptionText = State(initialValue: offer.description)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                creamBackground.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        ZStack(alignment: .bottomTrailing) {
                            if let replacementImage {
                                Image(uiImage: replacementImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 190)
                                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            } else {
                                RemoteCachedImageView(urlString: offer.photoUrl)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 190)
                                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            }

                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Label("Заменить фото", systemImage: "photo")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(Color.black.opacity(0.62)))
                            }
                            .padding(12)
                        }

                        if let error = viewModel.submitErrorMessage {
                            Text(error)
                                .font(.system(size: 13.5, weight: .medium, design: .rounded))
                                .foregroundStyle(.red)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.red.opacity(0.10)))
                        }

                        TextField("Название", text: $title)
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(RoundedRectangle(cornerRadius: 16).fill(softSageCard))

                        Picker("Категория", selection: $category) {
                            ForEach(FoodOffer.standardCategories, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(primaryGreen)
                        .padding(.horizontal, 14)
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 16).fill(softSageCard))

                        HStack(spacing: 12) {
                            TextField("Старая цена", text: $oldPriceText)
                                .keyboardType(.decimalPad)
                                .padding(.horizontal, 14)
                                .frame(height: 48)
                                .background(RoundedRectangle(cornerRadius: 16).fill(softSageCard))

                            TextField("Новая цена", text: $newPriceText)
                                .keyboardType(.decimalPad)
                                .padding(.horizontal, 14)
                                .frame(height: 48)
                                .background(RoundedRectangle(cornerRadius: 16).fill(softSageCard))
                        }

                        Stepper("Количество: \(quantity) шт", value: $quantity, in: 0...200)
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(RoundedRectangle(cornerRadius: 16).fill(softSageCard))
                            .onChange(of: quantity) { _, newValue in
                                if newValue == 0 {
                                    isAvailable = false
                                }
                            }

                        Toggle("Доступно для заказа", isOn: $isAvailable)
                            .disabled(quantity == 0)
                            .tint(primaryGreen)
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(RoundedRectangle(cornerRadius: 16).fill(softSageCard))

                        VStack(spacing: 10) {
                            DatePicker("Изготовлено / собрано", selection: $producedAt, displayedComponents: [.date])
                            Divider()
                            DatePicker("Годно до", selection: $expiresAt, in: producedAt..., displayedComponents: [.date])
                            Divider()
                            DatePicker("Самовывоз до", selection: $pickupUntil, displayedComponents: [.date, .hourAndMinute])
                        }
                        .tint(primaryGreen)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 16).fill(softSageCard))

                        TextField("Причина скидки", text: $reason)
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(RoundedRectangle(cornerRadius: 16).fill(softSageCard))

                        TextEditor(text: $descriptionText)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 90)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 16).fill(softSageCard))

                        Button {
                            Task {
                                _ = await viewModel.updateExistingOffer(
                                    original: offer,
                                    newImage: replacementImage,
                                    title: title,
                                    category: category,
                                    oldPriceText: oldPriceText,
                                    newPriceText: newPriceText,
                                    quantity: quantity,
                                    isAvailable: isAvailable,
                                    producedAt: producedAt,
                                    expiresAt: expiresAt,
                                    pickupUntil: pickupUntil,
                                    reason: reason,
                                    description: descriptionText
                                )
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if viewModel.isSubmitting {
                                    ProgressView().tint(.white)
                                }
                                Text(viewModel.isSubmitting ? "Сохраняем..." : "Сохранить изменения")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Capsule().fill(primaryGreen))
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isSubmitting)
                        .padding(.bottom, 20)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Закрыть") { dismiss() }
                        .foregroundStyle(primaryGreen)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run { replacementImage = image }
                    }
                }
            }
        }
    }
}
