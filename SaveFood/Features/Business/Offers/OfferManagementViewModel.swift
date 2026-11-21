import SwiftUI
import UIKit
import Observation

@Observable
@MainActor
final class OfferManagementViewModel {

    let seller: User

    private let offerRepository: OfferRepository
    private let profileRepository: ProfileRepository
    private let imageUploadService: ImageUploading

    var state: ViewState = .idle
    var offers: [FoodOffer] = []
    var venues: [Venue] = []

    var selectedCategoryFilter: String = "Все"
    var searchText: String = ""

    var isCameraPresented = false
    var isCreateSheetPresented = false
    var pendingCapturedImage: UIImage?
    var activeCapturedImage: UIImage?

    var offerToEdit: FoodOffer?

    var isSubmitting = false
    var submitErrorMessage: String?
    var successBannerMessage: String?

    var availableCategoryTabs: [String] {
        ["Все"] + FoodOffer.standardCategories
    }

    var primaryVenue: Venue? {
        venues.first
    }

    var filteredOffers: [FoodOffer] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return offers.filter { offer in
            let matchesCategory = (selectedCategoryFilter == "Все") || (offer.category == selectedCategoryFilter)
            let matchesQuery = query.isEmpty
                || offer.title.localizedCaseInsensitiveContains(query)
                || offer.category.localizedCaseInsensitiveContains(query)
                || offer.description.localizedCaseInsensitiveContains(query)
            return matchesCategory && matchesQuery
        }
    }

    init(
        seller: User,
        offerRepository: OfferRepository,
        profileRepository: ProfileRepository,
        imageUploadService: ImageUploading
    ) {
        self.seller = seller
        self.offerRepository = offerRepository
        self.profileRepository = profileRepository
        self.imageUploadService = imageUploadService
    }

    func loadSellerData() async {
        guard seller.role == .seller else {
            state = .error("Доступ разрешён только продавцам.")
            return
        }

        if offers.isEmpty {
            state = .loading
        }

        do {
            async let fetchedOffers = offerRepository.fetchOffers(forSellerUid: seller.uid)
            async let fetchedVenues = profileRepository.fetchVenues(forOwnerUid: seller.uid)

            let (loadedOffers, loadedVenues) = try await (fetchedOffers, fetchedVenues)
            offers = loadedOffers
            venues = loadedVenues
            state = loadedOffers.isEmpty ? .empty : .loaded
        } catch {
            state = .error("Не удалось загрузить ваши товары: \(error.localizedDescription)")
        }
    }

    func startQuickCameraFlow() {
        guard seller.role == .seller else { return }
        submitErrorMessage = nil
        pendingCapturedImage = nil
        isCameraPresented = true
    }

    func handlePhotoCaptured(_ image: UIImage) {
        pendingCapturedImage = image
        isCameraPresented = false
    }

    func handleCameraDismissed() {
        guard let image = pendingCapturedImage else { return }
        pendingCapturedImage = nil
        activeCapturedImage = image
        submitErrorMessage = nil
        isCreateSheetPresented = true
    }

    func publishOffer(
        image: UIImage,
        title: String,
        category: String,
        oldPriceText: String,
        newPriceText: String,
        quantity: Int,
        producedAt: Date,
        expiresAt: Date,
        pickupUntil: Date,
        reason: String,
        description: String,
        selectedVenueId: String?
    ) async -> Bool {
        guard seller.role == .seller else {
            submitErrorMessage = "Публиковать товары может только продавец."
            return false
        }
        guard !isSubmitting else { return false }

        let oldPrice = Self.parsePrice(oldPriceText)
        let newPrice = Self.parsePrice(newPriceText)
        let normalizedExpiresAt = Self.endOfDay(for: expiresAt)

        do {
            try Validators.validateOffer(
                title: title,
                category: category,
                oldPrice: oldPrice,
                newPrice: newPrice,
                quantity: quantity,
                photoUrl: "https://placeholder.savefood.local/check.jpg",
                producedAt: producedAt,
                expiresAt: normalizedExpiresAt,
                pickupUntil: pickupUntil,
                requirePositiveQuantity: true
            )
        } catch {
            submitErrorMessage = error.localizedDescription
            return false
        }

        isSubmitting = true
        submitErrorMessage = nil
        defer { isSubmitting = false }

        do {

            async let uploadedPhotoTask = imageUploadService.uploadPhoto(image)
            async let venuesFetchTask: [Venue] = venues.isEmpty
                ? (try await profileRepository.fetchVenues(forOwnerUid: seller.uid))
                : venues

            let (uploadedPhotoUrl, loadedVenues) = try await (uploadedPhotoTask, venuesFetchTask)
            if !loadedVenues.isEmpty {
                venues = loadedVenues
            }

            // Түсірілген фотоны жадыға сақтаймыз — карточкада лезде көрінеді
            RemoteImageMemoryCache.shared.store(image, for: uploadedPhotoUrl)
            ProductImageMemoryCache.shared.insert(image, for: uploadedPhotoUrl)

            // 2. Мекемені анықтау (немесе алғашқы рет болса автоматты құру)
            let venue = try await resolveOrCreateVenue(
                selectedVenueId: selectedVenueId,
                fallbackPhotoUrl: uploadedPhotoUrl
            )

            // 3. Тауарды сақтау (сатып алушыда бірден көрінеді)
            let input = CreateOfferInput(
                sellerUid: seller.uid,
                venueId: venue.id,
                venueName: venue.name,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                category: category,
                oldPrice: oldPrice,
                newPrice: newPrice,
                quantity: quantity,
                photoUrl: uploadedPhotoUrl,
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                reason: reason,
                producedAt: producedAt,
                expiresAt: normalizedExpiresAt,
                pickupUntil: pickupUntil
            )

            let createdOffer = try await offerRepository.createOffer(input)

            offers.insert(createdOffer, at: 0)
            selectedCategoryFilter = createdOffer.category
            state = .loaded
            activeCapturedImage = nil
            isCreateSheetPresented = false
            showSuccessMessage("Товар «\(createdOffer.title)» опубликован в разделе «\(createdOffer.category)»")
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return true
        } catch {
            submitErrorMessage = error.localizedDescription
            return false
        }
    }

    func updateExistingOffer(
        original: FoodOffer,
        newImage: UIImage?,
        title: String,
        category: String,
        oldPriceText: String,
        newPriceText: String,
        quantity: Int,
        isAvailable: Bool,
        producedAt: Date,
        expiresAt: Date,
        pickupUntil: Date,
        reason: String,
        description: String
    ) async -> Bool {
        guard original.sellerUid == seller.uid else {
            submitErrorMessage = "Нельзя редактировать чужой товар."
            return false
        }
        guard !isSubmitting else { return false }

        let oldPrice = Self.parsePrice(oldPriceText)
        let newPrice = Self.parsePrice(newPriceText)
        let normalizedExpiresAt = Self.endOfDay(for: expiresAt)

        isSubmitting = true
        submitErrorMessage = nil
        defer { isSubmitting = false }

        do {
            let finalPhotoUrl: String
            if let newImage {
                finalPhotoUrl = try await imageUploadService.uploadPhoto(newImage)
                RemoteImageMemoryCache.shared.store(newImage, for: finalPhotoUrl)
                ProductImageMemoryCache.shared.insert(newImage, for: finalPhotoUrl)
            } else {
                finalPhotoUrl = original.photoUrl
            }

            let updated = FoodOffer(
                id: original.id,
                sellerUid: original.sellerUid,
                venueId: original.venueId,
                venueName: original.venueName,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                category: category,
                oldPrice: oldPrice,
                newPrice: newPrice,
                quantity: max(0, quantity),
                photoUrl: finalPhotoUrl,
                isAvailable: quantity > 0 ? isAvailable : false,
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                reason: reason,
                producedAt: producedAt,
                expiresAt: normalizedExpiresAt,
                pickupUntil: pickupUntil,
                createdAt: original.createdAt
            )

            let saved = try await offerRepository.updateOffer(updated)
            if let index = offers.firstIndex(where: { $0.id == saved.id }) {
                offers[index] = saved
            }
            offerToEdit = nil
            showSuccessMessage("Изменения для «\(saved.title)» сохранены")
            return true
        } catch {
            submitErrorMessage = error.localizedDescription
            return false
        }
    }

    func updateQuantity(for offer: FoodOffer, delta: Int) async {
        let nextQty = max(0, offer.quantity + delta)
        do {
            let updated = try await offerRepository.updateOfferQuantity(offerId: offer.id, quantity: nextQty)
            if let index = offers.firstIndex(where: { $0.id == updated.id }) {
                offers[index] = updated
            }
        } catch {
            submitErrorMessage = "Не удалось обновить количество: \(error.localizedDescription)"
        }
    }

    func toggleAvailability(for offer: FoodOffer) async {
        do {
            let updated = try await offerRepository.updateOfferAvailability(
                offerId: offer.id,
                isAvailable: !offer.isAvailable
            )
            if let index = offers.firstIndex(where: { $0.id == updated.id }) {
                offers[index] = updated
            }
        } catch {
            submitErrorMessage = "Не удалось изменить статус: \(error.localizedDescription)"
        }
    }

    func deleteOffer(_ offer: FoodOffer) async {
        do {
            try await offerRepository.deleteOffer(offerId: offer.id)
            offers.removeAll { $0.id == offer.id }
            if offers.isEmpty {
                state = .empty
            }
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        } catch {
            submitErrorMessage = "Не удалось удалить товар: \(error.localizedDescription)"
        }
    }

    private func resolveOrCreateVenue(selectedVenueId: String?, fallbackPhotoUrl: String) async throws -> Venue {
        if let selectedVenueId, let found = venues.first(where: { $0.id == selectedVenueId }) {
            return found
        }
        if let existing = venues.first {
            return existing
        }

        let createdVenue = try await profileRepository.saveVenue(
            venueId: nil,
            ownerUid: seller.uid,
            name: seller.fullName,
            address: "Алматы, Казахстан",
            photoUrl: fallbackPhotoUrl
        )
        venues = [createdVenue]
        return createdVenue
    }

    private func showSuccessMessage(_ message: String) {
        successBannerMessage = message
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            if successBannerMessage == message {
                withAnimation {
                    successBannerMessage = nil
                }
            }
        }
    }

    private static func endOfDay(for date: Date) -> Date {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        return calendar.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? date
    }

    private static func parsePrice(_ raw: String) -> Double {
        let cleaned = raw
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return Double(cleaned) ?? 0
    }
}
