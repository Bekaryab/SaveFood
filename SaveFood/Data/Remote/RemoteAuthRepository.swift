
import Foundation
import FirebaseAuth
import FirebaseFirestore

enum AuthServiceError: LocalizedError {
    case unauthenticated
    case profileNotFound
    case profileSaveFailed(String)
    case firebase(String)

    var errorDescription: String? {
        switch self {
        case .unauthenticated:
            return "Сессия не найдена. Пожалуйста, войдите в аккаунт."
        case .profileNotFound:
            return "Профиль пользователя не найден в базе данных."
        case .profileSaveFailed(let detail):
            return "Не удалось сохранить профиль пользователя: \(detail)"
        case .firebase(let message):
            return message
        }
    }
}

final class RemoteAuthRepository: AuthRepository, @unchecked Sendable {

    private let auth: Auth
    private let db: Firestore

    init(
        auth: Auth = Auth.auth(),
        db: Firestore = Firestore.firestore()
    ) {
        self.auth = auth
        self.db = db
    }

    var currentUserUID: String? {
        auth.currentUser?.uid
    }

    func register(
        fullName: String,
        email: String,
        password: String,
        role: UserRole
    ) async throws -> User {
        let validName = try Validators.validateFullName(fullName, role: role)
        let validEmail = try Validators.validateEmail(email)
        let validPassword = try Validators.validatePassword(password)

        let authResult: AuthDataResult
        do {
            authResult = try await auth.createUser(withEmail: validEmail, password: validPassword)
        } catch {
            throw AuthServiceError.firebase(Self.mapAuthError(error))
        }

        let firebaseUser = authResult.user
        let changeRequest = firebaseUser.createProfileChangeRequest()
        changeRequest.displayName = validName
        do {
            try await changeRequest.commitChanges()
        } catch {
            // Ошибка обновления displayName в Auth не критична, профиль в Firestore сохранится
        }

        let dto = AuthDTO(
            uid: firebaseUser.uid,
            fullName: validName,
            email: validEmail,
            role: role
        )

        do {
            try await db.collection("users")
                .document(firebaseUser.uid)
                .setData(dto.toFirestoreData())
        } catch {
            // Откатываем пользователя в Auth, чтобы не оставлять аккаунт без профиля в Firestore
            try? await firebaseUser.delete()
            throw AuthServiceError.profileSaveFailed(error.localizedDescription)
        }

        return dto.toDomain()
    }

    func login(email: String, password: String) async throws -> User {
        let validEmail = try Validators.validateEmail(email)
        let validPassword = try Validators.validatePassword(password)

        let authResult: AuthDataResult
        do {
            authResult = try await auth.signIn(withEmail: validEmail, password: validPassword)
        } catch {
            throw AuthServiceError.firebase(Self.mapAuthError(error))
        }

        return try await fetchOrHydrateUserProfile(for: authResult.user)
    }

    func logout() throws {
        do {
            try auth.signOut()
        } catch {
            throw AuthServiceError.firebase("Не удалось выйти из аккаунта: \(error.localizedDescription)")
        }
    }

    func resetPassword(email: String) async throws {
        let validEmail = try Validators.validateEmail(email)
        do {
            try await auth.sendPasswordReset(withEmail: validEmail)
        } catch {
            throw AuthServiceError.firebase(Self.mapAuthError(error))
        }
    }

    func sendEmailVerification() async throws {
        guard let user = auth.currentUser else {
            throw AuthServiceError.unauthenticated
        }
        do {
            try await user.sendEmailVerification()
        } catch {
            throw AuthServiceError.firebase(Self.mapAuthError(error))
        }
    }

    func checkAuthenticationState() async throws -> User? {
        guard let firebaseUser = auth.currentUser else {
            return nil
        }
        return try await fetchOrHydrateUserProfile(for: firebaseUser)
    }

    private func fetchOrHydrateUserProfile(for firebaseUser: FirebaseAuth.User) async throws -> User {
        let docRef = db.collection("users").document(firebaseUser.uid)
        let snapshot = try await docRef.getDocument()

        if snapshot.exists, let dto = AuthDTO(document: snapshot) {
            return dto.toDomain()
        }

        // Если аккаунт был создан ранее без документа в users/{uid}, создаём базовый профиль customer
        let fallbackDTO = AuthDTO(
            uid: firebaseUser.uid,
            fullName: firebaseUser.displayName ?? "Пользователь",
            email: firebaseUser.email ?? "",
            role: .customer
        )
        try await docRef.setData(fallbackDTO.toFirestoreData())
        return fallbackDTO.toDomain()
    }

    private static func mapAuthError(_ error: Error) -> String {
        let nsError = error as NSError
        guard let code = AuthErrorCode(rawValue: nsError.code) else {
            return error.localizedDescription
        }
        switch code {
        case .emailAlreadyInUse:
            return "Этот email уже зарегистрирован. Попробуйте войти."
        case .invalidEmail:
            return "Неверный формат электронной почты."
        case .wrongPassword, .invalidCredential:
            return "Неверный email или пароль."
        case .userNotFound:
            return "Аккаунт с таким email не найден."
        case .weakPassword:
            return "Слишком слабый пароль (минимум 6 символов)."
        case .tooManyRequests:
            return "Слишком много попыток. Повторите чуть позже."
        case .networkError:
            return "Ошибка сети. Проверьте подключение к интернету."
        default:
            return "Ошибка авторизации: \(error.localizedDescription)"
        }
    }
}
