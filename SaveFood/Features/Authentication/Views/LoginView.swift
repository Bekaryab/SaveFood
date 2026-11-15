import SwiftUI
struct LoginView: View {
    @Bindable var viewModel: AuthenticationFlowViewModel
    var onBack: () -> Void
    var onSubmit: ((AuthAccountRole, AuthFormMode) -> Void)? = nil
    var body: some View {
        RegisterView(
            viewModel: viewModel,
            onBack: onBack,
            onSubmit: onSubmit
        )
        .onAppear {
            viewModel.formMode = .login
        }
    }
}
