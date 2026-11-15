import SwiftUI
import UIKit
import Observation
import FirebaseAuth
import FirebaseFirestore
@Observable
@MainActor
final class AuthenticationFlowViewModel {
    var isShowingAuthPage: Bool = false
    var isAuthCarouselVisible: Bool = false
    var isAuthSheetExpanded: Bool = false
    var formMode: AuthFormMode = .register
    var selectedRole: AuthAccountRole = .customer
    var fullName: String = ""
    var email: String = ""
    var password: String = ""
    var isPasswordVisible: Bool = false
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var isAuthenticated: Bool = false
    var currentUserName: String = ""
    private let db = Firestore.firestore()
    init() {
        checkExistingSession()
    }
    func checkExistingSession() {
        if let user = Auth.auth().currentUser {
            currentUserName = user.displayName ?? "Пользователь"
            isAuthenticated = true
            Task {
                await fetchUserRole(uid: user.uid)
            }
        }
    }
    func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
    func openAuthPage(mode: AuthFormMode) {
        dismissKeyboard()
        errorMessage = nil
        formMode = mode
        isAuthSheetExpanded = false
        isAuthCarouselVisible = true
        withAnimation(.spring(response: 0.54, dampingFraction: 0.88)) {
            isShowingAuthPage = true
        }
    }
    func closeAuthPage() {
        dismissKeyboard()
        errorMessage = nil
        isAuthSheetExpanded = false
        withAnimation(.spring(response: 0.52, dampingFraction: 0.88)) {
            isShowingAuthPage = false
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            if !isShowingAuthPage {
                isAuthCarouselVisible = false
            }
        }
    }
    func toggleFormMode() {
        dismissKeyboard()
        errorMessage = nil
        withAnimation(.spring(response: 0.36, dampingFraction: 0.84)) {
            formMode = (formMode == .register) ? .login : .register
        }
    }
    func submitAuth() async {
        dismissKeyboard()
        errorMessage = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        if formMode == .register && trimmedName.isEmpty {
            errorMessage = selectedRole == .customer
                ? "Пожалуйста, введите ваше полное имя"
                : "Пожалуйста, введите название заведения"
            return
        }
        guard !trimmedEmail.isEmpty, trimmedEmail.contains("@") else {
            errorMessage = "Введите корректный адрес электронной почты"
            return
        }
        guard trimmedPassword.count >= 6 else {
            errorMessage = "Пароль должен содержать минимум 6 символов"
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            if formMode == .register {
                let result = try await Auth.auth().createUser(
                    withEmail: trimmedEmail,
                    password: trimmedPassword
                )
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = trimmedName
                try? await changeRequest.commitChanges()
                let userData: [String: Any] = [
                    "uid": result.user.uid,
                    "fullName": trimmedName,
                    "email": trimmedEmail,
                    "role": selectedRole == .customer ? "customer" : "seller",
                    "createdAt": FieldValue.serverTimestamp()
                ]
                try? await db.collection("users").document(result.user.uid).setData(userData)
                currentUserName = trimmedName
            } else {
                let result = try await Auth.auth().signIn(
                    withEmail: trimmedEmail,
                    password: trimmedPassword
                )
                currentUserName = result.user.displayName ?? "Пользователь"
                await fetchUserRole(uid: result.user.uid)
            }
            withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) {
                isAuthenticated = true
            }
        } catch {
            errorMessage = mapFirebaseError(error)
        }
    }
    private func fetchUserRole(uid: String) async {
        guard let snapshot = try? await db.collection("users").document(uid).getDocument(),
              let data = snapshot.data() else { return }
        if let roleString = data["role"] as? String {
            selectedRole = (roleString == "seller") ? .seller : .customer
        }
        if let savedName = data["fullName"] as? String, !savedName.isEmpty {
            currentUserName = savedName
        }
    }
    func signOut() {
        try? Auth.auth().signOut()
        fullName = ""
        password = ""
        errorMessage = nil
        isShowingAuthPage = false
        isAuthCarouselVisible = false
        withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) {
            isAuthenticated = false
        }
    }
    private func mapFirebaseError(_ error: Error) -> String {
        let nsError = error as NSError
        guard let code = AuthErrorCode(rawValue: nsError.code) else {
            return error.localizedDescription
        }
        switch code {
        case .emailAlreadyInUse:
            return "Этот email уже зарегистрирован. Попробуйте войти"
        case .invalidEmail:
            return "Неверный формат электронной почты"
        case .wrongPassword, .invalidCredential:
            return "Неверный email или пароль"
        case .userNotFound:
            return "Аккаунт с таким email не найден"
        case .weakPassword:
            return "Слишком простой пароль (минимум 6 символов)"
        case .networkError:
            return "Ошибка сети. Проверьте подключение к интернету"
        default:
            return "Не удалось выполнить вход. Проверьте данные"
        }
    }
    var titleText: String {
        formMode == .register ? "Создать аккаунт" : "Войти в аккаунт"
    }
    var subtitleText: String {
        switch (formMode, selectedRole) {
        case (.register, .customer):
            return "Зарегистрируйтесь, чтобы получать\nвыгодные предложения"
        case (.register, .seller):
            return "Зарегистрируйте заведение и продавайте\nпродукты без списаний"
        case (.login, .customer):
            return "Войдите, чтобы находить свежие блюда\nсо скидкой рядом с вами"
        case (.login, .seller):
            return "Войдите в кабинет продавца для управления\nпредложениями и заказами"
        }
    }
}
