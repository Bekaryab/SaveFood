import SwiftUI
struct WelcomeContentView: View {
    @Binding var dragOffset: CGFloat
    var onCreateAccount: () -> Void
    var onLogin: () -> Void
    private let primaryGreen = Color(red: 0.11, green: 0.31, blue: 0.17)
    private let sheetBackground = Color(red: 0.976, green: 0.980, blue: 0.957)
    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(red: 0.78, green: 0.82, blue: 0.76))
                .frame(width: 44, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 18)
            VStack(spacing: 10) {
                Text("Сохраняем еду\nвместе")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(primaryGreen)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Покупайте качественные продукты\nсо скидкой и уменьшайте пищевые отходы")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(red: 0.36, green: 0.43, blue: 0.37))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 22)
            VStack(spacing: 12) {
                Button(action: onCreateAccount) {
                    HStack(spacing: 10) {
                        Text("Создать аккаунт")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 17, weight: .semibold))
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
                                        Color(red: 0.10, green: 0.29, blue: 0.16)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .shadow(
                        color: Color(red: 0.10, green: 0.29, blue: 0.16).opacity(0.24),
                        radius: 10,
                        x: 0,
                        y: 5
                    )
                }
                Button(action: onLogin) {
                    Text("Войти")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(primaryGreen)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.88))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color(red: 0.78, green: 0.82, blue: 0.76), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 26)
        }
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 34,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 34,
                style: .continuous
            )
            .fill(sheetBackground)
            .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: -6)
            .ignoresSafeArea(edges: .bottom)
        )
        .offset(y: min(40, dragOffset * 0.5))
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.height
                }
                .onEnded { value in
                    if value.translation.height < -75 {
                        dragOffset = 0
                        onCreateAccount()
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
                }
        )
    }
}
