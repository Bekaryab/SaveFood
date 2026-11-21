
import Foundation

protocol AuthRepository: Sendable {
    var currentUserUID: String? { get }

    func register(
        fullName: String,
        email: String,
        password: String,
        role: UserRole
    ) async throws -> User

    func login(
        email: String,
        password: String
    ) async throws -> User

    func logout() throws

    func resetPassword(email: String) async throws

    func sendEmailVerification() async throws

    func checkAuthenticationState() async throws -> User?
}
