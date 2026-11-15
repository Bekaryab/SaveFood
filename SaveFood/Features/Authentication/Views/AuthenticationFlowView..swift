import SwiftUI
struct AuthenticationFlowView: View {
    @State private var viewModel = AuthenticationFlowViewModel()
    @State private var welcomeDragOffset: CGFloat = 0
    private let creamBackground = Color(red: 0.945, green: 0.962, blue: 0.922)
    private let softSageWave = Color(red: 0.895, green: 0.935, blue: 0.875)
    var body: some View {
        if viewModel.isAuthenticated {
            ExploreView(
                userName: viewModel.currentUserName,
                userRole: viewModel.selectedRole,
                onSignOut: {
                    viewModel.signOut()
                }
            )
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        } else {
            GeometryReader { geo in
                let offscreenDistance = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom + 140
                ZStack {
                    creamBackground
                        .ignoresSafeArea()
                    VStack(spacing: 0) {
                        VStack(spacing: 6) {
                            Text("SAVE FOOD SAVE MONEY")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .italic()
                                .tracking(2.8)
                                .foregroundStyle(Color(red: 0.14, green: 0.40, blue: 0.22))
                            Text("SaveFood")
                                .font(.system(size: 48, weight: .heavy, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.08, green: 0.27, blue: 0.15),
                                            Color(red: 0.15, green: 0.39, blue: 0.22)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        .padding(.top, 14)
                        if #available(iOS 18.0, *) {
                            FoodFloatingAnimationView(isPaused: viewModel.isShowingAuthPage)
                                .frame(width: geo.size.width, height: geo.size.height * 0.40)
                                .clipped()
                        }
                        Spacer(minLength: 0)
                        WelcomeContentView(
                            dragOffset: $welcomeDragOffset,
                            onCreateAccount: {
                                viewModel.openAuthPage(mode: .register)
                            },
                            onLogin: {
                                viewModel.openAuthPage(mode: .login)
                            }
                        )
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .background {
                        ZStack {
                            Circle()
                                .fill(softSageWave)
                                .frame(width: geo.size.width * 0.85, height: geo.size.width * 0.85)
                                .offset(x: -geo.size.width * 0.35, y: -geo.size.height * 0.22)
                            Ellipse()
                                .fill(softSageWave.opacity(0.85))
                                .frame(width: geo.size.width * 1.25, height: geo.size.height * 0.40)
                                .rotationEffect(.degrees(-8))
                                .offset(x: 0, y: -geo.size.height * 0.04)
                        }
                        .ignoresSafeArea()
                    }
                    .scaleEffect(viewModel.isShowingAuthPage ? 0.94 : 1.0)
                    .opacity(viewModel.isShowingAuthPage ? 0.0 : 1.0)
                    .offset(y: viewModel.isShowingAuthPage ? -offscreenDistance : min(0, welcomeDragOffset * 0.35))
                    .allowsHitTesting(!viewModel.isShowingAuthPage)
                    RegisterView(
                        viewModel: viewModel,
                        onBack: {
                            viewModel.closeAuthPage()
                        }
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                    .opacity(viewModel.isShowingAuthPage ? 1.0 : 0.0)
                    .offset(y: viewModel.isShowingAuthPage ? 0 : offscreenDistance)
                    .allowsHitTesting(viewModel.isShowingAuthPage)
                }
            }
            .task {
                await ThreeDModelCache.shared.warmUpCartImmediately()
            }
        }
    }
}
#Preview {
    AuthenticationFlowView()
}
