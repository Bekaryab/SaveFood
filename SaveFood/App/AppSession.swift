import Foundation
import FirebaseAuth
import Observation

@Observable
@MainActor
final class AppSession {

    enum AuthState: Equatable {
        case checking
        case unauthenticated
        case authenticated(User)
    }

    var authState: AuthState = .checking
    var errorMessage: String?

    @ObservationIgnored private let authRepository: AuthRepository
    @ObservationIgnored private let profileRepository: ProfileRepository
    @ObservationIgnored nonisolated(unsafe) private var authStateListener: AuthStateDidChangeListenerHandle?

    var currentUser: User? {
        if case .authenticated(let user) = authState {
            return user
        }
        return nil
    }

    init(authRepository: AuthRepository, profileRepository: ProfileRepository) {
        self.authRepository = authRepository
        self.profileRepository = profileRepository
        startObservingFirebaseAuth()
    }

    deinit {
        if let handle = authStateListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func restoreSession() async {
        guard let uid = authRepository.currentUserUID else {
            authState = .unauthenticated
            return
        }
        await loadUserProfileWithRetry(uid: uid)
    }

    func signOut() {
        do {
            try authRepository.logout()
            authState = .unauthenticated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startObservingFirebaseAuth() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self else { return }
            Task { @MainActor in
                guard let uid = firebaseUser?.uid else {
                    self.authState = .unauthenticated
                    return
                }
                await self.loadUserProfileWithRetry(uid: uid)
            }
        }
    }

    /// Повтор чтения профиля нужен при регистрации,
    /// пока документ users/{uid} с ролью "seller"/"customer" записывается в Firestore.
    private func loadUserProfileWithRetry(uid: String) async {
        for attempt in 0..<4 {
            do {
                let user = try await profileRepository.fetchUserProfile(uid: uid)
                authState = .authenticated(user)
                return
            } catch {
                if attempt < 3 {
                    try? await Task.sleep(for: .milliseconds(350))
                }
            }
        }

        do {
            if let fallbackUser = try await authRepository.checkAuthenticationState() {
                authState = .authenticated(fallbackUser)
            } else {
                authState = .unauthenticated
            }
        } catch {
            errorMessage = error.localizedDescription
            authState = .unauthenticated
        }
    }
}
