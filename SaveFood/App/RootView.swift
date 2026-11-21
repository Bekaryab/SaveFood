import SwiftUI

struct RootView: View {

    let dependencies: AppDependencies
    @Bindable var session: AppSession

    private let primaryGreen = Color(red: 0.08, green: 0.30, blue: 0.15)
    private let creamBackground = Color(red: 0.965, green: 0.969, blue: 0.937)

    var body: some View {
        Group {
            switch session.authState {
            case .checking:
                ZStack {
                    creamBackground.ignoresSafeArea()
                    VStack(spacing: 14) {
                        ProgressView()
                            .tint(primaryGreen)
                        Text("SaveFood")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundStyle(primaryGreen)
                    }
                }

            case .unauthenticated:
                AuthenticationFlowView()

            case .authenticated(let user):
                switch user.role {
                case .seller:
                    BusinessDashboardView(
                        seller: user,
                        dependencies: dependencies,
                        onSignOut: {
                            session.signOut()
                        }
                    )

                case .customer:
                    ExploreView(
                        userName: user.fullName,
                        offerRepository: dependencies.offerRepository,
                        onSignOut: {
                            session.signOut()
                        }
                    )
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: session.authState)
    }
}
