import SwiftUI
struct RegisterTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    @Binding var isPasswordVisible: Bool
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .never
    private let fieldBackground = Color(red: 0.922, green: 0.937, blue: 0.902)
    private let iconGreen = Color(red: 0.14, green: 0.38, blue: 0.21)
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(iconGreen)
                .frame(width: 24)
            Group {
                if isSecure && !isPasswordVisible {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                }
            }
            .font(.system(size: 16, weight: .regular, design: .rounded))
            .textInputAutocapitalization(autocapitalization)
            .autocorrectionDisabled()
            if isSecure {
                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(red: 0.45, green: 0.52, blue: 0.45))
                }
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(fieldBackground)
        )
    }
}
