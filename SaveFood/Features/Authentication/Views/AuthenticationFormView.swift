import SwiftUI
struct AuthenticationFormView: View {
    @Bindable var viewModel: AuthenticationFlowViewModel
    var onBack: (() -> Void)? = nil
    var onSubmit: ((AuthAccountRole, AuthFormMode) -> Void)? = nil
    @FocusState private var isAnyFieldFocused: Bool
    @State private var sheetDragY: CGFloat = 0
    private let primaryGreen = Color(red: 0.10, green: 0.31, blue: 0.17)
    private let sheetBackground = Color(red: 0.976, green: 0.980, blue: 0.957)
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Sheet Drag Handle
            VStack(spacing: 8) {
                Capsule()
                    .fill(Color(red: 0.78, green: 0.82, blue: 0.76))
                    .frame(width: 44, height: 5)
                    .padding(.top, 12)
                VStack(spacing: 6) {
                    Text(viewModel.titleText)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(primaryGreen)
                        .multilineTextAlignment(.center)
                    Text(viewModel.subtitleText)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(red: 0.38, green: 0.44, blue: 0.38))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                isAnyFieldFocused = false
                viewModel.dismissKeyboard()
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        sheetDragY = value.translation.height
                    }
                    .onEnded { value in
                        isAnyFieldFocused = false
                        viewModel.dismissKeyboard()
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
                            if value.translation.height < -50 {
                                viewModel.isAuthSheetExpanded = true
                            } else if value.translation.height > 60 {
                                if viewModel.isAuthSheetExpanded {
                                    viewModel.isAuthSheetExpanded = false
                                } else if value.translation.height > 120 {
                                    onBack?()
                                }
                            }
                            sheetDragY = 0
                        }
                    }
            )
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    RoleSelectorView(selectedRole: $viewModel.selectedRole)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)
                    VStack(spacing: 12) {
                        if viewModel.formMode == .register {
                            RegisterTextField(
                                icon: viewModel.selectedRole == .customer ? "person" : "building.2",
                                placeholder: viewModel.selectedRole == .customer ? "Полное имя" : "Название заведения",
                                text: $viewModel.fullName,
                                isSecure: false,
                                isPasswordVisible: .constant(false),
                                autocapitalization: .words
                            )
                            .focused($isAnyFieldFocused)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        RegisterTextField(
                            icon: "envelope",
                            placeholder: "Электронная почта",
                            text: $viewModel.email,
                            isSecure: false,
                            isPasswordVisible: .constant(false),
                            keyboardType: .emailAddress
                        )
                        .focused($isAnyFieldFocused)
                        RegisterTextField(
                            icon: "lock",
                            placeholder: "Пароль",
                            text: $viewModel.password,
                            isSecure: true,
                            isPasswordVisible: $viewModel.isPasswordVisible
                        )
                        .focused($isAnyFieldFocused)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)
                    //error ғой
                    if let errorMessage = viewModel.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 15))
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .multilineTextAlignment(.leading)
                        }
                        .foregroundStyle(Color(red: 0.78, green: 0.18, blue: 0.18))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(red: 0.98, green: 0.88, blue: 0.88))
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)
                    }

                    // MARK: - Submit Button (Firebase ке жіберу)
                    Button {
                        isAnyFieldFocused = false
                        Task {
                            await viewModel.submitAuth()
                            if viewModel.isAuthenticated {
                                onSubmit?(viewModel.selectedRole, viewModel.formMode)
                            }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(viewModel.formMode == .register ? "Зарегистрироваться" : "Войти")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.14, green: 0.38, blue: 0.21),
                                            Color(red: 0.09, green: 0.28, blue: 0.15)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .shadow(
                            color: primaryGreen.opacity(0.22),
                            radius: 10,
                            x: 0,
                            y: 5
                        )
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    HStack(spacing: 6) {
                        Text(viewModel.formMode == .register ? "Уже есть аккаунт?" : "Еще нет аккаунта?")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(Color(red: 0.38, green: 0.44, blue: 0.38))
                        Button {
                            isAnyFieldFocused = false
                            viewModel.toggleFormMode()
                        } label: {
                            Text(viewModel.formMode == .register ? "Войти" : "Зарегистрироваться")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(primaryGreen)
                        }
                    }
                    .padding(.bottom, 28)
                }
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 34,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 34,
                style: .continuous
            )
            .fill(sheetBackground)
            .shadow(color: Color.black.opacity(0.08), radius: 22, x: 0, y: -6)
            .ignoresSafeArea(edges: .bottom)
        )
        .offset(y: max(-30, min(80, sheetDragY * 0.45)))
    }
}
