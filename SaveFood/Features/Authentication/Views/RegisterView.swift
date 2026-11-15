import SwiftUI
struct RegisterView: View {
    @Bindable var viewModel: AuthenticationFlowViewModel
    var onBack: () -> Void
    var onSubmit: ((AuthAccountRole, AuthFormMode) -> Void)? = nil
    private let primaryGreen = Color(red: 0.10, green: 0.31, blue: 0.17)
    private let creamBackground = Color(red: 0.945, green: 0.962, blue: 0.922)
    private let buttonCircleBg = Color(red: 0.895, green: 0.922, blue: 0.875)
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                creamBackground
                    .ignoresSafeArea()
                VStack(spacing: 0) {
                    ZStack {
                        HStack {
                            Button(action: onBack) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(primaryGreen)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(buttonCircleBg)
                                    )
                                    .contentShape(Circle())
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }
                        Text("SaveFood")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(primaryGreen)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .zIndex(10)
                    if #available(iOS 18.0, *), viewModel.isAuthCarouselVisible {
                        Auth3DCarouselView()
                            .frame(
                                width: geo.size.width,
                                height: viewModel.isAuthSheetExpanded ? geo.size.height * 0.18 : geo.size.height * 0.28
                            )
                            .clipped()
                            .transition(.opacity)
                    } else {
                        Spacer()
                            .frame(height: geo.size.height * 0.28)
                    }
                    Spacer(minLength: 0)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                AuthenticationFormView(
                    viewModel: viewModel,
                    onBack: onBack,
                    onSubmit: onSubmit
                )
                .frame(
                    width: geo.size.width,
                    height: viewModel.isAuthSheetExpanded ? geo.size.height * 0.76 : geo.size.height * 0.63
                )
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
