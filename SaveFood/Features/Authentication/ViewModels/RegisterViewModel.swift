import Foundation
import Combine

@MainActor
final class RegisterViewModel: ObservableObject {

    // MARK: - Form State

    @Published var selectedRole: AuthAccountRole = .customer
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isPasswordVisible: Bool = false

    // MARK: - UI State

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isRegistrationSuccessful: Bool = false

    // MARK: - Validation

    var isFormValid: Bool {
        !fullName.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        && isValidEmail(email)
        && password.count >= 8
    }

    // MARK: - Role Selection

    func selectRole(_ role: AuthAccountRole) {
        selectedRole = role
        errorMessage = nil
    }

    // MARK: - Password Visibility

    func togglePasswordVisibility() {
        isPasswordVisible.toggle()
    }

    // MARK: - Email Validation

    private func isValidEmail(_ email: String) -> Bool {
        let pattern =
        #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(
            of: pattern,
            options: .regularExpression
        ) != nil
    }

    // MARK: - Form Validation

    private func validateForm() -> Bool {
        errorMessage = nil
        guard !fullName.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {
            errorMessage = "Введите ваше имя"
            return false
        }
        guard isValidEmail(email) else {
            errorMessage = "Введите корректный Email"
            return false
        }
        guard password.count >= 8 else {
            errorMessage = "Пароль должен содержать минимум 8 символов"
            return false
        }
        return true
    }

    // MARK: - Registration
    func register() async -> Bool {
        guard validateForm() else {
            return false
        }
        guard !isLoading else {
            return false
        }
        isLoading = true

        defer {
            isLoading = false
        }
        do {
            try await Task.sleep(
                nanoseconds: 700_000_000
            )
            isRegistrationSuccessful = true
            return true
        } catch {
            errorMessage = "Произошла ошибка регистрации"
            return false
        }
    }

    // MARK: - Reset Form
    func resetForm() {
        fullName = ""
        email = ""
        password = ""
        selectedRole = .customer
        isPasswordVisible = false
        errorMessage = nil
        isRegistrationSuccessful = false
    }
}
