import SwiftUI

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.title2)
                }
                Text(title)
                    .font(AppFont.headline())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.primary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton("Debrief a Match", icon: "plus.circle.fill") { }
        PrimaryButton("Save") { }
    }
    .padding()
}
