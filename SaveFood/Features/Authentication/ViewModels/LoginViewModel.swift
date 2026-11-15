

import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {

    // MARK: - Form State
    @Published var selectedRole: AuthAccountRole = .customer

    @Published var email: String = ""

    @Published var password: String = ""

    @Published var isPasswordVisible: Bool = false

    // MARK: - UI State

    @Published var isLoading: Bool = false

    @Published var errorMessage: String?

    // MARK: - Validation

    var isFormValid: Bool {
        isValidEmail(email) &&
        !password.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
    }

    private func isValidEmail(_ email: String) -> Bool {

        let pattern =
        #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#

        return email.range(
            of: pattern,
            options: .regularExpression
        ) != nil
    }

    // MARK: - Password Visibility

    func togglePasswordVisibility() {
        isPasswordVisible.toggle()
    }

    // MARK: - Login

    func login() async -> Bool {

        errorMessage = nil

        guard isValidEmail(email) else {
            errorMessage = "Введите корректный Email"
            return false
        }

        guard !password.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {
            errorMessage = "Введите пароль"
            return false
        }

        guard !isLoading else {
            return false
        }

        isLoading = true

        defer {
            isLoading = false
        }

        // Temporary mock authentication.
        // Real authentication API will be connected later.

        do {
            try await Task.sleep(
                nanoseconds: 700_000_000
            )

            return true

        } catch {
            errorMessage = "Не удалось выполнить вход"
            return false
        }
    }

    // MARK: - Reset

    func resetForm() {
        email = ""
        password = ""
        isPasswordVisible = false
        errorMessage = nil
    }
}
