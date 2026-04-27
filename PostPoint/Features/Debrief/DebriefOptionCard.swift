import SwiftUI

struct DebriefOptionCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 28)

                Text(title)
                    .font(AppFont.body())

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppColors.primary)
                }
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? AppColors.primary.opacity(0.1) : AppColors.secondaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview {
    VStack(spacing: 12) {
        DebriefOptionCard(title: "Won comfortably", icon: "hand.thumbsup.fill", isSelected: true) { }
        DebriefOptionCard(title: "Lost close", icon: "hand.thumbsdown", isSelected: false) { }
    }
    .padding()
}
