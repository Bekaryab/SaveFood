
import Foundation

final class AppDependencies: @unchecked Sendable {
    let authRepository: AuthRepository
    let profileRepository: ProfileRepository
    let offerRepository: OfferRepository
    let reservationRepository: ReservationRepository
    let imageUploadService: ImageUploading

    init(
        authRepository: AuthRepository = RemoteAuthRepository(),
        profileRepository: ProfileRepository = RemoteProfileRepository(),
        offerRepository: OfferRepository = RemoteOfferRepository(),
        reservationRepository: ReservationRepository = RemoteReservationRepository(),
        imageUploadService: ImageUploading = ImgBBImageUploadService()
    ) {
        self.authRepository = authRepository
        self.profileRepository = profileRepository
        self.offerRepository = offerRepository
        self.reservationRepository = reservationRepository
        self.imageUploadService = imageUploadService
    }
}
