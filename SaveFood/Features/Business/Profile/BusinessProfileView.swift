
import SwiftUI
import PhotosUI
import UIKit

struct BusinessProfileView: View {

    @Bindable var viewModel: BusinessProfileViewModel
    var onSignOut: () -> Void

    @State private var photoPickerItem: PhotosPickerItem?

    private let primaryGreen = Color(red: 0.08, green: 0.30, blue: 0.15)
    private let creamBackground = Color(red: 0.965, green: 0.969, blue: 0.937)
    private let softSageCard = Color(red: 0.915, green: 0.938, blue: 0.892)

    var body: some View {
        NavigationStack {
            ZStack {
                creamBackground.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // Карточка аккаунта продавца
                        HStack(spacing: 14) {
                            Image(systemName: "storefront.circle.fill")
                                .font(.system(size: 46))
                                .foregroundStyle(primaryGreen)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.seller.fullName)
                                    .font(.system(size: 19, weight: .bold, design: .rounded))
                                    .foregroundStyle(primaryGreen)
                                Text(viewModel.seller.email)
                                    .font(.system(size: 13.5, design: .rounded))
                                    .foregroundStyle(.secondary)
                                Text("Роль: Продавец")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(primaryGreen)
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 22).fill(softSageCard))

                        // Фото заведения
                        ZStack(alignment: .bottomTrailing) {
                            if let selectedImage = viewModel.selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 185)
                                    .clipShape(RoundedRectangle(cornerRadius: 22))
                            } else if !viewModel.existingPhotoUrl.isEmpty {
                                RemoteCachedImageView(urlString: viewModel.existingPhotoUrl, placeholderIcon: "storefront")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 185)
                                    .clipShape(RoundedRectangle(cornerRadius: 22))
                            } else {
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(softSageCard)
                                    .frame(height: 185)
                                    .overlay {
                                        VStack(spacing: 8) {
                                            Image(systemName: "camera.badge.ellipsis")
                                                .font(.system(size: 32))
                                                .foregroundStyle(primaryGreen.opacity(0.6))
                                            Text("Выберите фото заведения")
                                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                            }

                            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                                Label("Фото", systemImage: "photo.fill")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(Color.black.opacity(0.62)))
                            }
                            .padding(12)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Название заведения")
                                .font(.system(size: 14.5, weight: .bold, design: .rounded))
                                .foregroundStyle(primaryGreen)

                            TextField("Например: Green Market", text: $viewModel.venueName)
                                .padding(.horizontal, 14)
                                .frame(height: 48)
                                .background(RoundedRectangle(cornerRadius: 16).fill(softSageCard))

                            Text("Адрес заведения")
                                .font(.system(size: 14.5, weight: .bold, design: .rounded))
                                .foregroundStyle(primaryGreen)
                                .padding(.top, 4)

                            TextField("Например: Алматы, пр. Абая 44", text: $viewModel.venueAddress)
                                .padding(.horizontal, 14)
                                .frame(height: 48)
                                .background(RoundedRectangle(cornerRadius: 16).fill(softSageCard))
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.system(size: 13.5, weight: .medium, design: .rounded))
                                .foregroundStyle(.red)
                        }

                        if let status = viewModel.statusMessage {
                            Text(status)
                                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                                .foregroundStyle(primaryGreen)
                        }

                        Button {
                            Task { await viewModel.saveVenueProfile() }
                        } label: {
                            HStack(spacing: 8) {
                                if viewModel.isSaving {
                                    ProgressView().tint(.white)
                                }
                                Text(viewModel.isSaving ? "Сохраняем..." : "Сохранить заведение")
                                    .font(.system(size: 16.5, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Capsule().fill(primaryGreen))
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isSaving)

                        Button(role: .destructive, action: onSignOut) {
                            Label("Выйти из аккаунта", systemImage: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color.red.opacity(0.10))
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Заведение")
            .task {
                if viewModel.state == .idle {
                    await viewModel.loadVenue()
                }
            }
            .onChange(of: photoPickerItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            viewModel.selectedImage = image
                        }
                    }
                }
            }
        }
    }
}
