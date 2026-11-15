import SwiftUI

struct RoleSelectorView: View {

    @Binding var selectedRole: AuthAccountRole

    private let primaryGreen = Color(red: 0.10, green: 0.31, blue: 0.17)
    private let fieldBackground = Color(red: 0.922, green: 0.937, blue: 0.902)

    var body: some View {
        HStack(spacing: 8) {
            ForEach(AuthAccountRole.allCases) { role in
                let isSelected = (selectedRole == role)
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                        selectedRole = role
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: role.iconName)
                            .font(.system(size: 15, weight: .semibold))

                        Text(role.rawValue)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(isSelected ? .white : primaryGreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isSelected ? primaryGreen : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(fieldBackground)
        )
    }
}
