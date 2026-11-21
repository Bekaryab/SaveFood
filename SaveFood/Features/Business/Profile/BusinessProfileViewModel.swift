import SwiftUI
import UIKit
import Observation

@Observable
@MainActor
final class BusinessProfileViewModel {

    let seller: User

    private let profileRepository: ProfileRepository
    private let imageUploadService: ImageUploading

    var state: ViewState = .idle
    var currentVenue: Venue?

    var venueName: String = ""
    var venueAddress: String = ""
    var selectedImage: UIImage?
    var existingPhotoUrl: String = ""

    var isSaving = false
    var statusMessage: String?
    var errorMessage: String?

    init(
        seller: User,
        profileRepository: ProfileRepository,
        imageUploadService: ImageUploading
    ) {
        self.seller = seller
        self.profileRepository = profileRepository
        self.imageUploadService = imageUploadService
        self.venueName = seller.fullName
    }

    func loadVenue() async {
        state = .loading
        errorMessage = nil
        do {
            let venues = try await profileRepository.fetchVenues(forOwnerUid: seller.uid)
            if let venue = venues.first {
                currentVenue = venue
                venueName = venue.name
                venueAddress = venue.address
                existingPhotoUrl = venue.photoUrl
            }
            state = .loaded
        } catch {
            state = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    func saveVenueProfile() async {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil
        statusMessage = nil
        defer { isSaving = false }

        do {
            let photoUrl: String
            if let selectedImage {
                photoUrl = try await imageUploadService.uploadPhoto(selectedImage)
                RemoteImageMemoryCache.shared.store(selectedImage, for: photoUrl)
            } else {
                photoUrl = existingPhotoUrl
            }

            let saved = try await profileRepository.saveVenue(
                venueId: currentVenue?.id,
                ownerUid: seller.uid,
                name: venueName,
                address: venueAddress,
                photoUrl: photoUrl
            )
            currentVenue = saved
            existingPhotoUrl = saved.photoUrl
            selectedImage = nil
            statusMessage = "Профиль заведения сохранён."
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
